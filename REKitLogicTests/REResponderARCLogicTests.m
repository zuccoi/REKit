/*
 REResponderARCLogicTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderARCLogicTests.h"
#import "RETestObject.h"


@implementation REResponderARCLogicTests

//--------------------------------------------------------------//
#pragma mark -- Test Case --
//--------------------------------------------------------------//

- (void)test_unfortunatelyKeyOfBlockIsNotDeallocatedIfItWasUsedInBlock
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [[NSObject alloc] init];
		[key respondsToSelector:NSSelectorFromString(@"dealloc") withKey:@"key" usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
		}];
		
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:@selector(log) forKey:key])) {
				supermethod(receiver, @selector(log));
			}
			
			// Do something
			receiver = receiver;
		}];
	}
	
	STAssertFalse(deallocated, @"");
}

- (void)test_associatedKeyOfBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		__weak id weakKey;
		key = [[NSObject alloc] init];
		weakKey = key;
		[key respondsToSelector:NSSelectorFromString(@"dealloc") withKey:@"key" usingBlock:^(id receiver) {
			deallocated = YES;
		}];
		
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		[obj associateValue:key forKey:@"key" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
		[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:@selector(log) forKey:weakKey])) {
				supermethod(receiver, @selector(log));
			}
			
			// Do something
			receiver = receiver;
		}];
	}
	
	STAssertTrue(deallocated, @"");
}

- (void)test_associatedContextIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[NSObject alloc] init];
		
		@autoreleasepool {
			// Make context
			RETestObject *context;
			SEL dealloc;
			dealloc = NSSelectorFromString(@"dealloc");
			context = [RETestObject testObject];
			[context respondsToSelector:dealloc withKey:@"key" usingBlock:^(id receiver) {
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfBlockForSelector:dealloc forKey:@"kye"])) {
					supermethod(receiver, dealloc);
				}
				
				// Raise deallocated flag
				deallocated = YES;
			}];
			
			// Associate context
			[obj associateValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
				id ctx;
				ctx = [receiver associatedValueForKey:@"context"];
				NSLog(@"ctx = %@", ctx);
			}];
			
			// Call log method
			STAssertNoThrow([obj performSelector:@selector(log)], @"");
		}
		
		// Call log method
		STAssertNoThrow([obj performSelector:@selector(log)], @"");
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

@end
