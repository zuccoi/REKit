/*
 RSAppDelegate.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "RSAppDelegate.h"
#import "RSMasterViewController.h"
#import "RSClassA.h"
#import "RSClassAA.h"
#import <objc/message.h>


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
//{
//	id obj;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:nil usingBlock:^(id me, NSString *string) {
//		NSLog(@"string = %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//}
//{
//	RSClassA *obj;
////	__block IMP originalIMP;
////	[RSClassA REResponder_replaceInstanceMethodForSelector:@selector(say:) withOriginalIMP:&originalIMP usingBlock:^(id receiver, NSString *string) {
////		id block;
////		block = [[[[receiver associatedValueForKey:@"REResponder_blocks"] objectForKey:@"say:"] lastObject] objectForKey:@"block"];
////		if (block) {
////			imp_implementationWithBlock(block)(receiver, NULL, string);
////		}
////		else {
////			originalIMP(receiver, @selector(say:), string);
////		}
////	}];
//	obj = [[[RSClassA alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&(NSString*){@"block1"} usingBlock:^(id receiver, NSString *string) {
//		NSLog(@"receiver = %@", receiver);
//		NSLog(@"Overridden %@", string);
//	}];
//	[obj say:@"Hello obj"];
////	[obj removeBlockNamed:@"block1"];
////	[obj say:@"Hello"];
////	//
//	id obj2;
////	NSString *blockName2 = @"blockName2";
//	obj2 = [[[RSClassA alloc] init] autorelease];
//	[obj2 say:@"Hello obj2"];
////	[obj2 respondsToSelector:@selector(say:) withBlockName:&blockName2 usingBlock:^(id receiver, NSString *string) {
////		NSLog(@"receiver = %@", receiver);
////		NSLog(@"Overridden2 %@", string);
////	}];
////	[obj2 say:@"Hello obj2"];
////	[obj2 removeBlockNamed:blockName2];
////	[obj2 say:@"Hello obj2"];
////	[obj respondsToSelector:@selector(message:) withBlockName:&(NSString*){@"messageBlock"} usingBlock:^(id receiver, NSString *message) {
//////		NSLog(@"receiver = %@", receiver);
////		NSLog(@"receiver (%@) = %@", NSStringFromClass([receiver class]), receiver);
////		NSLog(@"message = %@", message);
////		[receiver log];
////	}];
////	[obj performSelector:@selector(message:) withObject:@"Message"];
//}
//{
//	RSClassA *obj;
//	NSString *blockName1 = nil;
//	NSString *blockName2 = nil;
//	obj = [[[RSClassA alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName1 usingBlock:^(id me, NSString *string) {
//		NSLog(@"O1 %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"O1"];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName2 usingBlock:^(id me, NSString *string) {
//		NSLog(@"O2 %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"O2"];
//	[obj removeBlockNamed:blockName1];
//	[obj performSelector:@selector(say:) withObject:@"O2"];
//	[obj removeBlockNamed:blockName2];
//	[obj performSelector:@selector(say:) withObject:@"Bye"];
//}
{
	RSClassA *obj;
	obj = [[[RSClassA alloc] init] autorelease];
	[obj respondsToSelector:@selector(say:) withBlockName:@"blockName1" usingBlock:^(id me, NSString *string) {
		NSLog(@"O1 %@", string);
	}];
	[obj say:@"O1"];
	[obj respondsToSelector:@selector(say:) withBlockName:@"blockName2" usingBlock:^(id me, NSString *string) {
		NSLog(@"O2 %@", string);
	}];
	[obj say:@"O2"];
	[obj removeBlockNamed:@"blockName2"];
	[obj say:@"O1"];
	[obj removeBlockNamed:@"blockName1"];
	[obj say:@"Bye"];
	[obj respondsToSelector:@selector(log) withBlockName:nil usingBlock:^{
		NSLog(@"Overridden Log");
	}];
	[obj log];
	[obj respondsToSelector:@selector(message:) withBlockName:nil usingBlock:^(id me, NSString *message) {
		NSLog(@"message is \"%@\"", message);
	}];
	[obj performSelector:@selector(message:) withObject:@"Message"];
	
	RSClassA *obj2;
	obj2 = [[[RSClassA alloc] init] autorelease];
	[obj2 respondsToSelector:@selector(say:) withBlockName:@"blockName3" usingBlock:^(id me, NSString *string) {
		NSLog(@"O3 %@", string);
	}];
	[obj2 performSelector:@selector(say:) withObject:@"O3"];
}
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
	
	// Remove superBlock >>>
	return YES;
}

@end
