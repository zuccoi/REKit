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

- (void)test_removeObserver
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
	[person removeObserver:observer forKeyPath:@"name"];
	
	// Change name
	person.name = @"name";
	//
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
