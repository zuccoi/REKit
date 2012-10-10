/*
 RSAppDelegate.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "RSAppDelegate.h"
#import "RSMasterViewController.h"
#import "RSClassAA.h"


@implementation RSAppDelegate

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//
@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize masterViewController = _masterViewController;

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (void)dealloc
{
	// Release
	[_window release], _window = nil;
	[_navigationController release], _navigationController = nil;
	[_masterViewController release], _masterViewController = nil;
	
	// super
	[super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- ApplicationDelegate --
//--------------------------------------------------------------//

- (void)_test
{
	RSClassA *objA;
	objA = [[RSClassA alloc] init];
//	[objA log];
//	[objA respondsToSelector:@selector(log) usingBlock:^{
//		NSLog(@"%s - line %d", __PRETTY_FUNCTION__, __LINE__);
//	}];
	
	RSClassAA *objAA;
	objAA = [[[RSClassAA alloc] init] autorelease];
	NSLog(@"responds = %@", [objAA respondsToSelector:@selector(log)] ? @"YES" : @"NO");
	[objAA log];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Make masterViewController
	self.masterViewController = [[[RSMasterViewController alloc] init] autorelease];
	
	// Make navigationController
	self.navigationController = [[[UINavigationController alloc] initWithRootViewController:self.masterViewController] autorelease];
	
	// Make window
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.window.rootViewController = self.navigationController;
	
	// Show window
	[self.window makeKeyAndVisible];
	
	// Test
	[self _test];
	
#if 1
	id obj;
	__block NSString *blockName;
	obj = [[[NSObject alloc] init] autorelease];
	[obj respondsToSelector:@selector(say:) usingBlock:^{
		NSLog(@"blockName = %@", blockName);
	} blockName:&blockName];
	[obj performSelector:@selector(say:) withObject:@"Hello"];
	NSLog(@"blockNamed: = %@", [obj blockNamed:blockName]);
#else
	id obj;
	NSString *blockName;
	blockName = @"blockName";
	obj = [[[NSObject alloc] init] autorelease];
	[obj respondsToSelector:@selector(say:) usingBlock:^{
		NSLog(@"blockName = %@", blockName);
	} blockName:&blockName];
	[obj performSelector:@selector(say:) withObject:@"Hello"];
	NSLog(@"blockNamed: = %@", [obj blockNamed:blockName]);
#endif
	
	return YES;
}

@end
