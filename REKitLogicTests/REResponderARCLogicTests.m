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
