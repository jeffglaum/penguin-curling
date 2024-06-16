//
//  ES1Renderer.m
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ES1Renderer.h"
#import "PenguinCurlingAppDelegate.h"

// Penguin object
int g_PengiCount = 0;
bool g_fLayoutViewsCalled = FALSE;
Penguin *pPengi[10];

@implementation ES1Renderer

- (bool) createPengi
{
	if (g_PengiCount >= 10)
		return FALSE;
	
	pPengi[g_PengiCount] = [[Penguin alloc] init];

	if (pPengi[g_PengiCount] != NULL)
	{
		if (TRUE == g_fLayoutViewsCalled)
		{
			PenguinCurlingAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
			[[delegate glView] addBody: (ChipmunkBody *)pPengi[g_PengiCount]];
		}
			
		++g_PengiCount;
		return TRUE;
	}
	
	return FALSE;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext: context])
        {
            [self release];
            return nil;
        }

        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
		
		// Load ice texture
		glGenTextures(1, &texture[0]);
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		[self loadPNG: @"IceTarget"];
    }

    return self;
}


-(cpVect) mouseToSpace: (cpVect) pos
{
	cpVect v;
	
	v.x = pos.x;
	v.y = 1024 - pos.y;
	return v;
}


- (void)loadPNG: (NSString *)imgname
{
	NSString *path = [[NSBundle mainBundle] pathForResource: imgname ofType: @"png"];
	NSData *texData = [[NSData alloc] initWithContentsOfFile: path];
	UIImage *image = [[UIImage alloc] initWithData: texData];

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
	static const GLfloat iceVertices[] = {
		-1.0f, -1.0f,
		 1.0f, -1.0f,
        -1.0f,  1.0f,
		 1.0f,  1.0f,
    };
	
	static const GLfloat icetextureVertices[] = {
		0.00f, 1.0f,
		0.75f, 1.0f,
        0.00f, 0.0f,
		0.75f, 0.0f,
    };
	
    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext: context];
	
	glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    // This application only creates a single default framebuffer which is already bound at this point.
    // This call is redundant, but needed if dealing with multiple framebuffers.
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    glClear(GL_COLOR_BUFFER_BIT);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Ice background
	glVertexPointer(2, GL_FLOAT, 0, iceVertices);
	glBindTexture(GL_TEXTURE_2D, texture[0]);
    glTexCoordPointer(2, GL_FLOAT, 0, icetextureVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// Draw the penguins
	int i = 0;
	for (i=0 ; i<g_PengiCount ; i++)
	{
		[pPengi[i] render];
	}
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
    // This application only creates a single color renderbuffer which is already bound at this point.
    // This call is redundant, but needed if dealing with multiple renderbuffers.
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer: GL_RENDERBUFFER_OES];
}


- (void) objectMove:(cpVect) v
{
	[pPengi[(g_PengiCount - 1)] movePenguin: v];
}


- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }

	// Add penguin to chipmunk space
	PenguinCurlingAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	int i=0;
	for (i=0 ; i<g_PengiCount ; i++)
	{
		[[delegate glView] addBody: (ChipmunkBody *)pPengi[i]];
	}
	g_fLayoutViewsCalled = TRUE;
	
    return YES;
}


- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
