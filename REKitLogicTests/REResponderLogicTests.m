/*
 REResponderLogicTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderLogicTests.h"
#import "RETestObject.h"
#import <objc/message.h>

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
	[obj setBlockForSelector:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block", @"");
	
	// Don't affect to class
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertFalse([[obj class] respondsToSelector:sel], @"");
}

- (void)test_overrideHardcodedMethod
{
	SEL sel = @selector(log);
	
	// You can override hardcoded method
	NSString *log;
	RETestObject *obj;
	obj = [RETestObject testObject];
	[obj setBlockForSelector:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	log = [obj log];
	STAssertEqualObjects(log, @"Overridden log", @"");
	
	// Don't affect to class
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertFalse([[obj class] respondsToSelector:sel], @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherInstances
{
	// Make obj and otherObj
	id obj;
	id otherObj;
	obj = [[[NSObject alloc] init] autorelease];
	otherObj = [[[NSObject alloc] init] autorelease];
	
	// Add dynamic block to obj
	[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
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
	[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(dealloc) key:obj block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Do something…
			receiver = receiver;
		}];
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			return @"Overridden log";
		}];
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[key setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:key block:^(id receiver) {
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
		[key setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:key block:^(id receiver) {
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
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do something…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
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
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
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
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
//			// Do nothing…
//		}];
//		
//		// Remove top log block
//		[obj removeBlockForSelector:@selector(log) key:@"key"];
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
		[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Do nothing…
			id ctx;
			ctx = context;
		}];
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Add log method
		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Remove top log block
		[obj removeBlockForSelector:@selector(log) key:@"key"];
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
		[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Perform block
		[obj performSelector:@selector(log)];
		
		// Remove block
		[obj removeBlockForSelector:@selector(log) key:@"key"];
		
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
		[obj setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
			[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
				// Raise deallocated flag
				isContextDeallocated = YES;
				
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfCurrentBlock])) {
					supermethod(receiver, dealloc);
				}
			}];
			
			// Add log block
			[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
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
			[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
				
				// super
				IMP supermethod;
				if ((supermethod = [receiver supermethodOfCurrentBlock])) {
					supermethod(receiver, @selector(dealloc));
				}
			}];
			
			// Associate context
			[obj setAssociatedValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
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
	[obj setBlockForSelector:@selector(logWithSuffix:) key:nil block:^NSString*(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call logWithSuffix: method
	log = [obj performSelector:@selector(logWithSuffix:) withObject:@"suffix"];
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	id obj;
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block
	[obj setBlockForSelector:sel key:@"block" block:^CGRect(id receiver, CGPoint origin, CGSize size) {
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
	[obj setBlockForSelector:@selector(doSomething) key:nil block:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	REVoidIMP imp;
	imp = (REVoidIMP)[obj methodForSelector:@selector(doSomething)];
	imp(obj, @selector(doSomething));
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForSelector_forKey
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log block
	[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
		// Do something
		receiver = receiver;
	}];
	STAssertTrue([obj hasBlockForSelector:@selector(log) key:@"key"], @"");
	
	// Remove log block
	[obj removeBlockForSelector:@selector(log) key:@"key"];
	STAssertTrue(![obj hasBlockForSelector:@selector(log) key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block for log method with key
	[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[obj setBlockForSelector:@selector(say) key:@"key" block:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = [obj performSelector:@selector(log)];
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[obj removeBlockForSelector:@selector(log) key:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(log)], @"");
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[obj removeBlockForSelector:@selector(say) key:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(say)], @"");
}

- (void)test_replaceBlock
{
	NSString *string;
	
	// Make test obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add log block
	[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
		return @"Overridden log";
	}];
	
	// Replace log block
	[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
		return @"Replaced log";
	}];
	
	// Remove block for key
	[obj removeBlockForSelector:@selector(log) key:@"key"];
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
	[obj setBlockForSelector:sel key:@"block1" block:^NSString*(id receiver) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj setBlockForSelector:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj setBlockForSelector:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel key:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel key:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel key:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
	STAssertNotNil((id)[obj methodForSelector:sel], @"");
	STAssertEquals([obj methodForSelector:sel], [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_performDummyBlock
{
	NSString *string = nil;
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Add block1
	[obj setBlockForSelector:(sel = @selector(readThis:)) key:@"block1" block:^(id receiver, NSString *string) {
		return string;
	}];
	string = [obj performSelector:sel withObject:@"Read"];
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel key:@"block1"];
	STAssertFalse([obj respondsToSelector:sel], @"");
	STAssertNotNil((id)[obj methodForSelector:sel], @"");
	STAssertEquals([obj methodForSelector:sel], [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
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
	[obj setBlockForSelector:sel key:@"block1" block:^NSString*(id receiver) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj setBlockForSelector:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj setBlockForSelector:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForSelector:sel key:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel key:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel key:@"block2"];
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
	[obj setBlockForSelector:sel key:@"key" block:^NSString*(id receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj setBlockForSelector:sel key:@"key" block:^NSString*(id receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel key:@"key"];
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
	[obj setBlockForSelector:sel key:@"key" block:^NSString*(id receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj setBlockForSelector:sel key:@"key" block:^NSString*(id receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel key:@"key"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	for (id anObj in @[obj, obj]) {
		[anObj setBlockForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel key:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_overrideBySameBlock
{
	SEL sel = @selector(log);
	
	id obj;
	obj = [[[RETestObject alloc] init] autorelease];
	for (id anObj in @[obj, obj]) {
		[anObj setBlockForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel key:@"key"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log", @"");
}

- (void)test_canShareBlock
{
	SEL sel = @selector(log);
	
	id obj1, obj2;
	RETestObject *obj3;
	obj1 = [[[NSObject alloc] init] autorelease];
	obj2 = [[[NSObject alloc] init] autorelease];
	obj3 = [[[RETestObject alloc] init] autorelease];
	
	// Share block
	for (id obj in @[obj1, obj2, obj3]) {
		[obj setBlockForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend(obj2, sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"block", @"");
	
	// Remove block from obj2
	[obj2 removeBlockForSelector:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertFalse([obj2 respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"block", @"");
	
	// Remove block from obj3
	[obj3 removeBlockForSelector:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertFalse([obj2 respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"log", @"");
	
	// Remove block from obj1
	[obj1 removeBlockForSelector:sel key:@"key"];
	STAssertFalse([obj1 respondsToSelector:sel], @"");
	STAssertFalse([obj2 respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"log", @"");
}

- (void)test_canPassAlreadyExistBlock
{
	SEL sel = @selector(log);
	
	// Make block
	NSString *(^block)(id receiver);
	block = ^(id receiver) {
		return @"block";
	};
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block
	[obj setBlockForSelector:sel key:@"key" block:block];
	
	// Call
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForSelector:sel key:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_supermethodOf1stDynamicBlock
{
	SEL sel;
	sel = @selector(log);
	
	// Make obj
	NSObject *obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj setBlockForSelector:sel key:nil block:^(id receiver) {
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
	[obj setBlockForSelector:sel key:@"block1" block:^NSString*(id receiver) {
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
	[obj setBlockForSelector:sel key:@"block2" block:^NSString*(id receiver) {
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
	[obj setBlockForSelector:sel key:@"block3" block:^NSString*(id receiver) {
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
	[obj removeBlockForSelector:sel key:@"block3"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel key:@"block1"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel key:@"block2"];
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
	[obj setBlockForSelector:sel key:@"block1" block:^NSString*(id receiver) {
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
	[obj setBlockForSelector:sel key:@"block2" block:^NSString*(id receiver) {
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
	[obj setBlockForSelector:sel key:@"block3" block:^NSString*(id receiver) {
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
	[obj removeBlockForSelector:sel key:@"block3"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel key:@"block1"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel key:@"block2"];
	
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
	[obj setBlockForSelector:(sel = @selector(age)) key:nil block:^NSUInteger(id receiver) {
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
	[obj setBlockForSelector:(sel = @selector(ageAfterYears:)) key:nil block:^NSUInteger(id receiver, NSUInteger years) {
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
	[obj setBlockForSelector:@selector(rect) key:nil block:^(id receiver) {
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
	[obj setBlockForSelector:@selector(sayHello) key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(sayHello));
		}
	}];
	[obj sayHello];
}

- (void)test_getSupermethodFromOutsideOfBlock
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Get supermethod
	IMP supermethod;
	supermethod = [obj supermethodOfCurrentBlock];
	STAssertNil((id)supermethod, @"");
}

- (void)test_removeBlockForSelector_key
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
		// Do something
	}];
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Remove block
	[obj removeBlockForSelector:@selector(log) key:@"key"];
	STAssertTrue(![obj respondsToSelector:@selector(log)], @"");
	
	// Check imp
	IMP imp;
	imp = [obj methodForSelector:@selector(log)];
	STAssertEquals(imp, [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_removeCurrentBlock
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	
	// Check
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	[obj performSelector:@selector(log)];
	STAssertTrue(![obj respondsToSelector:@selector(log)], @"");
}

- (void)test_canCallRemoveCurrentBlockFromOutsideOfBlock
{
	SEL sel = @selector(doSomething);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Add doSomething method
	[obj setBlockForSelector:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Check doSomething method
	STAssertTrue([obj respondsToSelector:sel], @"");
}

- (void)test_doNotChangeClassFrequentlyWithDynamicBlockManagement
{
	// Make obj
	NSObject *obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add log method
	[obj setBlockForSelector:@selector(log) key:@"logBlock" block:^(id receiver) {
		return @"Dynamic log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Add say method
	[obj setBlockForSelector:@selector(say) key:@"sayBlock" block:^(id receiver) {
		return @"Dynamic say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForSelector:@selector(log) key:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) key:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_doNotChangeClassFrequentlyWithOverrideBlockManagement
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Override log method
	[obj setBlockForSelector:@selector(log) key:@"logBlock" block:^(id receiver) {
		return @"Overridden log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Override say method
	[obj setBlockForSelector:@selector(say) key:@"sayBlock" block:^(id receiver) {
		return @"Overridden say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForSelector:@selector(log) key:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) key:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_replacedClassIsKindOfOriginalClass
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject testObject];
	
	// Override log method
	[obj setBlockForSelector:@selector(log) key:@"logBlock" block:^(id receiver) {
		return @"Overridden log";
	}];
	
	// Check class
	STAssertTrue([obj isKindOfClass:[RETestObject class]], @"");
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
	[obj setConformable:YES toProtocol:protocol key:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable to protocol
	[obj setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__conformsToIncorporatedProtocols
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__canNotRemoveIncorporatedProtocol
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	
	// Set not conformable to NSCoding
	[obj setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__managesProtocolsBySpecifiedProtocol
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSSecureCoding and NSCoding then remove NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
	[obj setConformable:NO toProtocol:@protocol(NSSecureCoding) key:@"key"];
	STAssertTrue(![obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj conformable to NSSecureCoding and NSCoding then remove NSCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
	[obj setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__withNilKey
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set conformable
	[obj setConformable:YES toProtocol:@protocol(NSCoding) key:nil];
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__withInvalidArguments
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
	[obj setConformable:YES toProtocol:nil key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to protocol
	[obj setConformable:YES toProtocol:protocol key:key];
	
	// Try to set obj not-conformable with nil-protocol
	[obj setConformable:NO toProtocol:nil key:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Try to set obj not-conformable with nil-key
	[obj setConformable:NO toProtocol:protocol key:nil];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable
	[obj setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__stacksKeys
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
	[obj setConformable:YES toProtocol:protocol key:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to the protocol with other key
	[obj setConformable:YES toProtocol:protocol key:@"OtherKey"];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Try to set obj not-conformable to the protocol
	[obj setConformable:NO toProtocol:protocol key:@"OtherKey"];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable to the protocol
	[obj setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__doesNotStackSameKeyForAProtocol
{
	Protocol *protocol;
	NSString *key;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to the protocol
	[obj setConformable:YES toProtocol:protocol key:key];
	[obj setConformable:YES toProtocol:protocol key:key];
	[obj setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__allowsSameKeyForOtherProtocol
{
	// Decide key
	NSString *key;
	key = NSStringFromSelector(_cmd);
	
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	
	// Set obj conformable to NSCopying and NSCoding
	[obj setConformable:YES toProtocol:@protocol(NSCopying) key:key];
	[obj setConformable:YES toProtocol:@protocol(NSCoding) key:key];
	STAssertTrue([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCopying
	[obj setConformable:NO toProtocol:@protocol(NSCopying) key:key];
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCoding
	[obj setConformable:NO toProtocol:@protocol(NSCoding) key:key];
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__keyIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [[[NSObject alloc] init] autorelease];
		[key setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
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
		[obj setConformable:YES toProtocol:@protocol(NSCopying) key:key];
		[obj setConformable:YES toProtocol:@protocol(NSCoding) key:key];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_respondsToSelector__callWithNil
{
	// Make obj
	id obj;
	BOOL responds;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertNoThrow(responds = [obj respondsToSelector:nil], @"");
	STAssertTrue(!responds, @"");
}

- (void)test_conformsToProtocol__callWithNil
{
	// Make obj
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertNoThrow([obj conformsToProtocol:nil], @"");
}

- (void)test_respondsToUnimplementedMethod_class
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Check NSObject
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForSelector:sel key:@"key" block:^(id receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	}];
	
	// Responds to selector?
	STAssertTrue([[NSObject class] respondsToSelector:sel], @"");
	
	// Call the sel
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block", @"");
	
	// Don't affect to instances
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	STAssertFalse([obj respondsToSelector:sel], @"");
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

//- (void)test_overrideHardcodedMethod_class
//{
//	SEL selector = @selector(testObject);
//	// Override testObject method
//	[RETestObject setBlockForSelector:selector key:nil block:^(id receiver) {
//		
//	RETestObject *obj;
//	obj = [RETestObject testObject];
//	[obj setBlockForSelector:@selector(log) key:nil block:^NSString*(id receiver) {
//		return @"Overridden log";
//	}];
//	log = [obj log];
//	STAssertEqualObjects(log, @"Overridden log", @"");
//}

- (void)test_removeBlockForSelector_key_class
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForSelector:sel key:@"key" block:^(id receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	}];
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

@end
