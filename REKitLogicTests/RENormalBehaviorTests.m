/*
 RENormalBehaviorTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "RENormalBehaviorTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation RENormalBehaviorTests

- (void)test_classMethodReturnsClassInstance
{
	id obj;
	obj = [NSObject object];
	
	STAssertEquals([NSObject class], [obj class], @"");
	STAssertEquals([NSObject class], [[obj class] class], @"");
	STAssertEquals([NSObject class], [[NSObject class] class], @"");
}

- (void)test_object_getClassReturnsClassInstanceForInstance
{
	id obj;
	obj = [NSObject object];
	
	STAssertEquals([NSObject class], object_getClass(obj), @"");
}

- (void)test_object_getClassReturnsMetaClassForClassInstance
{
	id obj;
	obj = [NSObject object];
	
	STAssertFalse(object_getClass([NSObject class]) == [NSObject class], @"");
	STAssertEquals(object_getClass([NSObject class]), object_getClass([obj class]), @"");
}

- (void)test_object_getClassReturnsMetaClassForMetaClass
{
	STAssertEquals(object_getClass(object_getClass([NSObject class])), object_getClass([NSObject class]), @"");
}

- (void)test_forwardingMethodsIsSame
{
	SEL sel = @selector(unexistingMethod);
	
	id obj;
	obj = [NSObject object];
	STAssertEquals([obj methodForSelector:sel], [NSObject methodForSelector:sel], @"");
	STAssertEquals([NSObject instanceMethodForSelector:sel], [NSObject methodForSelector:sel], @"");
}

- (void)test_methodForSelectorReturnsForwardingMethodForClassInstance
{
	SEL sel = @selector(unexistingMethod);
	
	IMP imp;
	imp = [NSObject methodForSelector:sel];
	STAssertNotNil((id)imp, @"");
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_methodForSelectorReturnsForwardingMethodForMetaClass
{
	SEL sel = @selector(unexistingMethod);
	
	IMP imp;
	imp = [object_getClass([NSObject class]) methodForSelector:sel];
	STAssertNotNil((id)imp, @"");
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_class_getMethodImplementationReturnsForwardingMethod
{
	SEL sel = @selector(unexistingMethod);
	IMP imp;
	
	imp = class_getMethodImplementation([NSObject class], sel);
	STAssertNotNil((id)imp, @"");
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	imp = class_getMethodImplementation(object_getClass([NSObject class]), sel);
	STAssertNotNil((id)imp, @"");
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_methodForSelectorReturnsForwardingMethodForInstance
{
	SEL sel = @selector(unexistingMethod);
	IMP imp;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Check
	imp = [obj methodForSelector:sel];
	STAssertNotNil((id)imp, @"");
	STAssertEquals(imp, [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_methodForSelectorSearchesSuperClassMethodForInstance
{
	RETestObject *obj;
	RESubTestObject *subObj;
	obj = [[[RETestObject alloc] init] autorelease];
	subObj = [[[RESubTestObject alloc] init] autorelease];
	
	IMP imp;
	IMP subImp;
	imp = [obj methodForSelector:@selector(log)];
	subImp = [subObj methodForSelector:@selector(log)];
	STAssertEquals(imp, subImp, @"");
}

- (void)test_methodForSelectorSearchesSuperClassMethodForClass
{
	IMP imp;
	IMP subImp;
	imp = [RETestObject methodForSelector:@selector(integerWithInteger:)];
	subImp = [RESubTestObject methodForSelector:@selector(integerWithInteger:)];
	STAssertEquals(imp, subImp, @"");
}

- (void)test_methodForSelectorReturnsOverriddenImplementation
{
	RETestObject *obj;
	RESubTestObject *subObj;
	obj = [[[RETestObject alloc] init] autorelease];
	subObj = [[[RESubTestObject alloc] init] autorelease];
	
	IMP imp;
	IMP subImp;
	imp = [obj methodForSelector:@selector(overrideMe)];
	subImp = [subObj methodForSelector:@selector(overrideMe)];
	STAssertFalse(imp == subImp, @"");
}

- (void)test_classInstanceDoesNotRespondToUnexistingMethod
{
	SEL sel = @selector(unexistingMethod);
	STAssertFalse([NSObject respondsToSelector:sel], @"");
}

- (void)test_metaClassDoesNotRespondToUnexistingMethod
{
	SEL sel = @selector(unexistingMethod);
	STAssertFalse([object_getClass([NSObject class]) respondsToSelector:sel], @"");
}

- (void)test_instanceDoesNotRespondToUnexistingMethod
{
	SEL sel = @selector(unexistingMethod);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Check
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_classInstanceDoesNotRespondToInstanceMethod
{
	STAssertFalse([RETestObject respondsToSelector:@selector(log)], @"");
}

- (void)test_instanceDoesNotRespondsToClassMethod
{
	SEL sel = @selector(array);
	NSArray *array;
	array = [NSArray array];
	STAssertFalse([array respondsToSelector:sel], @"");
}

@end
