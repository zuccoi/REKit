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
//	obj = [[[RSClassA alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"blockName1" usingBlock:^(id me, NSString *string) {
//		NSLog(@"O1 %@", string);
//	}];
//	[obj say:@"O1"];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"blockName2" usingBlock:^(id me, NSString *string) {
//		NSLog(@"O2 %@", string);
//	}];
//	[obj say:@"O2"];
//	[obj removeBlockNamed:@"blockName2"];
//	[obj say:@"O1"];
//	[obj removeBlockNamed:@"blockName1"];
//	[obj say:@"Bye"];
//	[obj respondsToSelector:@selector(log) withBlockName:nil usingBlock:^(id me) {
//		NSLog(@"Overridden Log");
//	}];
//	[obj log];
//	[obj respondsToSelector:@selector(message:) withBlockName:nil usingBlock:^(id me, NSString *message) {
//		NSLog(@"message is \"%@\"", message);
//	}];
//	[obj performSelector:@selector(message:) withObject:@"Message"];
//	
//	RSClassA *obj2;
//	obj2 = [[[RSClassA alloc] init] autorelease];
//	[obj2 respondsToSelector:@selector(say:) withBlockName:@"blockName3" usingBlock:^(id me, NSString *string) {
//		NSLog(@"O3 %@", string);
//	}];
//	[obj2 performSelector:@selector(say:) withObject:@"O3"];
//}

//{
//	RSClassA *obj;
//	obj = [[[RSClassA alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"block1" usingBlock:^(id me, NSString *string) {
//		// Call supermethod
//		IMP supermethod;
//		supermethod = [me supermethodOfBlockNamed:@"block1"];
//		if (supermethod) {
//			supermethod(me, @selector(say:), string);
//		}
//		
//		// Say customized string
//		NSLog(@"block1 %@", string);
//	}];
////	[obj say:@"Hello"];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"block2" usingBlock:^(id me, NSString *string) {
//		// Call supermethod
//		IMP supermethod;
//		supermethod = [me supermethodOfBlockNamed:@"block2"];
//		if (supermethod) {
//			supermethod(me, @selector(say:), string);
//		}
//		
//		// Say customized string
//		NSLog(@"block2 %@", string);
//	}];
////	[obj say:@"Hello"];
//	[obj removeBlockNamed:@"block1"];
////	[obj say:@"Hello"];
//	[obj removeBlockNamed:@"block2"];
//	[obj say:@"Hello"];
//}

//{
//	id obj;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"block1" usingBlock:^(id me, NSString *string) {
//		// Call supermethod
//		IMP supermethod;
//		supermethod = [me supermethodOfBlockNamed:@"block1"];
//		if (supermethod) {
//			supermethod(me, @selector(say:), string);
//		}
//		
//		// Say customized string
//		NSLog(@"block1 %@", string);
//	}];
////	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj respondsToSelector:@selector(say:) withBlockName:@"block2" usingBlock:^(id me, NSString *string) {
//		// Call supermethod
//		IMP supermethod;
//		supermethod = [me supermethodOfBlockNamed:@"block2"];
//		if (supermethod) {
//			supermethod(me, @selector(say:), string);
//		}
//		
//		// Say customized string
//		NSLog(@"block2 %@", string);
//	}];
////	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj removeBlockNamed:@"block1"];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//}
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
	
	// Remove superblock >>>
	return YES;
}

@end
