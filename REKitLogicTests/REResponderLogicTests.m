/*
 REResponderLogicTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderLogicTests.h"
#import "RETestObject.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderLogicTests

- (void)test_respondsToUnimplementedMethod
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Responds to log method dynamically
	[obj respondsToSelector:sel withKey:nil usingBlock:^NSString*(id receiver) {
		return @"block";
	}];
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block", @"");
}

- (void)test_overrideHardcodedMethod
{
	// You can override hardcoded method
	NSString *log;
	RETestObject *obj;
	obj = [RETestObject testObject];
	[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	log = [obj log];
	STAssertEqualObjects(log, @"Overridden log", @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherInstances
{
	// Make obj and otherObj
	id obj;
	id otherObj;
	obj = [[[NSObject alloc] init] autorelease];
	otherObj = [[[NSObject alloc] init] autorelease];
	
	// Add dynamic block to obj
	[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
		return @"Dynamic log";
	}];
	
	// Check
	STAssertFalse([otherObj respondsToSelector:@selector(log)], @"");
}

- (void)test_overrideBlockDoesNotAffectOtherInstances
{
	NSString *string;
	
	// Make obj and otherObj
	RETestObject *obj;
	RETestObject *otherObj;
	obj = [RETestObject testObject];
	otherObj = [RETestObject testObject];
	
	// Override log method of obj
	[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
		return @"Overridden log";
	}];
	
	// Make other obj
	string = [otherObj log];
	STAssertEquals(string, @"log", @"");
}

- (void)test_usingObjectInDynamicBlockCausesRetainCycle
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		
		// Add log method
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			REVoidIMP supermethod;
			if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
	}
	
	// Check
	STAssertFalse(deallocated, @"");
}

- (void)test_usingObjectInOverrideBlockCausesRetainCycle
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Override log method
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			REVoidIMP supermethod;
			if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
	}
	
	// Check
	STAssertFalse(deallocated, @"");
}

- (void)test_passingObjectAsKeyCausesRetainCycle
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(dealloc) withKey:obj usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
	}
	
	// Check
	STAssertFalse(deallocated, @"");
}

- (void)test_receiverHavingDynamicBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Do something…
			receiver = receiver;
		}];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
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
		obj = [RETestObject testObject];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			return @"Overridden log";
		}];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
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
		key = [[[NSObject alloc] init] autorelease];
		[key respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
			// Do something
			receiver = receiver;
		}];
	}
	
	STAssertTrue(deallocated, @"");
}

- (void)test_keyOfBlockIsDeallocatedWhenObjectIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [[[NSObject alloc] init] autorelease];
		[key respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		RETestObject *obj;
		obj = [RETestObject testObject];
		
		// Override log method using key
		[obj respondsToSelector:@selector(log) withKey:key usingBlock:^(id receiver) {
			// supermethod
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(log));
			}
		}];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

//- (void)test_blockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [[[NSObject alloc] init] autorelease];
//		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
//			// Do something…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block respondsToSelector:@selector(release) withKey:nil usingBlock:^(id receiver) {
//			released = YES;
//		}];
//		[block respondsToSelector:@selector(retain) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		[block respondsToSelector:@selector(copy) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Check retain count of block
//		STAssertEquals(CFGetRetainCount(block), (signed long)1, @"");
//	}
//	
//	// Check
//	STAssertTrue(released, @"");
//}
//
//- (void)test_superblockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [[[NSObject alloc] init] autorelease];
//		
//		// Add log method
//		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block respondsToSelector:@selector(release) withKey:nil usingBlock:^(id receiver) {
//			released = YES;
//		}];
//		[block respondsToSelector:@selector(retain) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		[block respondsToSelector:@selector(copy) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
//			// supermethod
//			IMP supermethod;
//			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//				supermethod(receiver, @selector(log));
//			}
//		}];
//		
//		// Perform log method
//		[obj performSelector:@selector(log)];
//		
//		// Check retain count of block
//		STAssertEquals(CFGetRetainCount(block), (signed long)1, @"");
//	}
//	
//	// Check
//	STAssertTrue(released, @"");
//}
//
//- (void)test_reusedSuperblockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [[[NSObject alloc] init] autorelease];
//		
//		// Add log method
//		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block respondsToSelector:@selector(release) withKey:nil usingBlock:^(id receiver) {
//			released = YES;
//		}];
//		[block respondsToSelector:@selector(retain) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		[block respondsToSelector:@selector(copy) withKey:nil usingBlock:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Remove top log block
//		[obj removeBlockForSelector:@selector(log) withKey:@"key"];
//		
//		// Check retain count of block
//		STAssertEquals(CFGetRetainCount(block), (signed long)1, @"");
//	}
//	
//	// Check
//	STAssertTrue(released, @"");
//}

- (void)test_contextIsDeallocated
{
	__block BOOL isContextDeallocated = NO;
	__block BOOL isObjDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [[[NSObject alloc] init] autorelease];
		[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
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
		context = [[[NSObject alloc] init] autorelease];
		[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Do nothing…
			id ctx;
			ctx = context;
		}];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
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
		context = [[[NSObject alloc] init] autorelease];
		[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Add log method
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Remove top log block
		[obj removeBlockForSelector:@selector(log) withKey:@"key"];
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
		context = [[[NSObject alloc] init] autorelease];
		[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[NSObject alloc] init];
		
		// Add block
		[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Perform block
		[obj performSelector:@selector(log)];
		
		// Remove block
		[obj removeBlockForSelector:@selector(log) withKey:@"key"];
		
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
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, dealloc);
			}
		}];
		
		@autoreleasepool {
			// Make context
			__autoreleasing id context;
			context = [[[NSObject alloc] init] autorelease];
			[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
				// Raise deallocated flag
				isContextDeallocated = YES;
				
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfCurrentBlock])) {
					supermethod(receiver, dealloc);
				}
			}];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
				id ctx;
				ctx = context;
				string = @"called";
			}];
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
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		
		@autoreleasepool {
			// Make context
			RETestObject *context;
			context = [RETestObject testObject];
			[context respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
				
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfCurrentBlock])) {
					supermethod(receiver, @selector(dealloc));
				}
			}];
			
			// Associate context
			[obj associateValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
				id ctx;
				ctx = [receiver associatedValueForKey:@"context"];
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

- (void)test_allowArguments
{
	id obj;
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block with arguments
	[obj respondsToSelector:NSSelectorFromString(@"logWithSuffix:") withKey:nil usingBlock:^NSString*(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call logWithSuffix: method
	log = [obj performSelector:NSSelectorFromString(@"logWithSuffix:") withObject:@"suffix"];
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	id obj;
	SEL sel = NSSelectorFromString(@"makeRectWithOrigin:size:");
	CGRect rect;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block
	[obj respondsToSelector:sel withKey:@"block" usingBlock:^CGRect(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Call the method
	NSInvocation *invocation;
	CGPoint origin;
	CGSize size;
	origin = CGPointMake(10.0f, 20.0f);
	size = CGSizeMake(30.0f, 40.0f);
	invocation = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[invocation setTarget:obj];
	[invocation setSelector:sel];
	[invocation setArgument:&origin atIndex:2];
	[invocation setArgument:&size atIndex:3];
	[invocation invoke];
	[invocation getReturnValue:&rect];
	STAssertEquals(rect, CGRectMake(10.0f, 20.0f, 30.0f, 40.0f), @"");
}

- (void)test_methodForSelector_executeReturnedIMP
{
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add doSomething method
	[obj respondsToSelector:NSSelectorFromString(@"doSomething") withKey:nil usingBlock:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	REVoidIMP imp;
	imp = (REVoidIMP)[obj methodForSelector:NSSelectorFromString(@"doSomething")];
	imp(obj, NSSelectorFromString(@"doSomething"));
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForSelector_forKey
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log block
	[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
		// Do something
		receiver = receiver;
	}];
	STAssertTrue([obj hasBlockForSelector:@selector(log) withKey:@"key"], @"");
	
	// Remove log block
	[obj removeBlockForSelector:@selector(log) withKey:@"key"];
	STAssertTrue(![obj hasBlockForSelector:@selector(log) withKey:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block for log method with key
	[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[obj respondsToSelector:@selector(say) withKey:@"key" usingBlock:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = [obj performSelector:@selector(log)];
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[obj removeBlockForSelector:@selector(log) withKey:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(log)], @"");
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[obj removeBlockForSelector:@selector(say) withKey:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(say)], @"");
}

- (void)test_replaceBlock
{
	NSString *string;
	
	// Make test obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add log block
	[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
		return @"Overridden log";
	}];
	
	// Replace log block
	[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
		return @"Replaced log";
	}];
	
	// Remove block for key
	[obj removeBlockForSelector:@selector(log) withKey:@"key"];
	string = [obj log];
	STAssertEqualObjects(string, @"log", @"");
}

- (void)test_stackOfDynamicBlocks
{
	id obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	STAssertFalse([obj respondsToSelector:sel], @"");
	
	// Add block1
	[obj respondsToSelector:sel withKey:@"block1" usingBlock:^NSString*(id receiver) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withKey:@"block2" usingBlock:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withKey:@"block3" usingBlock:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel withKey:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel withKey:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel withKey:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
	log = [obj performSelector:sel];
	STAssertNil(log, @"");
}

- (void)test_performDummyBlock
{
	NSString *string = nil;
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add block1
	[obj respondsToSelector:(sel = NSSelectorFromString(@"readThis:")) withKey:@"block1" usingBlock:^(id receiver, NSString *string) {
		return string;
	}];
	string = [obj performSelector:sel withObject:@"Read"];
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel withKey:@"block1"];
	string = [obj performSelector:sel withObject:@"Read"];
	STAssertNil(string, @"");
}

- (void)test_stackOfOverrideBlocks
{
	RETestObject *obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [RETestObject testObject];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Add bock1
	[obj respondsToSelector:sel withKey:@"block1" usingBlock:^NSString*(id receiver) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withKey:@"block2" usingBlock:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withKey:@"block3" usingBlock:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel withKey:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel withKey:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel withKey:@"block2"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	id obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block with key
	[obj respondsToSelector:sel withKey:@"key" usingBlock:^NSString*(id receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj respondsToSelector:sel withKey:@"key" usingBlock:^NSString*(id receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel withKey:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	RETestObject *obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [RETestObject testObject];
	
	// Add block with key
	[obj respondsToSelector:sel withKey:@"key" usingBlock:^NSString*(id receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj respondsToSelector:sel withKey:@"key" usingBlock:^NSString*(id receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel withKey:@"key"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_supermethodOf1stDynamicBlock
{
	SEL sel;
	sel = @selector(log);
	
	// Make obj
	NSObject *obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj respondsToSelector:sel withKey:nil usingBlock:^(id receiver) {
		NSMutableString *log;
		log = [NSMutableString string];
		
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		STAssertNil((id)supermethod, @"");
		
		return @"Dynamic log";
	}];
	
	// Perform log
	[obj performSelector:@selector(log)];
}

- (void)test_supermethodOfDynamicBlock
{
	id obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block1
	[obj respondsToSelector:sel withKey:@"block1" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withKey:@"block2" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withKey:@"block3" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block3"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel withKey:@"block3"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel withKey:@"block1"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel withKey:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	RETestObject *obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [RETestObject testObject];
	
	// Add block1
	[obj respondsToSelector:sel withKey:@"block1" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withKey:@"block2" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withKey:@"block3" usingBlock:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block3"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel withKey:@"block3"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel withKey:@"block1"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel withKey:@"block2"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	obj.age = 10;
	
	// Override age method
	[obj respondsToSelector:(sel = @selector(age)) withKey:nil usingBlock:^NSUInteger(id receiver) {
		NSUInteger age = 0;
		
		// Get original age
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			age = (NSUInteger)supermethod(receiver, @selector(age));
		}
		
		// Increase age
		age++;
		
		return age;
	}];
	
	// Get age
	NSUInteger age;
	age = obj.age;
	STAssertEquals(age, (NSUInteger)11, @"");
}

- (void)test_supermethodWithArgumentReturningScalar
{
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	obj.age = 10;
	
	// Override age method
	[obj respondsToSelector:(sel = @selector(ageAfterYears:)) withKey:nil usingBlock:^NSUInteger(id receiver, NSUInteger years) {
		NSUInteger age = 0;
		
		// Get original age
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			age = (NSUInteger)supermethod(receiver, sel, years);
		}
		
		// Increase age
		age++;
		
		return age;
	}];
	
	// Get age
	NSUInteger age;
	age = [obj ageAfterYears:3];
	STAssertEquals(age, (NSUInteger)14, @"");
}

- (void)test_supermethodReturningStructure
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	obj.rect = CGRectMake(10.0f, 20.0f, 30.0f, 40.0f);
	
	// Override rect method
	[obj respondsToSelector:@selector(rect) withKey:nil usingBlock:^(id receiver) {
		// Get original rect
		CGRect rect;
		typedef CGRect (*RectIMP)(id, SEL, ...);
		RectIMP supermethod;
		if ((supermethod = (RectIMP)[receiver supermethodOfCurrentBlock])) {
			rect = supermethod(receiver, @selector(rect));
		}
		
		// Inset rect
		return CGRectInset(rect, 3.0f, 6.0f);
	}];
	
	// Get rect
	CGRect rect;
	rect = obj.rect;
	STAssertEquals(rect, CGRectMake(13.0f, 26.0f, 24.0f, 28.0f), @"");
}

- (void)test_supermethodReturningVoid
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	[obj respondsToSelector:@selector(sayHello) withKey:nil usingBlock:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(sayHello));
		}
	}];
	[obj sayHello];
}

- (void)test_removeBlockForSelector_withKey
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj respondsToSelector:@selector(log) withKey:@"key" usingBlock:^(id receiver) {
		// Do something
	}];
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Remove block
	[obj removeBlockForSelector:@selector(log) withKey:@"key"];
	STAssertTrue(![obj respondsToSelector:@selector(log)], @"");
}

- (void)test_removeCurrentBlock
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^(id receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	
	// Check
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	[obj performSelector:@selector(log)];
	STAssertTrue(![obj respondsToSelector:@selector(log)], @"");
}

- (void)test_doNotChangeClassFrequentlyWithDynamicBlockManagement
{
	// Make obj
	NSObject *obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj respondsToSelector:@selector(log) withKey:@"logBlock" usingBlock:^(id receiver) {
		return @"Dynamic log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Add say method
	[obj respondsToSelector:@selector(say) withKey:@"sayBlock" usingBlock:^(id receiver) {
		return @"Dynamic say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForSelector:@selector(log) withKey:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) withKey:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_doNotChangeClassFrequentlyWithOverrideBlockManagement
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Override log method
	[obj respondsToSelector:@selector(log) withKey:@"logBlock" usingBlock:^(id receiver) {
		return @"Overridden log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Override say method
	[obj respondsToSelector:@selector(say) withKey:@"sayBlock" usingBlock:^(id receiver) {
		return @"Overridden say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForSelector:@selector(log) withKey:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) withKey:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_setConformableToProtocol
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to protocol
	[obj setConformable:YES toProtocol:protocol withKey:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable to protocol
	[obj setConformable:NO toProtocol:protocol withKey:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__conformsToIncorporatedProtocols
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) withKey:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__canNotRemoveIncorporatedProtocol
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) withKey:@"key"];
	
	// Set not conformable to NSCoding
	[obj setConformable:NO toProtocol:@protocol(NSCoding) withKey:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__managesProtocolsBySpecifiedProtocol
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding and NSCoding then remove NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) withKey:@"key"];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) withKey:@"key"];
	[obj setConformable:NO toProtocol:@protocol(NSSecureCoding) withKey:@"key"];
	STAssertTrue(![obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj conformable to NSSecureCoding and NSCoding then remove NSCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) withKey:@"key"];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) withKey:@"key"];
	[obj setConformable:NO toProtocol:@protocol(NSCoding) withKey:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__withNilKey
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set conformable
	[obj setConformable:YES toProtocol:@protocol(NSCoding) withKey:nil];
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocolWithInvalidArguments
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Try to set obj conformable with nil-protocol
	[obj setConformable:YES toProtocol:nil withKey:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to protocol
	[obj setConformable:YES toProtocol:protocol withKey:key];
	
	// Try to set obj not-conformable with nil-protocol
	[obj setConformable:NO toProtocol:nil withKey:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Try to set obj not-conformable with nil-key
	[obj setConformable:NO toProtocol:protocol withKey:nil];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable
	[obj setConformable:NO toProtocol:protocol withKey:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocolWithKeyMethodStacksKeys
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to the protocol with key
	[obj setConformable:YES toProtocol:protocol withKey:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to the protocol with other key
	[obj setConformable:YES toProtocol:protocol withKey:@"OtherKey"];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Try to set obj not-conformable to the protocol
	[obj setConformable:NO toProtocol:protocol withKey:@"OtherKey"];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable to the protocol
	[obj setConformable:NO toProtocol:protocol withKey:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocolDoesNotStackSameKeyForAProtocol
{
	Protocol *protocol;
	NSString *key;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to the protocol
	[obj setConformable:YES toProtocol:protocol withKey:key];
	[obj setConformable:YES toProtocol:protocol withKey:key];
	[obj setConformable:NO toProtocol:protocol withKey:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocolAllowsSameKeyForOtherProtocol
{
	// Decide key
	NSString *key;
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSCopying and NSCoding
	[obj setConformable:YES toProtocol:@protocol(NSCopying) withKey:key];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) withKey:key];
	STAssertTrue([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCopying
	[obj setConformable:NO toProtocol:@protocol(NSCopying) withKey:key];
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCoding
	[obj setConformable:NO toProtocol:@protocol(NSCoding) withKey:key];
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_keyOfProtocolIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [[[NSObject alloc] init] autorelease];
		[key respondsToSelector:@selector(dealloc) withKey:nil usingBlock:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		
		// Set obj conformable to NSCopying and NSCoding
		[obj setConformable:YES toProtocol:@protocol(NSCopying) withKey:key];
		[obj setConformable:YES toProtocol:@protocol(NSCoding) withKey:key];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_respondsToSelector_callWithNil
{
	// Make obj
	id obj;
	BOOL responds;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertNoThrow(responds = [obj respondsToSelector:nil], @"");
	STAssertTrue(!responds, @"");
}

- (void)test_conformsToProtocol_callWithNil
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertNoThrow([obj conformsToProtocol:nil], @"");
}

@end
