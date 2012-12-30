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

- (void)test_contextIsDeallocated
{
	__block BOOL deallocated = NO;
	SEL sel;
	sel = NSSelectorFromString(@"dealloc");
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[NSObject alloc] init];
		
		@autoreleasepool {
			// Make context
			id context;
			context = [[NSObject alloc] init];
			[context respondsToSelector:sel withKey:@"key" usingBlock:^(id receiver) {
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"key"])) {
					supermethod(receiver, sel);
				}
				
				// Raise deallocated flag
				deallocated = YES;
			}];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
				NSLog(@"context = %@", context);
			}];
			[obj performSelector:@selector(log)];
		}
		[obj performSelector:@selector(log)];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_test // >>>
{
	__block BOOL deallocated = NO;
	SEL sel;
	sel = NSSelectorFromString(@"dealloc");
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[NSObject alloc] init];
		
		@autoreleasepool {
			// Make context
			id context;
			context = [[NSObject alloc] init];
			[context respondsToSelector:sel withKey:@"key" usingBlock:^(id receiver) {
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"key"])) {
					supermethod(receiver, sel);
				}
				
				// Raise deallocated flag
				deallocated = YES;
			}];
			
			// Associate context
			[obj associateValue:context forKey:(void*)context policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
				id ctx;
				ctx = [receiver associatedValueForKey:(void*)context];
				NSLog(@"ctx = %@", ctx);
			}];
			[obj performSelector:@selector(log)];
		}
		[obj performSelector:@selector(log)];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

@end
