/*
 REObserverTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REObserverTests.h"


@interface Person : NSObject

// Property
@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger age;

// Object
+ (instancetype)person;

@end


@implementation Person

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
	return [[[Person alloc] init] autorelease];
}

@end

#pragma mark -


@implementation REObserverTests

- (void)test_addObserverUsingBlock
{
	// Make person
	Person *p;
	p = [Person person];
	
	// Add observer
	__block BOOL observed = NO;
	__block NSDictionary *dict = nil;
	[p addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
		dict = change;
	}];
	
	// Change name
	p.name = @"name";
	//
	STAssertTrue(observed, @"");
	STAssertNotNil(dict, @"");
}

- (void)test_removeObserver
{
	// Make person
	Person *p;
	p = [Person person];
	
	// Add observer then remove it
	id observer;
	__block BOOL observed = NO;
	observer = [p addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[p removeObserver:observer forKeyPath:@"name"];
	
	// Change name
	p.name = @"name";
	//
	STAssertFalse(observed, @"");
}

- (void)test_stopObserving
{
	// Make person
	Person *p;
	p = [Person person];
	
	// Add observer then remove it
	id observer;
	__block BOOL observed = NO;
	observer = [p addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
		observed = YES;
	}];
	[observer stopObserving];
	
	// Change name
	p.name = @"name";
	//
	STAssertFalse(observed, @"");
}

@end
