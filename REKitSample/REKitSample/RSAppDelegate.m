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
	
//	id obj;
//	__block NSString *blockName;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string) {
//		NSLog(@"string = %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
//	id obj;
//	NSString *blockName;
//	blockName = @"blockName";
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string){
//		NSLog(@"blockName = %@", blockName);
//		NSLog(@"string = %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
//	id obj;
//	__block NSString *blockName;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string){
//		NSLog(@"blockName = %@", blockName);
//		NSLog(@"string = %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
//	id obj;
//	NSString *blockName;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:nil usingBlock:^(NSString *string){
//		NSLog(@"string = %@", string);
//	}];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string){
//		NSLog(@"string = %@", [string stringByAppendingString:@" World!"]);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj removeBlockNamed:blockName];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
//	id obj;
//	__block NSString *blockName;
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:nil usingBlock:^BOOL(NSString *string){
//		static BOOL _flag = YES;
//		if (_flag) {
//			NSLog(@"%@", string);
//		}
//		_flag = !_flag;
//		return !_flag;
//	}];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^BOOL(NSString *string){
//		BOOL said = NO;
//		BOOL (^superBlock)(NSString *string);
//		superBlock = [obj superBlockOfBlockNamed:blockName];
//		if (superBlock) {
//			said = superBlock(string);
//		}
//		if (said) {
//			NSLog(@"%@", [string stringByAppendingString:@" World!"]);
//		}
//		else {
//			NSLog(@"Hello?");
//		}
//		
//		return YES;
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello!"];
//	[obj performSelector:@selector(say:) withObject:@"Hello!"];
//	[obj performSelector:@selector(say:) withObject:@"Hello!"];
	
//	id obj;
//	NSString *blockName = @"blockName";
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string){
//		NSLog(@"%@", string);
//	}];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string){
//		NSLog(@"Overridden %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello!"];
//	[obj removeBlockNamed:blockName];
//	if ([obj respondsToSelector:@selector(say:)]) {
//		[obj performSelector:@selector(say:) withObject:@"Hello!"];
//	}
	
//	id obj;
//	NSString *blockName1 = @"blockName1";
//	NSString *blockName2 = @"blockname2";
//	obj = [[[NSObject alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName1 usingBlock:^(NSString *string) {
//		NSLog(@"%@", [string stringByAppendingString:@" World!"]);
//	}];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName2 usingBlock:^BOOL(NSString *string) {
//		// super
//		void (^superBlock)(NSString *string);
//		superBlock = [obj superBlockOfBlockNamed:blockName2];
//		if (superBlock) {
//			superBlock(string);
//		}
//		
//		// Say
//		NSLog(@"%@", [string stringByAppendingString:@" REResponder!"]);
//		
//		return YES;
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj removeBlockNamed:blockName1];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
	id obj;
	BOOL res;
	NSString *blockName = @"blockName";
	obj = [[[NSObject alloc] init] autorelease];
	res = [obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string) {
		NSLog(@"%@", [string stringByAppendingString:@" World"]);
	}];
	NSAssert(res, @"");
	res = [obj respondsToSelector:@selector(log:) withBlockName:&blockName usingBlock:^(NSString *string) {
		NSLog(@"%@", string);
	}];
	NSAssert(!res, @"");
	
	return YES;
}

@end
