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
	
	// Get subclasses of RETestObject
	subclasses = [RESubclassesOfClass([RETestObject class], YES) filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class aClass, NSDictionary *bindings) {
		NSString *className;
		className = NSStringFromClass(aClass);
		return (![className hasPrefix:@"REResponder_"] && ![className hasPrefix:@"NSKVONotifying_"]);
	}]];
	expected = [NSSet setWithArray:@[[RETestObject class], [RESubTestObject class]]];
	STAssertEqualObjects(subclasses, expected, @"");
}

@end
