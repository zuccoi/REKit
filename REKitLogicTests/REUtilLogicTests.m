/*
 REUtilLogicTests.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "RETestObject.h"
#import "REUtilLogicTests.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REUtilLogicTests

- (void)test_REGetClass
{
	id obj;
	obj = [NSObject object];
	
	Class class;
	class = [NSObject class];
	
	STAssertEquals(REGetClass(obj), class, @"");
	STAssertEquals(REGetClass([NSObject class]), class, @"");
	STAssertEquals(REGetClass(object_getClass([NSObject class])), class, @"");
}

- (void)test_REGetMetaClass
{
	id obj;
	obj = [NSObject object];
	
	Class metaClass;
	metaClass = object_getClass([NSObject class]);
	
	STAssertEquals(REGetMetaClass(obj), metaClass, @"");
	STAssertEquals(REGetMetaClass([NSObject class]), metaClass, @"");
	STAssertEquals(REGetMetaClass(object_getClass([NSObject class])), metaClass, @"");
}

- (void)test_RESubclassesOfClass
{
	NSSet *subclasses;
	NSSet *expected;
	
	// Pass nil
	subclasses = RESubclassesOfClass(nil, NO);
	STAssertNil(subclasses, @"");
	
	// Get subclasses of RETestObject
	subclasses = [RESubclassesOfClass([RETestObject class], NO) filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class aClass, NSDictionary *bindings) {
		NSString *className;
		className = NSStringFromClass(aClass);
		return (![className hasPrefix:@"REResponder_"] && ![className hasPrefix:@"NSKVONotifying_"]);
	}]];
	expected = [NSSet setWithArray:@[[RESubTestObject class]]];
	STAssertEqualObjects(subclasses, expected, @"");
	
	// Get subclasses of RERestObject
	subclasses = [RESubclassesOfClass([RETestObject class], YES) filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class aClass, NSDictionary *bindings) {
		NSString *className;
		className = NSStringFromClass(aClass);
		return (![className hasPrefix:@"REResponder_"] && ![className hasPrefix:@"NSKVONotifying_"]);
	}]];
	expected = [NSSet setWithArray:@[[RETestObject class], [RESubTestObject class]]];
	STAssertEqualObjects(subclasses, expected, @"");
}

- (void)test_willChangeClass
{
	__block Class newClass = nil;
	
	// Register to notification center
	[[NSNotificationCenter defaultCenter] addObserverForName:REObjectWillChangeClassNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		newClass = NSClassFromString([note userInfo][REObjectNewClassNameKey]);
	}];
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Call willChangeClass
	[obj willChangeClass:NSStringFromClass([NSArray class])];
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
	obj = [RETestObject object];
	
	// Call didChangeClass
	[obj didChangeClass:NSStringFromClass([RETestObject class])];
	STAssertEquals(oldClass, [RETestObject class], @"");
}

@end
