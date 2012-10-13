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
//	[self _test];
	
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
	
//	id obj;
//	BOOL res;
//	NSString *blockName = @"blockName";
//	obj = [[[NSObject alloc] init] autorelease];
//	res = [obj respondsToSelector:@selector(say:) withBlockName:&blockName usingBlock:^(NSString *string) {
//		NSLog(@"%@", [string stringByAppendingString:@" World"]);
//	}];
//	NSAssert(res, @"");
//	res = [obj respondsToSelector:@selector(log:) withBlockName:&blockName usingBlock:^(NSString *string) {
//		NSLog(@"%@", string);
//	}];
//	NSAssert(!res, @"");
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj removeBlockNamed:blockName];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
	
//	id obj;
//	id obj2 = nil;
//	NSString *blockName1 = @"blockName1";
//	NSString *blockName2 = @"blockName2";
//	obj = [[[RSClassA alloc] init] autorelease];
//	obj2 = [[[RSClassA alloc] init] autorelease];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName1 usingBlock:^(id receiver, NSString *string) {
//		NSLog(@"receiver = %@", receiver);
//		
//		// super
//		void (^superBlock)(id, NSString*);
//		superBlock = [obj superBlockOfBlockNamed:blockName1];
//		if (superBlock) {
//			superBlock(receiver, string);
//		}
//		
//		// Say
//		NSLog(@"Override1 %@", string);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj2 performSelector:@selector(say:) withObject:@"Wow"];
//	[obj respondsToSelector:@selector(say:) withBlockName:&blockName2 usingBlock:^(id receiver, NSString *string) {
//		// super
//		void (^superBlock)(id, NSString*);
//		superBlock = [obj superBlockOfBlockNamed:blockName2];
//		if (superBlock) {
//			superBlock(receiver, string);
//		}
//		
//		// Say
//		NSLog(@"Override2 %@", string);
////		NSLog(@"receiver = %@", receiver);
////		NSLog(@"obj = %@", obj);
//	}];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj2 performSelector:@selector(say:) withObject:@"Wow"];
//	[obj removeBlockNamed:blockName2];
//	[obj removeBlockNamed:blockName1];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj2 performSelector:@selector(say:) withObject:@"Wow"];
//	[obj removeBlockNamed:blockName2];
//	[obj performSelector:@selector(say:) withObject:@"Hello"];
//	[obj2 performSelector:@selector(say:) withObject:@"Wow"];
	// Check if obj will be released >>>
	
//	void (^sayBlock)(id, NSString*);
//	sayBlock = ^(id receiver, NSString *string) {
//		NSLog(@"block says \"%@\"", string);
//	};
//	IMP imp;
//	imp = imp_implementationWithBlock(sayBlock);
//	imp(sayBlock, @selector(say), @"Hello");
	
//	void (^sayBlock)(id, NSString*);
//	sayBlock = ^(id receiver, NSString *string) {
//		NSLog(@"block says \"%@\"", string);
//	};
//	IMP imp;
//	imp = imp_implementationWithBlock(sayBlock);
//	imp(sayBlock, NULL, @"Hello");
	
//	void (^sayBlock)(id, id, SEL, NSString*);
//	sayBlock = ^(id me, id receiver, SEL selector, NSString *string) {
//		NSLog(@"me = %@", me);
//		NSLog(@"receiver = %@", receiver);
//		NSLog(@"selector = %@", NSStringFromSelector(selector));
//		NSLog(@"string = %@", string);
//		objc_msgSend(receiver, selector, string);
//	};
//	IMP imp;
//	imp = imp_implementationWithBlock(sayBlock);
//	imp(sayBlock, NULL, obj2, @selector(say:), @"Hello");
//	sayBlock(sayBlock, obj2, @selector(say:), @"Hello");
//	sayBlock(obj2, obj2, @selector(say:), @"Hello");
	
//	id (^sayBlock)(id, SEL, NSString*);
//	sayBlock = ^(id receiver, SEL selector, NSString *string) {
//		NSLog(@"receiver = %@", receiver);
//		NSLog(@"selector = %@", NSStringFromSelector(selector));
//		NSLog(@"string = %@", string);
//		objc_msgSend(receiver, selector, string);
//		return (id)YES;
//	};
//	IMP imp;
//	NSString *message;
//	imp = imp_implementationWithBlock(sayBlock);
//	message = imp(obj2, NULL, @selector(say:), @"Hello");
//	NSLog(@"message = %@", message ? @"YES" : @"NO");
////	NSLog(@"message = %@", message);
//	message = sayBlock(obj2, @selector(say:), @"Hello");
//	NSLog(@"message = %@", message ? @"YES" : @"NO");
////	NSLog(@"message = %@", message);
	
//	void (^block)(void);
//	block = ^{
//		NSLog(@"block");
//	};
//	[(id)block associateValue:@"Hello" forKey:@"key" policy:OBJC_ASSOCIATION_RETAIN];
//	NSLog(@"value = %@", [(id)block associatedValueForKey:@"key"]);
//	id copiedBlock;
//	copiedBlock = Block_copy(block);
//	NSLog(@"value = %@", [copiedBlock associatedValueForKey:@"key"]);
	
	RSClassA *obj;
//	__block IMP originalIMP;
//	[RSClassA replaceInstanceMethodForSelector:@selector(say:) withOriginalIMP:&originalIMP usingBlock:^(id receiver, NSString *string) {
//		id block;
//		block = [[[[receiver associatedValueForKey:@"REResponder_blocks"] objectForKey:@"say:"] lastObject] objectForKey:@"block"];
//		if (block) {
//			imp_implementationWithBlock(block)(receiver, NULL, string);
//		}
//		else {
//			originalIMP(receiver, @selector(say:), string);
//		}
//	}];
	obj = [[[RSClassA alloc] init] autorelease];
	[obj respondsToSelector:@selector(say:) withBlockName:&(NSString*){@"block1"} usingBlock:^(id receiver, NSString *string) {
		NSLog(@"receiver = %@", receiver);
		NSLog(@"Overridden %@", string);
	}];
	[obj say:@"Hello obj"];
//	[obj removeBlockNamed:@"block1"];
//	[obj say:@"Hello"];
//	//
	id obj2;
//	NSString *blockName2 = @"blockName2";
	obj2 = [[[RSClassA alloc] init] autorelease];
	[obj2 say:@"Hello obj2"];
//	[obj2 respondsToSelector:@selector(say:) withBlockName:&blockName2 usingBlock:^(id receiver, NSString *string) {
//		NSLog(@"receiver = %@", receiver);
//		NSLog(@"Overridden2 %@", string);
//	}];
//	[obj2 say:@"Hello obj2"];
//	[obj2 removeBlockNamed:blockName2];
//	[obj2 say:@"Hello obj2"];
//	[obj respondsToSelector:@selector(message:) withBlockName:&(NSString*){@"messageBlock"} usingBlock:^(id receiver, NSString *message) {
////		NSLog(@"receiver = %@", receiver);
//		NSLog(@"receiver (%@) = %@", NSStringFromClass([receiver class]), receiver);
//		NSLog(@"message = %@", message);
//		[receiver log];
//	}];
//	[obj performSelector:@selector(message:) withObject:@"Message"];
	
	// Remove superBlock >>>
	return YES;
}

@end
