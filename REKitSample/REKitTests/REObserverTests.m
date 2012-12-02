/*
 REObserverTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REObserverTests.h"


@interface REPerson : NSObject

// Property
@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger age;

// Object
+ (instancetype)person;

@end


@implementation REPerson

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"name"]
		|| [key isEqualToString:@"age"]
	){
		return YES;
	}
	
	return [NSObject automaticallyNotifiesObserversForKey:key];
}

+ (instancetype)person
{
	return [[[REPerson alloc] init] autorelease];
}

@end

#pragma mark -


@implementation REObserverTests

- (void)test_observingInfos
{
	__block BOOL observed;
	
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0}];
	observedInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0}];
	
	// Add observer
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Remove observer with context
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person.name = @"name2";
	STAssertTrue(observed, @"");
	[person removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	person.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person.name = @"name4";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	person.name = @"name5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Add observer using block
	NSDictionary *observingInfo;
	NSDictionary *observedInfo;
	REObserverHandler block;
	block = ^(NSDictionary *change) {
		observed = YES;
	};
	block = Block_copy(block);
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observingInfo = @{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0, REObserverBlockKey : block};
	observedInfo = @{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0, REObserverBlockKey : block};
	observed = NO;
	person.name = @"name6";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos][0], observingInfo, @"");
	STAssertEqualObjects([person observedInfos][0], observedInfo, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person.name = @"name7";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Remove observer with context
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observed = NO;
	person.name = @"name8";
	STAssertTrue(observed, @"");
	[person removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	person.name = @"name9";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observed = NO;
	person.name = @"name10";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	person.name = @"name11";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
}

- (void)test_observingInfosWithContext
{
	__block BOOL observed;
	
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSString *context;
	NSArray *observingInfos;
	NSArray *observedInfos;
	context = @"context";
	observingInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	observedInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	
	// Add observer
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer with context
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person.name = @"name2";
	STAssertTrue(observed, @"");
	[person removeObserver:observer forKeyPath:@"name" context:context];
	observed = NO;
	person.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person.name = @"name4";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	person.name = @"nmae5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
}

- (void)test_observingInfosOfObjectsAtIndexes
{
	__block BOOL observed;
	
	// Make persons
	NSArray *persons;
	REPerson *person0, *person1;
	persons = @[(person0 = [REPerson person]), (person1 = [REPerson person])];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Make elements
	NSArray *observingInfos;
	NSArray *observedInfos;
	NSIndexSet *indexes;
	NSString *context;
	observingInfos = @[@{REObserverContainerKey : persons, REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person0, REObserverOptionsKey : @0}];
	observedInfos = @[@{REObserverContainerKey : persons,REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0}];
	indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
	context = @"context";
	
	// Add observer
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person0.name = @"name0";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person0 observedInfos], observedInfos, @"");
	STAssertEqualObjects([person1 observedInfos], @[], @"");
	
	// Remove observer
	[persons removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:@"name"];
	observed = NO;
	person0.name = @"name1";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Remove observer directly
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person0.name = @"name2";
	STAssertTrue(observed, @"");
	[person0 removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person0.name = @"name3";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Add observer with context
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observingInfos = @[@{REObserverContainerKey : persons,REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person0, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	observedInfos = @[@{REObserverContainerKey : persons,REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	observed = NO;
	person0.name = @"name4";
	STAssertTrue(observed, @"");
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person0 observedInfos], observedInfos, @"");
	STAssertEqualObjects([person1 observedInfos], @[], @"");
	
	// Remove observer
	[persons removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:@"name"];
	observed = NO;
	person0.name = @"name5";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Remove observer directly without specifying context
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person0.name = @"name6";
	STAssertTrue(observed, @"");
	[person0 removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person0.name = @"name7";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Remove observer directly specifying nil context // Can't remove observer. It's normal behavior.
//	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
//	[person0 removeObserver:observer forKeyPath:@"name" context:nil];
	
	// Remove observer directly specifying context
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person0.name = @"name8";
	STAssertTrue(observed, @"");
	[person0 removeObserver:observer forKeyPath:@"name" context:context];
	observed = NO;
	person0.name = @"name9";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Stop observing (withou context)
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:nil];
	observed = NO;
	person0.name = @"name10";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	person0.name = @"name11";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
	
	// Stop observing (with context)
	[persons addObserver:observer toObjectsAtIndexes:indexes forKeyPath:@"name" options:0 context:context];
	observed = NO;
	person0.name = @"name12";
	STAssertTrue(observed, @"");
	[observer stopObserving];
	observed = NO;
	person0.name = @"name13";
	STAssertFalse(observed, @"");
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person0 observedInfos], @[], @"");
}

- (void)test_addObserverUsingBlock
{
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Add observer
	__block BOOL observed = NO;
	__block NSDictionary *dict = nil;
	[person addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
		dict = change;
	}];
	
	// Change name
	person.name = @"name";
	//
	STAssertTrue(observed, @"");
	STAssertNotNil(dict, @"");
}

- (void)test_removeObserver
{
	__block BOOL observed = NO;
	id observer;
	
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Make observer
	observer = [[[NSObject alloc] init] autorelease];
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	
	// Add observer then remove it
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[person removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person.name = @"name1";
	STAssertFalse(observed, @"");
	
	// Add observer then remove it
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[person removeObserver:observer forKeyPath:@"name" context:nil];
	observed = NO;
	person.name = @"name2";
	STAssertFalse(observed, @"");
	
	// Add observer using block then remove it
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[person removeObserver:observer forKeyPath:@"name"];
	observed = NO;
	person.name = @"name";
	STAssertFalse(observed, @"");
}

- (void)test_stopObserving
{
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Add observer then remove it
	id observer;
	__block BOOL observed = NO;
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[observer stopObserving];
	
	// Change name
	person.name = @"name";
	//
	STAssertFalse(observed, @"");
}

@end
