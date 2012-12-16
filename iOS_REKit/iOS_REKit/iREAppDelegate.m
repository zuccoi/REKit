/*
 iREAppDelegate.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "iREAppDelegate.h"
#import "iREViewController.h"


@implementation iREAppDelegate

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (void)dealloc
{
	[_window release];
	[_viewController release];
    [super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- ApplicationDelegate --
//--------------------------------------------------------------//

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
	self.viewController = [[[iREViewController alloc] initWithNibName:@"iREViewController" bundle:nil] autorelease];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
