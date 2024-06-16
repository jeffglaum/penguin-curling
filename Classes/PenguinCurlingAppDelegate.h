//
//  PenguinCurlingAppDelegate.h
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class EAGLView;

@interface PenguinCurlingAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
	
	AVAudioPlayer *player;
	AVAudioPlayer *player2;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

-(AVAudioPlayer *)getPlayer;
-(AVAudioPlayer *)getPlayer2;

@end

