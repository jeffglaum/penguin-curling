//
//  Penguin.m
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Penguin.h"
#import "PenguinCurlingAppDelegate.h"

#define GLOBAL_SCALE_FACTOR         2

#define PENGUIN_HEIGHT_PIXELS       256.0f
#define PENGUIN_WIDTH_PIXELS        256.0f
#define PENGUIN_HEIGHT_RATIO        (PENGUIN_HEIGHT_PIXELS / SCREEN_HEIGHT_PIXELS / GLOBAL_SCALE_FACTOR)
#define PENGUIN_WIDTH_RATIO         (PENGUIN_WIDTH_PIXELS  / SCREEN_WIDTH_PIXELS / GLOBAL_SCALE_FACTOR)

#define EYESTRIP_NUM_CELLS          4
#define EYESTRIP_HEIGHT_PIXELS      512.0f
#define EYESTRIP_WIDTH_PIXELS       128.0f
#define EYESTRIP_HEIGHT_RATIO       (EYESTRIP_HEIGHT_PIXELS / EYESTRIP_NUM_CELLS / SCREEN_HEIGHT_PIXELS / GLOBAL_SCALE_FACTOR)
#define EYESTRIP_WIDTH_RATIO        (EYESTRIP_WIDTH_PIXELS  / SCREEN_WIDTH_PIXELS / GLOBAL_SCALE_FACTOR)
#define EYES_BODY_OFFSET_X          -0.029f
#define EYES_BODY_OFFSET_Y          0.085f
#define EYES_RANDOM_BLINK_INVERVAL	(((GLfloat)rand() / (GLfloat)RAND_MAX) * 10.0f)
#define EYES_BLINK_STEP_TIME        0.07f

#define WING_HEIGHT_PIXELS          128.0f
#define WING_WIDTH_PIXELS           128.0f
#define WING_HEIGHT_RATIO           (WING_HEIGHT_PIXELS / SCREEN_HEIGHT_PIXELS / GLOBAL_SCALE_FACTOR)
#define WING_WIDTH_RATIO            (WING_WIDTH_PIXELS  / SCREEN_WIDTH_PIXELS / GLOBAL_SCALE_FACTOR)
#define WING_BODY_OFFSET_X          0.07f
#define WING_BODY_OFFSET_Y          -0.01f
#define WING_RANDOM_WIGGLE_INVERVAL	(((GLfloat)rand() / (GLfloat)RAND_MAX) * 20.0f)
#define WING_WIGGLE_STEP_TIME       0.002f

static const GLfloat bodyVertices[] = 
{
	-PENGUIN_WIDTH_RATIO,  -PENGUIN_HEIGHT_RATIO,
	 PENGUIN_WIDTH_RATIO,  -PENGUIN_HEIGHT_RATIO,
	-PENGUIN_WIDTH_RATIO,   PENGUIN_HEIGHT_RATIO,
	 PENGUIN_WIDTH_RATIO,   PENGUIN_HEIGHT_RATIO,
};

static const GLfloat wingVertices[] = 
{
	-WING_WIDTH_RATIO,  -WING_HEIGHT_RATIO,
	 WING_WIDTH_RATIO,  -WING_HEIGHT_RATIO,
	-WING_WIDTH_RATIO,   WING_HEIGHT_RATIO,
	 WING_WIDTH_RATIO,   WING_HEIGHT_RATIO,
};

static const GLfloat eyeVertices[] = 
{
	-EYESTRIP_WIDTH_RATIO,  -EYESTRIP_HEIGHT_RATIO,
	 EYESTRIP_WIDTH_RATIO,  -EYESTRIP_HEIGHT_RATIO,
	-EYESTRIP_WIDTH_RATIO,   EYESTRIP_HEIGHT_RATIO,
	 EYESTRIP_WIDTH_RATIO,   EYESTRIP_HEIGHT_RATIO,
};

static const GLfloat genTextureVertices[] = 
{
	0.0f,  1.0f,
	1.0f,  1.0f,
	0.0f,  0.0f,
	1.0f,  0.0f,
};



@implementation Penguin
@synthesize chipmunkObjects;

