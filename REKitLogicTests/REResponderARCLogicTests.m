/*
 REResponderARCLogicTests.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderARCLogicTests.h"
#import "RETestObject.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wignored-attributes"


@implementation REResponderARCLogicTests

//--------------------------------------------------------------//
#pragma mark -- Test Case --
//--------------------------------------------------------------//

- (void)test_receiverHavingDynamicBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Do something…
			receiver = receiver;
		});
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_receiverHavingOverrideBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject object];
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			return @"Overridden log";
		});
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_keyOfBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [NSObject object];
		RESetBlock(key, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, @selector(log), NO, key, ^(id receiver) {
			// Do something
			receiver = receiver;
		});
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_contextIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	__block BOOL isObjDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		RESetBlock(context, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		__typeof(context) __weak context_ = context;
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use context
			id ctx;
			ctx = context_;
		});
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
	STAssertTrue(isObjDeallocated, @"");
}

- (void)test_contextOfSuperblockIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	__block BOOL isObjDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		__typeof(context) __weak context_ = context;
		RESetBlock(context, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use context
			id ctx;
			ctx = context_;
		});
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Do nothing…
			id ctx;
			ctx = context_;
		});
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Perform log method
		[obj performSelector:@selector(log)];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
	STAssertTrue(isObjDeallocated, @"");
}

- (void)test_contextOfReusedSuperblockIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	__block BOOL isObjDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		__typeof(context) __weak context_ = context;
		RESetBlock(context, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Add log method
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use context
			id ctx;
			ctx = context_;
		});
		
		// Override log method
		RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
			// Use context
			id ctx;
			ctx = context_;
		});
		
		// Remove top log block
		[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
	STAssertTrue(isObjDeallocated, @"");
}

- (void)test_contextOfRemovedBlockIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		RESetBlock(context, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		
		// Add block
		RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		});
		
		// Perform block
		[obj performSelector:@selector(log)];
		
		// Remove block
		[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
		
		// Check
		STAssertTrue(!isContextDeallocated, @"");
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
}

- (void)test_autoreleasingContextIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	__block BOOL isObjDeallocated = NO;
	__block NSString *string = nil;
	SEL dealloc;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, dealloc);
		});
		
		@autoreleasepool {
			// Make context
			id context;
			context = [NSObject object];
			__typeof(context) __weak context_ = context;
			RESetBlock(context, NSSelectorFromString(@"dealloc"), NO, nil, ^(id receiver) {
				// Raise deallocated flag
				isContextDeallocated = YES;
				
				// supermethod
				RESupermethod(nil, receiver, dealloc);
			});
			
			// Add log block
			RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
				id ctx;
				ctx = context_;
				string = @"called";
			});
		}
		
		// Log
		STAssertNoThrow([obj performSelector:@selector(log)], @"");
	}
	
	// Check
	STAssertEqualObjects(string, @"called", @"");
	STAssertTrue(isContextDeallocated, @"");
	STAssertTrue(isObjDeallocated, @"");
}

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
			context = [RETestObject object];
			RESetBlock(context, dealloc, NO, nil, ^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
			});
			
			// Associate context
			[obj setAssociatedValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
				RETestObject *ctx;
				ctx = [receiver associatedValueForKey:@"context"];
				string = [ctx log];
			});
		}
		
		// Call log method
		STAssertNoThrow([obj performSelector:@selector(log)], @"");
	}
	
	// Check
	STAssertEqualObjects(string, @"log", @"");
	STAssertTrue(deallocated, @"");
}

@end


#pragma clang diagnostic pop
