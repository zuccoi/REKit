/*
 REObserverLogicTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REObserverLogicTests.h"
#import "RETestObject.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REObserverLogicTests

- (void)test_observingInfos
{
	__block BOOL observed;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverKeyPathKey : @"name",
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverOptionsKey : @0
	}];
	observedInfos = @[@{
		REObserverKeyPathKey : @"name",
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverOptionsKey : @0
	}];
	
	// Add observer
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove observer
	[obj removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Remove observer with context
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj.name = @"name2";
	STAssertTrue(observed, @"");
	[obj removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	obj.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Stop observing
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj.name = @"name4";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	obj.name = @"name5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Add observer using block
	NSDictionary *observingInfo;
	NSDictionary *observedInfo;
	REObserverHandler block;
	observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	block = [[obj associatedValueForKey:@"REObserver_observedInfos"] lastObject][@"block"];
	observingInfo = @{
		REObserverKeyPathKey : @"name",
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverOptionsKey : @0,
		REObserverBlockKey : block
	};
	observedInfo = @{
		REObserverKeyPathKey : @"name",
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverOptionsKey : @0,
		REObserverBlockKey : block
	};
	observed = NO;
	obj.name = @"name6";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos][0], observingInfo, @"");
	STAssertEqualObjects([obj observedInfos][0], observedInfo, @"");
	
	// Remove observer
	[obj removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj.name = @"name7";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Remove observer with context
	observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observed = NO;
	obj.name = @"name8";
	STAssertTrue(observed, @"");
	[obj removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	obj.name = @"name9";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Stop observing
	observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observed = NO;
	obj.name = @"name10";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	obj.name = @"name11";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
}

- (void)test_observingInfosWithContext
{
	__block BOOL observed;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSString *context;
	NSArray *observingInfos;
	NSArray *observedInfos;
	context = @"context";
	observingInfos = @[@{
		REObserverKeyPathKey : @"name",
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverOptionsKey : @0,
		REObserverContextPointerValueKey : [NSValue valueWithPointer:context]
	}];
	observedInfos = @[@{
		REObserverKeyPathKey : @"name",
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverOptionsKey : @0,
		REObserverContextPointerValueKey : [NSValue valueWithPointer:context]
	}];
	
	// Add observer
	[obj addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove observer
	[obj removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove observer with context
	[obj addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj.name = @"name2";
	STAssertTrue(observed, @"");
	[obj removeObserver:observer forKeyPath:@"name" context:context];
	observed = NO;
	obj.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
	
	// Stop observing
	[obj addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj.name = @"name4";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	obj.name = @"nmae5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj observedInfos], @[], @"");
}

- (void)test_observingInfosOfObjectsAtIndexes
{
	__block BOOL observed;
	
	// Make objs
	NSArray *objs;
	RETestObject *obj0, *obj1;
	objs = @[(obj0 = [RETestObject testObject]), (obj1 = [RETestObject testObject])];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSArray *observingInfos;
	NSArray *observedInfos;
	NSIndexSet *indexes;
	NSString *context;
	observingInfos = @[@{
		REObserverContainerKey : objs,
		REObserverKeyPathKey : @"name",
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj0],
		REObserverOptionsKey : @0
	}];
	observedInfos = @[@{
		REObserverContainerKey : objs,REObserverKeyPathKey : @"name",
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverOptionsKey : @0
	}];
	indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
	context = @"context";
	
	// Add observer
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj0.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj0 observedInfos], observedInfos, @"");
	STAssertEqualObjects([obj1 observedInfos], @[], @"");
	
	// Remove observer
	[objs removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:@"name"];
	observed = NO;
	obj0.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Remove observer directly
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj0.name = @"name2";
	STAssertTrue(observed, @"");
	[obj0 removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj0.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Add observer with context
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observingInfos = @[@{
		REObserverContainerKey : objs,REObserverKeyPathKey : @"name",
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj0],
		REObserverOptionsKey : @0,
		REObserverContextPointerValueKey : [NSValue valueWithPointer:context]
	}];
	observedInfos = @[@{
		REObserverContainerKey : objs,REObserverKeyPathKey : @"name",
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverOptionsKey : @0,
		REObserverContextPointerValueKey : [NSValue valueWithPointer:context]
	}];
	observed = NO;
	obj0.name = @"name4";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj0 observedInfos], observedInfos, @"");
	STAssertEqualObjects([obj1 observedInfos], @[], @"");
	
	// Remove observer
	[objs removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:@"name"];
	observed = NO;
	obj0.name = @"name5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Remove observer directly without specifying context
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj0.name = @"name6";
	STAssertTrue(observed, @"");
	[obj0 removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj0.name = @"name7";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Remove observer directly specifying nil context // Can't remove observer. It's normal behavior.
//	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
//	[obj0 removeObserver:observer forKeyPath:@"name" context:nil];
	
	// Remove observer directly specifying context
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj0.name = @"name8";
	STAssertTrue(observed, @"");
	[obj0 removeObserver:observer forKeyPath:@"name" context:context];
	observed = NO;
	obj0.name = @"name9";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Stop observing (withou context)
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	obj0.name = @"name10";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	obj0.name = @"name11";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
	
	// Stop observing (with context)
	[objs addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	obj0.name = @"name12";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	obj0.name = @"name13";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([obj0 observedInfos], @[], @"");
}

- (void)test_addObserverUsingBlock
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer
	__block BOOL observed = NO;
	__block NSDictionary *dict = nil;
	[obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
		dict = change;
	}];
	
	// Change name
	obj.name = @"name";
	//
	STAssertTrue(observed, @"");
	STAssertNotNil(dict, @"");
}

- (void)test_NSKeyVvalueObservingOptionNew
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer
	[obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionNew usingBlock:^(NSDictionary *change) {
		NSDictionary *dictionary;
		dictionary = @{
			NSKeyValueChangeKindKey : @(NSKeyValueChangeSetting),
			NSKeyValueChangeNewKey : @"name",
		};
		STAssertEqualObjects(change, dictionary, @"");
	}];
	obj.name = @"name";
}

- (void)test_NSKeyVvalueObservingOptionOld
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	obj.name = @"old name";
	
	// Add observer
	[obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionOld usingBlock:^(NSDictionary *change) {
		NSDictionary *dictionary;
		dictionary = @{
			NSKeyValueChangeKindKey : @(NSKeyValueChangeSetting),
			NSKeyValueChangeOldKey : @"old name",
		};
		STAssertEqualObjects(change, dictionary, @"");
	}];
	obj.name = @"new name";
}

- (void)test_NSKeyVvalueObservingOptionInitial
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer
	__block BOOL observed = NO;
	[obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionInitial usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	STAssertTrue(observed, @"");
}

- (void)test_NSKeyVvalueObservingOptionPrior
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer
	__block NSUInteger count = 0;
	[obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionPrior usingBlock:^(NSDictionary *change) {
		count++;
		if (count == 1) {
			NSDictionary *dictionary;
			dictionary = @{
				NSKeyValueChangeNotificationIsPriorKey : @YES,
				NSKeyValueChangeKindKey : @(NSKeyValueChangeSetting),
			};
			STAssertEqualObjects(change, dictionary, @"");
		}
		else if (count == 2) {
			NSDictionary *dictionary;
			dictionary = @{
				NSKeyValueChangeKindKey : @(NSKeyValueChangeSetting),
			};
			STAssertEqualObjects(change, dictionary, @"");
		}
		else {
			STFail(@"");
		}
	}];
	obj.name = @"name";
}

- (void)test_removeObserver
{
	__block BOOL observed = NO;
	id observer;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Make observer
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Add observer then remove it
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[obj removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj.name = @"name1";
	STAssertFalse(observed, @"");
	
	// Add observer then remove it
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[obj removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	obj.name = @"name2";
	STAssertFalse(observed, @"");
	
	// Add observer using block then remove it
	observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[obj removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	obj.name = @"name";
	STAssertFalse(observed, @"");
}

- (void)test_stopObserving
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer then remove it
	id observer;
	__block BOOL observed = NO;
	observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[observer stopObserving];
	
	// Change name
	obj.name = @"name";
	//
	STAssertFalse(observed, @"");
}

- (void)test_observationAfterClassChangeCausedByDynamicBlock
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer for name
	__block NSString *recognizedName = nil;
	id observer;
	observer = [obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionNew usingBlock:^(NSDictionary *change) {
		recognizedName = change[NSKeyValueChangeNewKey];
	}];
	
	// Get block
	REObserverHandler block;
	block = [[obj associatedValueForKey:@"REObserver_observedInfos"] lastObject][@"block"];
	
	// Add read method
	NSString *key;
	key = @"key";
	[obj respondsToSelector:NSSelectorFromString(@"read") withKey:key usingBlock:^(id receiver) {
		return @"Dynamic";
	}];
	
	// Change name
	obj.name = @"name";
	//
	STAssertEqualObjects(recognizedName, @"name", @"");
	
	// Check observingInfos and observedInfos
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverBlockKey : block
	}];
	observedInfos = @[@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverBlockKey : block
	}];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove block
	[obj removeBlockForSelector:NSSelectorFromString(@"read") withKey:key];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Change name
	obj.name = @"name2";
	STAssertEqualObjects(recognizedName, @"name2", @"");
}

- (void)test_observationAfterClassChangeCausedByOverrideBlock
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add observer for name
	__block NSString *recognizedName = nil;
	id observer;
	observer = [obj addObserverForKeyPath:@"name" options:NSKeyValueObservingOptionNew usingBlock:^(NSDictionary *change) {
		recognizedName = change[NSKeyValueChangeNewKey];
	}];
	
	// Get block
	REObserverHandler block;
	block = [[obj associatedValueForKey:@"REObserver_observedInfos"] lastObject][@"block"];
	
	// Override log method
	NSString *key;
	key = @"key";
	[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
		return @"Overridden";
	}];
	
	// Change name
	obj.name = @"name";
	//
	STAssertEqualObjects(recognizedName, @"name", @"");
	
	// Check observingInfos and observedInfos
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverBlockKey : block
	}];
	observedInfos = @[@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverBlockKey : block
	}];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove block
	[obj removeBlockForSelector:@selector(log) withKey:key];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Change name
	obj.name = @"name2";
	STAssertEqualObjects(recognizedName, @"name2", @"");
}

- (void)test_ordinalObservationAfterClassChangeCausedByDynamicBlock
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Make observer
	id observer;
	__block NSString *recognizedName = nil;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		recognizedName = change[NSKeyValueChangeNewKey];
	}];
	[obj addObserver:observer forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
	
	// Override log method
	NSString *key;
	key = @"key";
	[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
		return @"Dynamic";
	}];
	
	// Change name
	obj.name = @"name";
	//
	STAssertEqualObjects(recognizedName, @"name", @"");
	
	// Check observingInfos and observedInfos
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew)
	}];
	observedInfos = @[@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew)
	}];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove block
	[obj removeBlockForSelector:@selector(log) withKey:key];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Change name
	obj.name = @"name2";
	STAssertEqualObjects(recognizedName, @"name2", @"");
}

- (void)test_ordinalObservationAfterClassChangeCasedByOverrideBlock
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Make observer
	id observer;
	__block NSString *recognizedName = nil;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		recognizedName = change[NSKeyValueChangeNewKey];
	}];
	[obj addObserver:observer forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
	
	// Override log method
	NSString *key;
	key = @"key";
	[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
		return @"Overridden";
	}];
	
	// Change name
	obj.name = @"name";
	//
	STAssertEqualObjects(recognizedName, @"name", @"");
	
	// Check observingInfos and observedInfos
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew)
	}];
	observedInfos = @[@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew)
	}];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Remove block
	[obj removeBlockForSelector:@selector(log) withKey:key];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj observedInfos], observedInfos, @"");
	
	// Change name
	obj.name = @"name2";
	STAssertEqualObjects(recognizedName, @"name2", @"");
}

- (void)test_observationAtIndexes
{
	// Make objs
	NSArray *objs;
	RETestObject *obj0, *obj1;
	objs = @[(obj0 = [RETestObject testObject]), (obj1 = [RETestObject testObject])];
	
	// Add observer for name
	id observer;
	__block NSString *recognizedName = nil;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withKey:@"key" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		recognizedName = change[NSKeyValueChangeNewKey];
	}];
	[objs addObserver:observer toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)] forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
	
	// Override log method
	[obj0 respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
		return @"Overrideen";
	}];
	
	// Change name
	obj0.name = @"name";
	//
	STAssertEqualObjects(recognizedName, @"name", @"");
	
	// Check observingInfos and observedInfos
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj0],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverContainerKey : objs
	}];
	observedInfos = @[@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : @"name",
		REObserverOptionsKey : @(NSKeyValueObservingOptionNew),
		REObserverContainerKey : objs
	}];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj0 observedInfos], observedInfos, @"");
	
	// Remove block
	[obj0 removeBlockForSelector:@selector(log) withKey:@"key"];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([obj0 observedInfos], observedInfos, @"");
	
	// Change name
	obj0.name = @"name2";
	STAssertEqualObjects(obj0.name, @"name2", @"");
}

- (void)test_stopObservingInDeallocMethod
{
	__block BOOL observed = NO;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	@autoreleasepool {
		// Start observing
		id observer;
		observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			observed = YES;
		}];
		STAssertTrue([[obj observedInfos] count] == 1, @"");
		
		// Cahnge name
		obj.name = @"name";
		
		// observer will be deallocated…
	}
	STAssertTrue(observed, @"");
	STAssertNotNil(obj, @"");
	STAssertTrue([[obj observedInfos] count] == 0, @"");
}

- (void)test_stopObservingStartedByOrdinalMethodInDeallocMethod
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	@autoreleasepool {
		// Start observing
		id observer;
		observer = [[[NSObject alloc] init] autorelease];
		[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
		
		// observer will be deallocated…
	}
	STAssertTrue([[obj observedInfos] count] == 0, @"");
}

- (void)test_stopBeingObservedInDeallocMethod
{
	__block BOOL observed = NO;
	id observer;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Start observing
		observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			observed = YES;
		}];
		STAssertTrue([[observer observingInfos] count] == 1, @"");
		
		// Retain observer
		[observer retain];
		
		// Change name
		obj.name = @"name";
		
		// Observed object (obj) will be deallocated…
	}
	STAssertTrue(observed, @"");
	STAssertNotNil(observer, @"");
	STAssertTrue([[observer observingInfos] count] == 0, @"");
	
	// Release observer
	[observer release];
}

- (void)test_stopBeingObservedStartedByOrdinalMethodInDeallocMethod
{
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Start observing
		[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
		
		// Observed object (obj) will be deallocated…
	}
	STAssertTrue([[observer observingInfos] count] == 0, @"");
}

- (void)test_blockIsDeallocated
{
	__block BOOL released = NO;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Start observing
		id observer;
		observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			// Do nothing…
		}];
		
		// Get block
		id block;
		block = [[obj associatedValueForKey:@"REObserver_observedInfos"] lastObject][@"block"];
		
		// Override methods
		[block respondsToSelector:@selector(release) withKey:nil usingBlock:^(id receiver) {
			released = YES;
		}];
		[block respondsToSelector:@selector(copy) withKey:nil usingBlock:^(id receiver) {
			STFail(@"");
		}];
		[block respondsToSelector:@selector(retain) withKey:nil usingBlock:^(id receiver) {
			STFail(@"");
		}];
		
		// Check retain count of block
		STAssertEquals(CFGetRetainCount(block), (signed long)1, @"");
	}
	
	// Check
	STAssertTrue(released, @"");
}

- (void)test_observingInfosAreDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Strt observing
		id observer;
		observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			// Do something
		}];
		
		// Override dealloc method of observingInfos
		SEL sel = @selector(dealloc);
		[[observer observingInfos] respondsToSelector:sel withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, sel);
			}
		}];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_observedInfosAreDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Strt observing
		id observer;
		observer = [obj addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			// Do something
		}];
		
		// Override dealloc method of observedInfos
		SEL sel = @selector(dealloc);
		[[obj observedInfos] respondsToSelector:sel withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, sel);
			}
		}];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

@end
