//
//  ES1Renderer.h
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <AVFoundation/AVFoundation.h>

#import "Penguin.h"
#import "ObjectiveChipmunk.h"
#import "EAGLView.h"

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
	GLuint texture[4];
}

- (void) render;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) loadPNG:(NSString *)imgname;
- (bool) createPengi;
- (void) objectMove:(cpVect) v;
@end
