/*
 REResponderARCLogicTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
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
	__block NSString *string = nil;
	
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
			[context respondsToSelector:dealloc withKey:nil usingBlock:^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
			}];
			
			// Associate context
			[obj associateValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
				RETestObject *ctx;
				ctx = [receiver associatedValueForKey:@"context"];
				string = [ctx log];
			}];
		}
		
		// Call log method
		STAssertNoThrow([obj performSelector:@selector(log)], @"");
	}
	
	// Check
	STAssertEqualObjects(string, @"log", @"");
	STAssertTrue(deallocated, @"");
}

@end
