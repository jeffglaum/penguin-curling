//
//  PenguinCurlingAppDelegate.m
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PenguinCurlingAppDelegate.h"
#import "EAGLView.h"


@implementation PenguinCurlingAppDelegate

@synthesize window;
@synthesize glView;

-(AVAudioPlayer *)getPlayer
{
	return player;
}

-(AVAudioPlayer *)getPlayer2
{
	return player2;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{	
	// Initialize audio
	NSString *path = [[NSBundle mainBundle] pathForResource:@"bbboard" ofType:@"wav"];
	NSURL *url = [[NSURL alloc] initFileURLWithPath: path];
	player = [[AVAudioPlayer alloc] initWithContentsOfURL: url error: NULL];
	[player prepareToPlay];
	
	NSString *path2 = [[NSBundle mainBundle] pathForResource:@"Transporter" ofType:@"wav"];
	NSURL *url2 = [[NSURL alloc] initFileURLWithPath: path2];
	player2 = [[AVAudioPlayer alloc] initWithContentsOfURL: url2 error: NULL];
	[player2 prepareToPlay];
	
	
    [glView startAnimation];

    // Add a root view controller.
    //
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view = glView;
    
    
	[url release];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)dealloc
{
    [window release];
    [glView release];

    [super dealloc];
}

@end
