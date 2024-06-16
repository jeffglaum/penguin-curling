//
//  ESRenderer.h
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <ObjectiveChipmunk.h>

@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (cpVect)mouseToSpace:(cpVect)pos;
- (bool) createPengi;
- (void) objectMove:(cpVect) v;

@end
