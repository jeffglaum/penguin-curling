//
//  main.m
//  PenguinCurling
//
//  Created by Jeff Glaum on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PenguinCurlingAppDelegate.h"


int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([PenguinCurlingAppDelegate class]));
    [pool release];
    return retVal;
}
