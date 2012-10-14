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

- (void)dealloc
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	// super
	[super dealloc];
}

@end

#pragma mark -


@implementation REObserverTests

- (void)test_addObserver
{
	__block BOOL deallocatedP = NO;
	__block BOOL deallocatedObserver = NO;
	
	@autoreleasepool {
		// Make person
		Person *p;
		p = [Person person];
		
		// Add observer
		id observer;
		observer = [p addObserverForKeyPath:@"name" options:0 usingBlock:^(NSDictionary *change) {
			NSLog(@"change = %@", change);
		}];
		
		// Change name
		p.name = @"name";
		
		// Override dealloc method of p
		[p respondsToSelector:@selector(dealloc) withBlockName:@"block1" usingBlock:^(id me) {
			// super
			IMP supermethod;
			supermethod = [p supermethodOfBlockNamed:@"block1"];
			if (supermethod) {
				supermethod(me, @selector(dealloc));
			}
			
			// Raise deallocatedP
			deallocatedP = YES;
		}];
		
		// Override dealloc method of observer
		[observer respondsToSelector:@selector(dealloc) withBlockName:@"block2" usingBlock:^(id me) {
			// super
			IMP supermethod;
			supermethod = [p supermethodOfBlockNamed:@"block2"];
			if (supermethod) {
				supermethod(me, @selector(dealloc));
			}
			
			// Raise deallocatedObserver
			deallocatedObserver = YES;
		}];
		
		// Change name
		p.name = @"newName";
	}
	
	STAssertTrue(deallocatedP, @"");
	STAssertTrue(deallocatedObserver, @"");
}

@end
