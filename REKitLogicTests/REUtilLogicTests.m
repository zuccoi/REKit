/*
 REUtilLogicTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "RETestObject.h"
#import "REUtilLogicTests.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REUtilLogicTests

- (void)test_willChangeClass
{
	__block Class newClass = nil;
	
	// Register to notification center
	[[NSNotificationCenter defaultCenter] addObserverForName:REObjectWillChangeClassNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		newClass = NSClassFromString([note userInfo][REObjectNewClassNameKey]);
	}];
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Call willChangeClass
	[obj willChangeClass:[NSArray class]];
	STAssertEquals(newClass, [NSArray class], @"");
}

- (void)test_didChangeClass
{
	__block Class oldClass = nil;
	
	// Register to notification center
	[[NSNotificationCenter defaultCenter] addObserverForName:REObjectDidChangeClassNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		oldClass = NSClassFromString([note userInfo][REObjectOldClassNameKey]);
	}];
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Call didChangeClass
	[obj didChangeClass:[RETestObject class]];
	STAssertEquals(oldClass, [RETestObject class], @"");
}

#if POST_DID_INIT_NOTIFICATION
- (void)test_REObjectDidInitNotification
{
	__block BOOL notified = NO;
	
	// Observe REObjectDidInitNotification
	[[NSNotificationCenter defaultCenter] addObserverForName:REObjectDidInitNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
		// Get obj
		id obj;
		obj = [note object];
		if ([obj class] != [RETestObject class]) {
			return;
		}
		
		// Raise notified flag
		notified = YES;
	}];
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	STAssertTrue(notified, @"");
}
#endif

@end
