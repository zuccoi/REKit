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

- (void)test_observingInfos
{
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	
	// Make elements
	NSArray *observingInfos;
	NSArray *observedInfos;
	observingInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0}];
	observedInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0}];
	
	// Add observer
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Remove observer with context
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[person removeObserver:observer forKeyPath:@"name" context:nil];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	[person addObserver:observer forKeyPath:@"name" options:0 context:nil];
	[observer stopObserving];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Add observer using block
	NSDictionary *observingInfo;
	NSDictionary *observedInfo;
	REObserverHandler block;
	block = ^(NSDictionary *change) {
		// Do nothing
	};
	block = Block_copy(block);
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:block];
	observingInfo = @{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0, REObserverBlockKey : block};
	observedInfo = @{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0, REObserverBlockKey : block};
	STAssertEqualObjects([observer observingInfos][0], observingInfo, @"");
	STAssertEqualObjects([person observedInfos][0], observedInfo, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Remove observer with context
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		// Do nothing
	}];
	[person removeObserver:observer forKeyPath:@"name" context:nil];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	observer = [person addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		// Do nothing
	}];
	[observer stopObserving];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
}

- (void)test_observingInfosWithContext
{
	// Make person
	REPerson *person;
	person = [REPerson person];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	
	// Make elements
	NSString *context;
	NSArray *observingInfos;
	NSArray *observedInfos;
	context = @"context";
	observingInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservedObjectKey : person, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	observedInfos = @[@{REObserverKeyPathKey : @"name", REObserverObservingObjectKey : observer, REObserverOptionsKey : @0, REObserverContextPointerValueKey : [NSValue valueWithPointer:context]}];
	
	// Add observer
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer
	[person removeObserver:observer forKeyPath:@"name"];
	STAssertEqualObjects([observer observingInfos], observingInfos, @"");
	STAssertEqualObjects([person observedInfos], observedInfos, @"");
	
	// Remove observer with context
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	[person removeObserver:observer forKeyPath:@"name" context:context];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
	
	// Stop observing
	[person addObserver:observer forKeyPath:@"name" options:0 context:context];
	[observer stopObserving];
	STAssertEqualObjects([observer observingInfos], @[], @"");
	STAssertEqualObjects([person observedInfos], @[], @"");
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

- (void)test_ordinalAddObserver_toObjectsAtIndexes
{
	__block BOOL observed;
	
	// Make persons
	NSArray *persons;
	persons = @[[REPerson person], [REPerson person], [REPerson person]];
	
	// Make observer
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	[persons addObserver:observer toObjectsAtIndexes:[NSIndexSet indexSetWithIndex:1] forKeyPath:@"name" options:0 context:nil];
	
	// Change 2nd person's name
	observed = NO;
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
		STAssertEqualObjects(receiver, observer, @"");
		STAssertEqualObjects(keyPath, @"name", @"");
		STAssertEqualObjects(object, persons[1], @"");
		STAssertEqualObjects(change, @{NSKeyValueChangeKindKey : @(NSKeyValueChangeSetting)}, @"");
		STAssertNil(context, @"");
	}];
	((REPerson*)persons[1]).name = @"name";
	STAssertTrue(observed, @"");
	[observer removeBlockNamed:@"blockName"];
	
	// Change 1st person's name
	observed = NO;
	[observer respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withBlockName:@"blockName" usingBlock:^(id receiver, NSString *keyPath, id object, NSDictionary *change, void *context) {
		observed = YES;
	}];
	((REPerson*)persons[0]).name = @"name";
	STAssertFalse(observed, @"");
}

@end
