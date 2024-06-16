//
//  EAGLView.h
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ESRenderer.h"
#import "Penguin.h"

#define SCREEN_WIDTH_PIXELS		768.0f
#define SCREEN_HEIGHT_PIXELS	1024.0f


// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{    
@private
    id <ESRenderer> renderer;

    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
    // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
    // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
    // isn't available.
    NSTimer *animationTimer;
	CADisplayLink *displayLink;
	CADisplayLink *mydisplayLink;

	ChipmunkSpace *space;

	cpVect mousePoint;
	cpVect mousePoint_last;
	ChipmunkBody *mouseBody;
	ChipmunkConstraint *mouseJoint;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, retain) id displayLink;
@property (nonatomic, assign) NSTimer *animationTimer;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;
- (void)addBody:(ChipmunkBody *)newbody;
- (IBAction)onPenguinButtonClick:(id)sender;

@end