- (id)init
{
	self = [super init];
	if (self)
	{
		// Load the penguin textures from PNGs
		glGenTextures(3, &texture[0]);
		// Penguin body
		glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_BODY]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		[self loadPNG: @"Body"];
		// Penguin eyes (animation strip)
		glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_EYES]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		[self loadPNG: @"EyesAnimAlpha"];
		// Penguin wing
		glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_WING]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		[self loadPNG: @"Wing"];
		
		penguinAlpha = 0;
		
		// Define the penguin's physical characteristics to the physics engine
		cpFloat penguinMass   = PENGUIN_MASS;
		cpFloat penguinMoment = cpMomentForBox(penguinMass, PENGUIN_SIZE, PENGUIN_SIZE);
		penguinBody = [[ChipmunkBody alloc] initWithMass:penguinMass andMoment:penguinMoment];
		
		penguinBody.position = cpv(384.0f, 100.0f);
        ChipmunkShape *shape = [ChipmunkPolyShape boxWithBody:penguinBody width:PENGUIN_SIZE height:PENGUIN_SIZE radius: 0];
		shape.elasticity = 0.3f;
		shape.friction = 0.4f;
		shape.collisionType = [Penguin class];
        shape.userData = self;
        chipmunkObjects = [NSArray arrayWithObjects:penguinBody, shape, nil];

		// Allocate an animation timer for the penguins blinking eyes
		eyeAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)EYES_RANDOM_BLINK_INVERVAL target:self selector:@selector(blinkEyes:) userInfo:nil repeats:FALSE];
		fEyesAnimating = NO;
		stripStep = (1.0f / EYESTRIP_NUM_CELLS);
		
		eyeTextureVertices[0] = 0.0f;
		eyeTextureVertices[1] = (1.0f / EYESTRIP_NUM_CELLS);
		eyeTextureVertices[2] = 1.0f;
		eyeTextureVertices[3] = (1.0f / EYESTRIP_NUM_CELLS);
		eyeTextureVertices[4] = 0.0f;
		eyeTextureVertices[5] = 0.0f;
		eyeTextureVertices[6] = 1.0f;
		eyeTextureVertices[7] = 0.0f;
		
		// Allocate an animation timer for the penguins wing wiggles
		wingAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)WING_RANDOM_WIGGLE_INVERVAL target:self selector:@selector(wiggleWing:) userInfo:nil repeats:FALSE];
		fwingAnimating = NO;
		wingAngleStep = 1;
		wingAngleDelta = 0;
		
		// Allocate an animation timer for penguin fade-in effect
		fadeinAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.01f target:self selector:@selector(penguinFadeIn:) userInfo:nil repeats:TRUE];
		id appDelegate   = [[UIApplication sharedApplication] delegate];
		
        AVAudioPlayer *player = [appDelegate getPlayer2];
		[player play];
    }
    return self;
}


- (void)penguinFadeIn:(NSTimer*)theTimer
{
	penguinAlpha += 0.01f;
	
	if (penguinAlpha >= 1.0f)
	{
		penguinAlpha = 1.0f;
		[fadeinAnimationTimer invalidate];
	}
}


- (void)wiggleWing:(NSTimer*)theTimer
{	
	if (NO == fwingAnimating)
	{
		wiggleAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)WING_WIGGLE_STEP_TIME target:self selector:@selector(wiggleWing:) userInfo:nil repeats:TRUE];
		fwingAnimating = YES;
	}
	
	wingAngleDelta += wingAngleStep;
	
	if (wingAngleDelta < -10)
	{
		[wiggleAnimationTimer invalidate];
		fwingAnimating = NO;
	}
	
	if (wingAngleDelta > 7 || wingAngleDelta < -10)
	{
		wingAngleStep *= -1;
	}

	if (NO == fwingAnimating)
	{
		wingAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)WING_RANDOM_WIGGLE_INVERVAL target:self selector:@selector(wiggleWing:) userInfo:nil repeats:FALSE];
	}
}


