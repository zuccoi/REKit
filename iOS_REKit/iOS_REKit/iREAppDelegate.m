/*
 iREAppDelegate.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "iREAppDelegate.h"
#import "iREViewController.h"


@implementation iREAppDelegate

//--------------------------------------------------------------//
#pragma mark -- ApplicationDelegate --
//--------------------------------------------------------------//

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Show window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[iREViewController alloc] initWithNibName:@"iREViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

@end
