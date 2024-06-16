//
//  EAGLView.m
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EAGLView.h"
#import "ES1Renderer.h"
#import "ObjectiveChipmunk.h"
#import "PenguinCurlingAppDelegate.h"


extern ChipmunkBody *body;
static NSString *borderType = @"borderType";

@interface EAGLView ()
@property (nonatomic, getter=isAnimating) BOOL animating;
@end


@implementation EAGLView

@synthesize animating, animationFrameInterval, displayLink, animationTimer;


// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (IBAction)onPenguinButtonClick:(id)sender
{
	[renderer createPengi];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    self = [super initWithCoder:coder];
    if (self)
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];


        renderer = [[ES1Renderer alloc] init];
        if (!renderer)
        {
            [self release];
            return nil;
        }

        animating              = FALSE;
        displayLinkSupported   = FALSE;
        animationFrameInterval = 1;
        displayLink            = nil;
        animationTimer         = nil;

		// Chipmunk physics engine
		//
		space = [[ChipmunkSpace alloc] init];
       
        [space addBounds: cpBBNew(0, SCREEN_HEIGHT_PIXELS, SCREEN_WIDTH_PIXELS, 0) thickness:5.0f elasticity:1.0f friction:0.8f filter: CP_SHAPE_FILTER_ALL collisionType: borderType];
		
		[space addCollisionHandler:self
							 typeA:[Penguin class] typeB:borderType
							 begin:@selector(beginCollision:space:)
						  preSolve:nil
						 postSolve:@selector(postSolveCollision:space:)
						  separate:@selector(separateCollision:space:)
		 ];		
		
        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
		
		[self setMultipleTouchEnabled:YES];

		// Set up the display link to control the timing of the animation.
		mydisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimation)];
		mydisplayLink.frameInterval = 1;
		[mydisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }

    return self;
}

- (void)addBody:(ChipmunkBody *)newbody
{
	[space add: newbody];
}


- (bool)beginCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)space
{
	id appDelegate   = [[UIApplication sharedApplication] delegate];
	AVAudioPlayer *player = [appDelegate getPlayer];
	
	[player play];
	
	return TRUE;
}

- (void)postSolveCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)space 
{
	
}

// The separate callback is called whenever shapes stop touching.
- (void)separateCollision:(cpArbiter*)arbiter space:(ChipmunkSpace*)space {
	CHIPMUNK_ARBITER_GET_SHAPES(arbiter, buttonShape, border);
}


// It is called from the display link every time the screen wants to redraw itself.
- (void)updateAnimation {
	// Step (simulate) the space based on the time since the last update.
	cpFloat dt = displayLink.duration*displayLink.frameInterval;
	[space step:dt];
}

- (void)drawView:(id)sender
{
    [renderer render];
}

- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.

            self.displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];

        self.animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            self.displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            self.animationTimer = nil;
        }

        self.animating = FALSE;
    }
}

- (void)dealloc
{
    [renderer release];
    [displayLink release];

    [super dealloc];
}

- (void)removeFromSuperview
{
	[animationTimer invalidate];
	[super removeFromSuperview];
}



#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

- (void) touchesBegan: (NSSet*) touches withEvent:(UIEvent*) event
{
	if ([touches count] == 1)
    {
		UITouch *touch = [[event touchesForView: self] anyObject];
		cpVect point   = [renderer mouseToSpace: [touch locationInView: self]];

		mousePoint = point;
		NSLog(@"x=%f, y=%f", point.x, point.y);

        ChipmunkShape *shape = [space pointQueryNearest: mousePoint maxDistance: 100.0 filter: CP_SHAPE_FILTER_ALL];
        
		if(shape)
		{
			NSLog(@"Hit!!!");
			mousePoint_last = mousePoint;
			mouseBody.position = mousePoint;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touchA;
    CGPoint pointA, pointB;
    
    if ([touches count] == 1)
    {
        touchA = [[touches allObjects] objectAtIndex:0];
        pointA = [touchA locationInView:self];
        pointB = [touchA previousLocationInView:self];
        
		CGFloat dx = (CGFloat)pointB.x - (CGFloat)pointA.x;
		CGFloat dy = (CGFloat)pointB.y - (CGFloat)pointA.y;

		cpVect v = cpvmult(cpv(-1*dx, dy), 1.0f);
		[renderer objectMove: v]; 
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[space  remove:mouseJoint];
	mouseJoint = nil;
}

@end
