/*
 MREAppDelegate.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "MREAppDelegate.h"
#import "MREViewController.h"
#import "REKit.h"


@implementation MREAppDelegate

//--------------------------------------------------------------//
#pragma mark -- ApplicationDelegate --
//--------------------------------------------------------------//

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// Show viewController
	NSView *view;
	self.viewController = [[MREViewController alloc] initWithNibName:@"MREViewController" bundle:nil];
	view = self.viewController.view;
	view.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
	view.frame = self.view.bounds;
	[self.view addSubview:view];
}

@end
