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

- (void)test_superclassOfNSObjectIsNull
{
	STAssertNil([NSObject superclass], @"");
}

- (void)test_class_getSuperclass__ForNSObjectIsNull
{
	STAssertNil(class_getSuperclass([NSObject class]), @"");
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

- (void)test_methodForSelectorDoesNotReturnInstanceMethodForClassInstance
{
	SEL sel = @selector(log);
	
	IMP imp;
	imp = [RETestObject methodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertTrue(imp != [RETestObject instanceMethodForSelector:sel], @"");
	STAssertTrue(imp != [[RETestObject object] methodForSelector:sel], @"");
}

- (void)test_methodForSelectorDoesNotReturnClassMethodForInstance
{
	SEL sel = @selector(version);
	
	IMP imp;
	imp = [[NSObject object] methodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertTrue(imp != [NSObject methodForSelector:sel], @"");
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
	obj = [RETestObject object];
	subObj = [RESubTestObject object];
	
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
	obj = [RETestObject object];
	subObj = [RESubTestObject object];
	
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

- (void)test_valueAssociatedToMetaClassIsNotObtainableUsingClassInstance
{
	// Associate
	objc_setAssociatedObject(object_getClass([NSObject class]), "key", @"value", OBJC_ASSOCIATION_RETAIN);
	
	// Check associated value
	STAssertEqualObjects(objc_getAssociatedObject(object_getClass([NSObject class]), "key"), @"value", @"");
	
	// Check class instance's one
	id value;
	value = objc_getAssociatedObject([NSObject class], "key");
	STAssertNil(value, @"");
	
	// Tear down
	objc_setAssociatedObject(object_getClass([NSObject class]), "key", nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)test_valueAssociatedToClassInstanceIsNotObtainableUsingMetaClass
{
	// Associate
	objc_setAssociatedObject([NSObject class], "key", @"value", OBJC_ASSOCIATION_RETAIN);
	
	// Check associated value
	STAssertEqualObjects(objc_getAssociatedObject([NSObject class], "key"), @"value", @"");
	
	// Check value of meta class
	STAssertNil(objc_getAssociatedObject(object_getClass([NSObject class]), "key"), @"");
	
	// Tear down
	objc_setAssociatedObject([NSObject class], "key", nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)test_NSStringConcreateClass
{
	NSString *string;
	string = [NSString string];
	
	// Check class
	STAssertEqualObjects(NSStringFromClass([string class]), @"__NSCFConstantString", @"");
	
	// Check superclass
	STAssertEqualObjects(NSStringFromClass([[string class] superclass]), @"__NSCFString", @"");
	
	// Check superclass of superclass
	STAssertEqualObjects(NSStringFromClass([[[string class] superclass] superclass]), @"NSMutableString", @"");
	
	// Check superclass of superclass of superclass
	STAssertEqualObjects(NSStringFromClass([[[[string class] superclass] superclass] superclass]), @"NSString", @"");
}

- (void)test_NSArrayConcreateClass
{
	NSArray *array;
	array = [NSArray array];
	
	// Check class
	STAssertEqualObjects(NSStringFromClass([array class]), @"__NSArrayI", @"");
	
	// Check superclass
	STAssertEqualObjects(NSStringFromClass([[array class] superclass]), @"NSArray", @"");
}

- (void)_reconnectString:(NSString*)string
{
	string = @"reconnected";
}

- (void)test_canReconnectArgument
{
	NSString *string;
	string = @"original";
	[self _reconnectString:string];
	STAssertEqualObjects(string, @"original", @"");
}

- (void)test_classInstanceIsChangedAfterKVO
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Make observers
	id observer1, observer2;
	observer1 = [NSObject object];
	observer2 = [NSObject object];
	
	// Start observing
	Class class1;
	[obj addObserver:observer1 forKeyPath:@"version" options:0 context:nil];
	class1 = object_getClass(obj);
	STAssertEqualObjects(NSStringFromClass(class1), @"NSKVONotifying_NSObject", @"");
	
	// Stop observing
	Class class2;
	[obj removeObserver:observer1 forKeyPath:@"version"];
	class2 = object_getClass(obj);
	STAssertEqualObjects(NSStringFromClass(class2), @"NSObject", @"");
	STAssertTrue(class2 != class1, @"");
	
	// Start observing
	Class class3;
	[obj addObserver:obj forKeyPath:@"version" options:0 context:nil];
	class3 = object_getClass(obj);
	STAssertEqualObjects(NSStringFromClass(class3), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class3 != class2, @"");
	
	// Start observing more
	Class class4;
	[obj addObserver:observer2 forKeyPath:@"version" options:0 context:nil];
	class4 = object_getClass(obj);
	STAssertEqualObjects(NSStringFromClass(class4), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class4 == class3, @"");
	
	// Stop observing
	Class class5;
	[obj removeObserver:observer2 forKeyPath:@"version"];
	class5 = object_getClass(obj);
	STAssertEqualObjects(NSStringFromClass(class5), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class5 == class4, @"");
	
	// Stop observing
	Class class6;
	[obj removeObserver:obj forKeyPath:@"version"];
	class6 = object_getClass(obj);
	STAssertTrue(class6 != class5, @"");
	STAssertTrue(class6 == [NSObject class], @"");
}

- (void)test_metaClassIsChangedAfterKVO
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Make observers
	id observer1, observer2;
	observer1 = [NSObject object];
	observer2 = [NSObject object];
	
	// Start observing
	Class class1;
	[obj addObserver:observer1 forKeyPath:@"version" options:0 context:nil];
	class1 = object_getClass(object_getClass(obj));
	STAssertEqualObjects(NSStringFromClass(class1), @"NSKVONotifying_NSObject", @"");
	
	// Stop observing
	Class class2;
	[obj removeObserver:observer1 forKeyPath:@"version"];
	class2 = object_getClass(object_getClass(obj));
	STAssertEqualObjects(NSStringFromClass(class2), @"NSObject", @"");
	STAssertTrue(class2 != class1, @"");
	
	// Start observing
	Class class3;
	[obj addObserver:obj forKeyPath:@"version" options:0 context:nil];
	class3 = object_getClass(object_getClass(obj));
	STAssertEqualObjects(NSStringFromClass(class3), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class3 != class2, @"");
	
	// Start observing more
	Class class4;
	[obj addObserver:observer2 forKeyPath:@"version" options:0 context:nil];
	class4 = object_getClass(object_getClass(obj));
	STAssertEqualObjects(NSStringFromClass(class4), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class4 == class3, @"");
	
	// Stop observing
	Class class5;
	[obj removeObserver:observer2 forKeyPath:@"version"];
	class5 = object_getClass(object_getClass(obj));
	STAssertEqualObjects(NSStringFromClass(class5), @"NSKVONotifying_NSObject", @"");
	STAssertTrue(class5 == class4, @"");
	
	// Stop observing
	Class class6;
	[obj removeObserver:obj forKeyPath:@"version"];
	class6 = object_getClass(object_getClass(obj));
	STAssertTrue(class6 != class5, @"");
	STAssertTrue(class6 == object_getClass([NSObject class]), @"");
}

- (void)test_valueAssociatedToClassInstanceIsNotSameAfterKVO
{
	// Make obj and associate value
	id obj;
	obj = [NSObject object];
	objc_setAssociatedObject([obj class], "key", @(1), OBJC_ASSOCIATION_RETAIN);
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"version" options:0 context:nil];
	
	// Get associatedValue
	id associatedValue;
	associatedValue = objc_getAssociatedObject(object_getClass(obj), "key");
	STAssertNil(associatedValue, @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"version"];
	
	// Tear down
	objc_setAssociatedObject([obj class], "key", nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)test_valueAssociatedClassInstanceIsSameAfterKVOIfYouUseClassMethod
{
	// Make obj and associate value
	id obj;
	obj = [NSObject object];
	objc_setAssociatedObject([obj class], "key", @(1), OBJC_ASSOCIATION_RETAIN);
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"version" options:0 context:nil];
	
	// Get associatedValue
	id associatedValue;
	associatedValue = objc_getAssociatedObject([obj class], "key");
	STAssertEqualObjects(associatedValue, @(1), @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"version"];
	
	// Tear down
	objc_setAssociatedObject([obj class], "key", nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)test_valueAssociatedToMetaClassIsNotSameAfterKVO
{
	// Make obj and associate value
	id obj;
	obj = [NSObject object];
	objc_setAssociatedObject(object_getClass(object_getClass(obj)), "key", @(1), OBJC_ASSOCIATION_RETAIN);
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"version" options:0 context:nil];
	
	// Get associated value
	id associatedValue;
	associatedValue = objc_getAssociatedObject(object_getClass(object_getClass(obj)), "key");
	STAssertNil(associatedValue, @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"version"];
	
	// Tear down
	objc_setAssociatedObject(object_getClass(object_getClass(obj)), "key", nil, OBJC_ASSOCIATION_RETAIN);
}

@end
