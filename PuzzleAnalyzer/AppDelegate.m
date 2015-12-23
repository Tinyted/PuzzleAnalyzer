//
//  AppDelegate.m
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//

#import "AppDelegate.h"
#import "PuzzleVideoController.h"

@interface AppDelegate ()
{

}

@property (nonatomic, strong) PuzzleVideoController *puzzleWindowController;

@end

@implementation AppDelegate

@synthesize puzzleWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    PuzzleVideoController *controller = [[PuzzleVideoController alloc]initWithWindowNibName:@"VideoWindow"];
    [controller showWindow:self];
    puzzleWindowController = controller;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