- (void)blinkEyes:(NSTimer*)theTimer
{
	if (NO == fEyesAnimating)
	{
		blinkAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)EYES_BLINK_STEP_TIME target:self selector:@selector(blinkEyes:) userInfo:nil repeats:TRUE];
		fEyesAnimating = YES;
	}
	
	eyeTextureVertices[1] += stripStep;
	eyeTextureVertices[3] += stripStep;
	eyeTextureVertices[5] += stripStep;
	eyeTextureVertices[7] += stripStep;
	if (eyeTextureVertices[1] > 1.0f)
	{
		stripStep *= -1.0f;
		eyeTextureVertices[1] = 1.0f;
		eyeTextureVertices[3] = 1.0f;
		eyeTextureVertices[5] = 1.0f - (1.0f / EYESTRIP_NUM_CELLS);
		eyeTextureVertices[7] = 1.0f - (1.0f / EYESTRIP_NUM_CELLS);
	}
	else if (eyeTextureVertices[1] < (1.0f / EYESTRIP_NUM_CELLS))
	{   
		stripStep *= -1.0f;
		eyeTextureVertices[1] = (1.0f / EYESTRIP_NUM_CELLS);
		eyeTextureVertices[3] = (1.0f / EYESTRIP_NUM_CELLS);
		eyeTextureVertices[5] = 0.0f;
		eyeTextureVertices[7] = 0.0f;
		
		[blinkAnimationTimer invalidate];
		fEyesAnimating = NO;
	}
	
	if (NO == fEyesAnimating)
	{
		eyeAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)EYES_RANDOM_BLINK_INVERVAL target:self selector:@selector(blinkEyes:) userInfo:nil repeats:FALSE];
	}
}


static cpFloat frand_unit(){return 2.0f*((cpFloat)rand()/(cpFloat)RAND_MAX) - 1.0f;}


- (void) movePenguin: (cpVect)v
{
	penguinBody.velocity     = cpvadd(penguinBody.velocity, v);
	penguinBody.angularVelocity += 5.0f*frand_unit();
}


- (void)loadPNG: (NSString *)imgname
{
	NSString *path = [[NSBundle mainBundle] pathForResource:imgname ofType:@"png"];
	NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
	UIImage *image = [[UIImage alloc] initWithData:texData];
	if (image == nil)
		NSLog(@"Do real error checking here");
	
	GLuint width = CGImageGetWidth(image.CGImage);
	GLuint height = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	void *imageData = malloc( height * width * 4 );
	CGContextRef contextm = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
	CGColorSpaceRelease( colorSpace );
	CGContextClearRect( contextm, CGRectMake( 0, 0, width, height ) );
	CGContextTranslateCTM( contextm, 0, height - height );
	CGContextDrawImage( contextm, CGRectMake( 0, 0, width, height ), image.CGImage );
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	
	CGContextRelease(contextm);
	
	free(imageData);
	[image release];
	[texData release];
}


- (void)render
{
	// Convert penguin body position from Chipmunk space into GL screen space
	GLfloat penguinXPos  = (((penguinBody.position.x / SCREEN_WIDTH_PIXELS)  * 2.0f) - 1.0f);
	GLfloat penguinYPos  = (((penguinBody.position.y / SCREEN_HEIGHT_PIXELS) * 2.0f) - 1.0f);
	//GLfloat penguinAngle = penguinBody.angle;
	GLfloat penguinAngle = 0.0f;

	glColor4f(1, 1, 1, penguinAlpha);

	glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	
	// Draw the penguins body
	glLoadIdentity();
	glRotatef(penguinAngle, 0.0f, 0.0f, 1.0f);
	glTranslatef(penguinXPos, penguinYPos, 0.0f);
    glVertexPointer(2, GL_FLOAT, 0, bodyVertices);
	glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_BODY]);
    glTexCoordPointer(2, GL_FLOAT, 0, genTextureVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Draw the penguins wing
	glLoadIdentity();
	glRotatef(penguinAngle, 0.0f, 0.0f, 1.0f);
	glTranslatef(penguinXPos + WING_BODY_OFFSET_X, penguinYPos + WING_BODY_OFFSET_Y, 0.0f);
	glRotatef(wingAngleDelta, 0.0f, 0.0f, 1.0f);
	glVertexPointer(2, GL_FLOAT, 0, wingVertices);
	glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_WING]);
    glTexCoordPointer(2, GL_FLOAT, 0, genTextureVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	
	// Draw the penguins eyes
	glLoadIdentity();
	glRotatef(penguinAngle, 0.0f, 0.0f, 1.0f);
    glTranslatef(penguinXPos + EYES_BODY_OFFSET_X, penguinYPos + EYES_BODY_OFFSET_Y, 0.0f);
	glScalef(0.9f, 0.9f, 0.0f);
	glVertexPointer(2, GL_FLOAT, 0, eyeVertices);
	glBindTexture(GL_TEXTURE_2D, texture[PENGUIN_TEXTURE_EYES]);
    glTexCoordPointer(2, GL_FLOAT, 0, eyeTextureVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
		
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glColor4f(1, 1, 1, 1);

}


- (void)dealloc 
{
    [super dealloc];
}


@end
