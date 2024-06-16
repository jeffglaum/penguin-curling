//
//  Penguin.h
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "ES1Renderer.h"
#import "ObjectiveChipmunk.h"
#import "PenguinCurlingAppDelegate.h"


#define PENGUIN_SIZE 100.0f
#define PENGUIN_MASS 1.0f

#define PENGUIN_TEXTURE_BODY	0
#define PENGUIN_TEXTURE_EYES	1
#define PENGUIN_TEXTURE_WING	2

@interface Penguin : NSObject <ChipmunkObject>
{
	// Chipmunk physics engine objects
	ChipmunkBody *penguinBody;
    NSArray *chipmunkObjects;
	
	// GL textures that make up the penguin (body, eyes, wing, etc.)
	GLuint texture[3];
	
	NSTimer *fadeinAnimationTimer;
	GLfloat penguinAlpha;

	// Blinking eyes animation timer
	NSTimer *eyeAnimationTimer;
	bool fEyesAnimating;
	GLfloat stripStep;
	NSTimer *blinkAnimationTimer;
	GLfloat eyeTextureVertices[8];

	// Wing wiggle animation timer
	NSTimer *wingAnimationTimer;
	bool fwingAnimating;
	NSTimer *wiggleAnimationTimer;
	int wingAngleStep;
	int wingAngleDelta;
}

@property (readonly) NSArray *chipmunkObjects;

- (void) loadPNG: (NSString *)image;
- (void) render;
- (void) movePenguin: (cpVect)v;
- (void) blinkEyes:(NSTimer*)theTimer;
- (void) wiggleWing:(NSTimer*)theTimer;
- (void) penguinFadeIn:(NSTimer*)theTimer;

@end
