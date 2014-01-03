/*
 REResponderClassMethodOfObjectTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderClassMethodOfObjectTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderClassMethodOfObjectTests

- (void)_resetClasses
{
	// Reset all classes
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		// Remove blocks
		NSDictionary *blocks;
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_classMethodBlocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForClassMethod:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_instanceMethodBlocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForInstanceMethod:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		
		// Remove protocols
		NSDictionary *protocols;
		protocols = [aClass associatedValueForKey:@"REResponder_protocols"];
		[protocols enumerateKeysAndObjectsUsingBlock:^(NSString *protocolName, NSDictionary *protocolInfo, BOOL *stop) {
			[protocolInfo[@"keys"] enumerateObjectsUsingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
				[aClass setConformable:NO toProtocol:NSProtocolFromString(protocolName) key:aKey];
			}];
		}];
	}
}

- (void)setUp
{
	// super
	[super setUp];
	
	[self _resetClasses];
}

- (void)tearDown
{
	[self _resetClasses];
	
	// super
	[super tearDown];
}

- (void)test_respondsToUnimplementedMethod
{
	SEL sel = _cmd;
	NSString *log;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	
	// Responds?
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Check log
	log = [[obj class] performSelector:sel];
	STAssertEqualObjects(log, @"block", @"");
}

- (void)test_overrideHardcodedMethod
{
	SEL sel = @selector(classLog);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	
	// Responds?
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	STAssertEqualObjects([[obj class] classLog], @"Overridden log", @"");
}

- (void)test_dynamicBlockDoesNotAffectInstanceMethod
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	
	// Don't affect instance
	STAssertTrue(![obj respondsToSelector:sel], @"");
	STAssertTrue(![[obj class] instancesRespondToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectInstanceMethod
{
	SEL sel = @selector(classLog);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	
	// Don't affect instance
	STAssertTrue(![obj respondsToSelector:sel], @"");
	STAssertTrue(![[obj class] instancesRespondToSelector:sel], @"");
	
	// Call original
	STAssertEqualObjects([RETestObject classLog], @"classLog", @"");
}

- (void)test_dynamicBlockDoesNotAffectOriginalClass
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	
	// Don't affect class
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectOriginalClass
{
	SEL sel = @selector(classLog);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	
	// Don't affect class
	STAssertTrue([RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	
	// Call original
	STAssertEqualObjects([RETestObject classLog], @"classLog", @"");
}

- (void)test_dynamicBlockDoesNotAffectSubclasses
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	
	// Don't affect subclass
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectSubclasses
{
	SEL sel = @selector(classLog);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	
	// Don't affect subclass
	STAssertTrue([RESubTestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
	
	// Call original of subclass
	STAssertEqualObjects([RESubTestObject classLog], @"classLog", @"");
}

- (void)test_dynamicBlockDoesNotAffectSuperclass
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"block";
	}];
	
	// Don't affect superclass
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectSuperclass
{
	SEL sel = @selector(classLog);
	
	// Make obj
	RESubTestObject *obj;
	obj = [RESubTestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^NSString*(id receiver) {
		return @"Overridden log";
	}];
	
	// Don't affect superclass
	STAssertTrue([RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	
	// Call original of subclass
	STAssertEqualObjects([RETestObject classLog], @"classLog", @"");
}

- (void)test_dynamicBlockAffectSubclassesConnectedToForwardingMethod
{
	// Test using KVO >>>
}

- (void)test_dynamicBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(subRect);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(id receiver) {
		return CGRectMake(4.0, 3.0, 2.0, 1.0);
	}];
	
	// Call subclass's imp
	STAssertEquals([RESubTestObject subRect], CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_overrideBlockDoesNotAffectOverrideImplementationOfSubclass
{
	SEL sel = @selector(theRect);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^(id receiver) {
		return CGRectMake(4.0, 3.0, 2.0, 1.0);
	}];
	
	// Call subclass's imp
	STAssertEquals([RESubTestObject theRect], CGRectMake(100.0, 200.0, 300.0, 400.0), @"");
}

- (void)test_overridingLastBlockUpdatesSubclasses
{
	// Test using KVO >>>
}

- (void)test_overrideLastBlockWithSameBlock
{
	// Test using KVO >>>
}

- (void)test_addDynamicBlockToSubclasses
{
	// Test using KVO >>>
}

- (void)test_receiverIsClass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		STAssertEquals(receiver, [obj class], @"");
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_receiverCanBeSubclass
{
	// Test using KVO >>>
}

- (void)test_canPsssReceiverAsKey
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	
	// Add block
	[obj setBlockForClassMethod:@selector(otherMethod) key:[obj class] block:^(Class receiver) {
		return @"block";
	}];
	
	// Call
	STAssertEqualObjects(objc_msgSend([obj class], @selector(otherMethod)), @"block", @"");
}

- (void)test_usingObjectInDynamicBlockCausesRetainCycle
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		
		// Add block
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		obj = [RETestObject object];
		
		// Override log method
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Use obj
			id object;
			object = obj;
		}];
		
		// Override dealloc method
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(dealloc) key:obj block:^(Class receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Do something
			receiver = receiver;
		}];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		obj = [RETestObject object];
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			return @"Overridden log";
		}];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		key = [NSObject object];
		[key setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(log) key:key block:^(Class receiver) {
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
		key = [NSObject object];
		[key setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		RETestObject *obj;
		obj = [RETestObject object];
		
		// Override log method using key
		[obj setBlockForClassMethod:@selector(log) key:key block:^(Class receiver) {
			return RESupermethod(nil, receiver, @selector(log));
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
//		obj = [NSObject object];
//		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
//			// Do something…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForInstanceMethod:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForInstanceMethod:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForInstanceMethod:@selector(copy) key:nil block:^(id receiver) {
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

//- (void)test_superblockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [NSObject object];
//		
//		// Add log method
//		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForInstanceMethod:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForInstanceMethod:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForInstanceMethod:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
//			// supermethod
//			RESupermethod(nil, receiver, @selector(log));
//		}];
//		
//		// Call
//		objc_msgSend([obj class], @selector(log));
//		
//		// Check retain count of block
//		STAssertEquals(CFGetRetainCount(block), (signed long)1, @"");
//	}
//	
//	// Check
//	STAssertTrue(released, @"");
//}

//- (void)test_reusedSuperblockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [NSObject object];
//		
//		// Add log method
//		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
//			// Do nothing…
//		}];
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForInstanceMethod:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		}];
//		[block setBlockForInstanceMethod:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		[block setBlockForInstanceMethod:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		}];
//		
//		// Override log method
//		[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
//			// Do nothing…
//		}];
//		
//		// Remove top log block
//		[obj removeBlockForClassMethod:@selector(log) key:@"key"];
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
		context = [NSObject object];
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
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
		context = [NSObject object];
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Do nothing…
			id ctx;
			ctx = context;
		}];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Call
		objc_msgSend([obj class], @selector(log));
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
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Add log method
		[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Remove top log block
		[obj removeBlockForClassMethod:@selector(log) key:@"key"];
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
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
			// Use context
			id ctx;
			ctx = context;
		}];
		
		// Perform block
		objc_msgSend([obj class], @selector(log));
		
		// Remove block
		[obj removeBlockForClassMethod:@selector(log) key:@"key"];
		
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
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		@autoreleasepool {
			// Make context
			__autoreleasing id context;
			context = [NSObject object];
			[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
				// Raise deallocated flag
				isContextDeallocated = YES;
				
				// supermethod
				RESupermethod(nil, receiver, @selector(dealloc));
			}];
			
			// Add log block
			[obj setBlockForClassMethod:@selector(log) key:nil block:^(Class receiver) {
				id ctx;
				ctx = context;
				string = @"called";
			}];
		}
		
		// Deallocated?
		STAssertTrue(!isContextDeallocated, @"");
		
		// Call
		objc_msgSend([obj class], @selector(log));
	}
	
	// Check
	STAssertEqualObjects(string, @"called", @"");
	STAssertTrue(isContextDeallocated, @"");
	STAssertTrue(isObjDeallocated, @"");
}

- (void)test_associatedContextIsNotDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		
		@autoreleasepool {
			// Make context
			RETestObject *context;
			context = [RETestObject object];
			[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
				
				// supermethod
				RESupermethod(nil, receiver, @selector(dealloc));
			}];
			
			// Add log block
			[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
				id ctx;
				ctx = [receiver associatedValueForKey:@"context"];
				STAssertNotNil(ctx, @"");
			}];
			
			// Associate context
			[[obj class] setAssociatedValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Deallocated?
			STAssertTrue(!deallocated, @"");
			STAssertNotNil([[obj class] associatedValueForKey:@"context"], @"");
			
			// Call
			objc_msgSend([obj class], @selector(log));
		}
		
		// Call
		objc_msgSend([obj class], @selector(log));
	}
	
	// Check
	STAssertTrue(!deallocated, @"");
}

- (void)test_allowArguments
{
	id obj;
	NSString *log;
	
	// Make obj
	obj = [NSObject object];
	
	// Add block with arguments
	[obj setBlockForClassMethod:@selector(logWithSuffix:) key:nil block:^NSString*(Class receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call logWithSuffix: method
	log = objc_msgSend([obj class], @selector(logWithSuffix:), @"suffix");
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	id obj;
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Make obj
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:@"block" block:^CGRect(Class receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Check rect
	rect = (REIMP(CGRect)objc_msgSend_stret)([obj class], sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add doSomething method
	[obj setBlockForClassMethod:@selector(doSomething) key:nil block:^(Class receiver) {
		called = YES;
	}];
	
	// Call imp
	IMP imp;
	imp = [[obj class] methodForSelector:@selector(doSomething)];
	(REIMP(void)imp)([obj class], @selector(doSomething));
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForClassMethod_key
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add log block
	[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
		// Do something
		receiver = receiver;
	}];
	STAssertTrue([obj hasBlockForClassMethod:@selector(log) key:@"key"], @"");
	STAssertTrue(![obj hasBlockForInstanceMethod:@selector(log) key:@"key"], @"");
	STAssertTrue(![[obj class] hasBlockForClassMethod:@selector(log) key:@"key"], @"");
	STAssertTrue(![[obj class] hasBlockForInstanceMethod:@selector(log) key:@"key"], @"");
	
	// Remove log block
	[obj removeBlockForClassMethod:@selector(log) key:@"key"];
	STAssertTrue(![obj hasBlockForClassMethod:@selector(log) key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:@selector(log) key:@"key" block:^(Class receiver) {
		return @"log";
	}];
	
	// Add block
	[obj setBlockForClassMethod:@selector(say) key:@"key" block:^(Class receiver) {
		return @"say";
	}];
	
	// Call log
	string = objc_msgSend([obj class], @selector(log));
	STAssertEqualObjects(string, @"log", @"");
	
	// Call say
	string = objc_msgSend([obj class], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[obj removeBlockForClassMethod:@selector(log) key:@"key"];
	STAssertTrue(![[obj class] respondsToSelector:@selector(log)], @"");
	string = objc_msgSend([obj class], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[obj removeBlockForClassMethod:@selector(say) key:@"key"];
	STAssertTrue(![[obj class] respondsToSelector:@selector(say)], @"");
}

- (void)test_stackOfDynamicBlocks
{
	SEL sel = _cmd;
	NSString *log;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block1
	[obj setBlockForClassMethod:sel key:@"block1" block:^(Class receiver) {
		return @"block1";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj setBlockForClassMethod:sel key:@"block2" block:^(Class receiver) {
		return @"block2";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj setBlockForClassMethod:sel key:@"block3" block:^(Class receiver) {
		return @"block3";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForClassMethod:sel key:@"block3"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForClassMethod:sel key:@"block1"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForClassMethod:sel key:@"block2"];
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
	STAssertEquals([[obj class] methodForSelector:sel], [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_connectToForwardingMethod
{
	NSString *string = nil;
	SEL sel = @selector(readThis:);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Add block1
	[obj setBlockForClassMethod:(sel = @selector(readThis:)) key:@"block1" block:^(Class receiver, NSString *string) {
		return string;
	}];
	string = objc_msgSend([obj class], sel, @"Read");
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[obj removeBlockForClassMethod:sel key:@"block1"];
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
	STAssertEquals([[obj class] methodForSelector:sel], [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_stackOfOverrideBlocks
{
	RETestObject *obj;
	SEL sel = @selector(classLog);
	NSString *log;
	
	// Make obj
	obj = [RETestObject object];
	
	// Add bock1
	[obj setBlockForClassMethod:sel key:@"block1" block:^(Class receiver) {
		return @"block1";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj setBlockForClassMethod:sel key:@"block2" block:^(Class receiver) {
		return @"block2";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj setBlockForClassMethod:sel key:@"block3" block:^(Class receiver) {
		return @"block3";
	}];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForClassMethod:sel key:@"block3"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForClassMethod:sel key:@"block1"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForClassMethod:sel key:@"block2"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"classLog", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	id obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [NSObject object];
	
	// Add block with key
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = objc_msgSend([obj class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	RETestObject *obj;
	SEL sel = @selector(classLog);
	NSString *log;
	
	// Make obj
	obj = [RETestObject object];
	
	// Add block with key
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block1";
	}];
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block2";
	}];
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	
	// Call log method
	log = [[obj class] classLog];
	STAssertEqualObjects(log, @"classLog", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = _cmd;
	
	id obj;
	obj = [NSObject object];
	for (id anObj in @[obj, obj]) {
		[anObj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj class], sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
}

- (void)test_overrideBySameBlock
{
	SEL sel = @selector(classLog);
	
	id obj;
	obj = [RETestObject object];
	for (id anObj in @[obj, obj]) {
		[anObj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Call
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj class], sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj class], sel), @"classLog", @"");
}

- (void)test_canShareBlock
{
	SEL sel = @selector(classLog);
	
	id obj1, obj2;
	RETestObject *obj3;
	obj1 = [NSObject object];
	obj2 = [NSObject object];
	obj3 = [RETestObject object];
	
	// Share block
	for (id obj in @[obj1, obj2, obj3]) {
		[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend([obj1 class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([obj2 class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([obj3 class], sel), @"block", @"");
	
	// Remove block from obj2
	[obj2 removeBlockForClassMethod:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend([obj1 class], sel), @"block", @"");
	STAssertFalse([[obj2 class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj3 class], sel), @"block", @"");
	
	// Remove block from obj3
	[obj3 removeBlockForClassMethod:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend([obj1 class], sel), @"block", @"");
	STAssertFalse([[obj2 class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj3 class], sel), @"classLog", @"");
	
	// Remove block from obj1
	[obj1 removeBlockForClassMethod:sel key:@"key"];
	STAssertFalse([[obj1 class] respondsToSelector:sel], @"");
	STAssertFalse([[obj2 class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj3 class], sel), @"classLog", @"");
}

- (void)test_canPassAlreadyExistBlock
{
	SEL sel = @selector(log);
	
	// Make block
	NSString *(^block)(Class receiver);
	block = ^(Class receiver) {
		return @"block";
	};
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:@"key" block:block];
	
	// Call
	STAssertTrue([[obj class] respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([obj class], sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	STAssertFalse([[obj class] respondsToSelector:sel], @"");
}

- (void)test_supermethodPointsToNil
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Make obj
	NSObject *obj;
	obj = [NSObject object];
	
	// Add log method
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToOriginalMethod
{
	SEL sel = @selector(classLog);
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	IMP originalMethod;
	originalMethod = [[obj class] methodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		// Get supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		
		// Check supermethod
		STAssertEquals(supermethod, originalMethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToInstancesBlock
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add instances block
	IMP imp;
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
	}];
	imp = [obj methodForSelector:sel];
	STAssertTrue([[obj class] methodForSelector:sel] != imp, @"");
	
	// Add class block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// Check supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToInstancesBlockOfOriginalClass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Makd obj
	id obj;
	obj = [NSObject object];
	
	// Add instances block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
	}];
	
	// Add class block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToObjectBlock
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add object block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
	}];
	
	// Add class block
	[obj setBlockForClassMethod:sel key:nil block:^(id receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlockOfOriginalClass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	__block IMP imp = NULL;
	
	// Make obj
	id obj;
	obj = [NSObject class];
	
	// Add class block
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	imp = [NSObject methodForSelector:sel];
	
	// Add class block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertEquals(supermethod, imp, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlockOfOriginalClass__reverse
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	__block IMP imp = NULL;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add class block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertEquals(supermethod, imp, @"");
		
		called = YES;
	}];
	
	// Add class block
	[RETestObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	imp = [RETestObject methodForSelector:sel];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = YES;
	__block IMP imp;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	imp = [NSObject methodForSelector:sel];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertEquals(supermethod, imp, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlockOfSuperclass__reverse
{
	SEL sel = _cmd;
	__block BOOL called = YES;
	__block IMP imp;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertEquals(supermethod, imp, @"");
		
		called = YES;
	}];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	imp = [NSObject methodForSelector:sel];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlock
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Makd obj
	id obj;
	obj = [NSObject object];
	
	// Add block1
	IMP imp;
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	imp = [object_getClass(obj) methodForSelector:sel];
	
	// Add block2
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		STAssertEquals(supermethod, imp, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend(object_getClass(obj), sel);
	STAssertTrue(called, @"");
}

- (void)test_superMethodOfSubclassPointsToClassBlock
{
	// Test using KVO >>>
}

- (void)test_supermethodOfDynamicBlock
{
	SEL sel = _cmd;
	NSString *log;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block1
	[obj setBlockForClassMethod:sel key:@"block1" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block1"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[obj setBlockForClassMethod:sel key:@"block2" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block2"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[obj setBlockForClassMethod:sel key:@"block3" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block3"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForClassMethod:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForClassMethod:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockForClassMethod:sel key:@"block2"];
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	SEL sel = @selector(classLog);
	NSString *log;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block1
	[obj setBlockForClassMethod:sel key:@"block1" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block1"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog-block1", @"");
	
	// Add block2
	[obj setBlockForClassMethod:sel key:@"block2" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block2"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog-block1-block2", @"");
	
	// Add block3
	[obj setBlockForClassMethod:sel key:@"block3" block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block3"];
	}];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForClassMethod:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForClassMethod:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog-block2", @"");
	
	// Remove block2
	[obj removeBlockForClassMethod:sel key:@"block2"];
	
	// Call
	log = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(log, @"classLog", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel = @selector(version);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Get originalValue
	NSInteger originalValue;
	originalValue = [RETestObject version];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return RESupermethod(0, receiver, sel) + 1;
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend(object_getClass(obj), sel);
	STAssertEquals(value, originalValue + 1, @"");
}

- (void)test_supermethodWithArgumentReturningScalar
{
	SEL sel = @selector(integerWithInteger:);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSInteger integer) {
		return RESupermethod(0, receiver, sel, integer) + 1;
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend(object_getClass(obj), sel, 10);
	STAssertEquals(value, 11, @"");
}

- (void)test_supermethodReturningStructure
{
	SEL sel = @selector(rect);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver, sel);
		
		// Modify rect
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Get rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)(object_getClass(obj), sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_supermethodReturningVoid
{
	SEL sel = @selector(sayHello);
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))) {
			supermethod(receiver, sel);
			called = YES;
		}
	}];
	
	// Call
	objc_msgSend(object_getClass(obj), sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethod__obtainFromOutsideOfBlock
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Get supermethod
	IMP supermethod;
	supermethod = (IMP)objc_msgSend(obj, @selector(supermethodOfCurrentBlock));
	STAssertNil((id)supermethod, @"");
	supermethod = (IMP)objc_msgSend(object_getClass(obj), @selector(supermethodOfCurrentBlock));
	STAssertNil((id)supermethod, @"");
}

- (void)test_removeBlockForClassMethod_key
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add log method
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		// Do something
	}];
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	STAssertTrue(![object_getClass(obj) respondsToSelector:sel], @"");
	
	// Check imp
	IMP imp;
	imp = class_getMethodImplementation(object_getClass(obj), sel);
	STAssertEquals(imp, [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_removeCurrentBlock
{
	SEL sel = _cmd;
	id obj;
	
	// Make obj
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	
	// Check
	objc_msgSend(object_getClass(obj), sel);
	STAssertTrue(![object_getClass(obj) respondsToSelector:sel], @"");
}

- (void)test_removeCurrentBlock__obj
{
	SEL sel = _cmd;
	__block BOOL deallocated = NO;
	id obj;
	
	@autoreleasepool {
		// Make obj
		obj = [NSObject object];
		[obj setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			deallocated = YES;
			RESupermethod(nil, receiver, sel);
		}];
		
		// Add log method
		[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
			// Remove currentBlock
			[obj removeCurrentBlock];
		}];
		
		// Check
		STAssertTrue([object_getClass(obj) respondsToSelector:sel], @"");
		objc_msgSend(object_getClass(obj), sel);
		STAssertTrue(![object_getClass(obj) respondsToSelector:sel], @"");
	}
	
	STAssertTrue(deallocated, @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block1
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		[receiver removeCurrentBlock];
		return @"block1-";
	}];
	
	// Add block2
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"block2"];
	}];
	
	// Call
	string = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend(object_getClass(obj), sel);
	STAssertEqualObjects(string, @"block2", @"");
}

- (void)test_canCallRemoveCurrentBlockFromOutsideOfBlock
{
	SEL sel = @selector(doSomething);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Add doSomething method
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
	}];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Check doSomething method
	STAssertTrue([object_getClass(obj) respondsToSelector:sel], @"");
}

- (void)test_doNotChangeClassFrequentlyWithDynamicBlockManagement
{
	// Make obj
	NSObject *obj;
	obj = [RETestObject object];
	
	// Add log method
	[obj setBlockForClassMethod:@selector(log) key:@"logBlock" block:^(Class receiver) {
		return @"Dynamic log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Add say method
	[obj setBlockForClassMethod:@selector(say) key:@"sayBlock" block:^(Class receiver) {
		return @"Dynamic say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForInstanceMethod:@selector(log) key:@"logBlock"];
	[obj removeBlockForInstanceMethod:@selector(say) key:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_doNotChangeClassFrequentlyWithOverrideBlockManagement
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override
	[obj setBlockForClassMethod:@selector(classLog) key:@"logBlock" block:^(Class receiver) {
		return @"Overridden log";
	}];
	STAssertTrue([obj class] != [RETestObject class], @"");
	
	// Record new class
	Class newClass;
	newClass = [obj class];
	
	// Override
	[obj setBlockForClassMethod:@selector(sayHello) key:@"sayBlock" block:^(Class receiver) {
		return @"Overridden say";
	}];
	STAssertEquals([obj class], newClass, @"");
	
	// Remove blocks
	[obj removeBlockForInstanceMethod:@selector(classLog) key:@"logBlock"];
	[obj removeBlockForInstanceMethod:@selector(sayHello) key:@"sayBlock"];
	STAssertEquals([obj class], newClass, @"");
}

- (void)test_replacedClassIsKindOfOriginalClass
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override log method
	[obj setBlockForClassMethod:@selector(classLog) key:@"logBlock" block:^(Class receiver) {
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
	obj = [NSObject object];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	
	// Set obj conformable to protocol
	[obj setConformable:YES toProtocol:protocol key:key];
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	
	// Set obj not-conformable to protocol
	[obj setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_removeBlockForInstanceMethod_key_class
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Responds?
	STAssertTrue(![object_getClass(obj) respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	[obj setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block";
	}];
	
	// Remove block
	[obj removeBlockForClassMethod:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![object_getClass(obj) respondsToSelector:sel], @"");
}

- (void)test_REIMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		called = YES;
	}];
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		(REIMP(void)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
	}];
	
	// Call
	objc_msgSend(object_getClass(obj), sel);
	STAssertTrue(called, @"");
}

- (void)test_REIMP__id
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return @"hello";
	}];
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		NSString *res;
		res = (REIMP(id)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
		return res;
	}];
	
	STAssertEqualObjects(objc_msgSend(object_getClass(obj), sel), @"hello", @"");
}

- (void)test_REIMP__scalar
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return 1;
	}];
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		NSInteger i;
		i = (REIMP(NSInteger)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
		return i + 1;
	}];
	
	STAssertEquals((NSInteger)objc_msgSend(object_getClass(obj), sel), (NSInteger)2, @"");
}

- (void)test_REIMP__CGRect
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		RESupermethod(CGRectZero, receiver, sel);
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		CGRect rect;
		rect = (REIMP(CGRect)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Check rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)(object_getClass(obj), sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSString *string) {
		RESupermethod(nil, receiver, sel, string);
		STAssertEqualObjects(string, @"block", @"");
	}];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSString *string) {
		RESupermethod(nil, receiver, sel, @"block");
		STAssertEqualObjects(string, @"string", @"");
	}];
	
	// Call
	objc_msgSend(object_getClass(obj), sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, sel, @"Wow"), string];
	}];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, sel, @"block1"), string];
	}];
	
	// Call
	NSString *string;
	string = objc_msgSend(object_getClass(obj), sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, sel, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	}];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, sel, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend(object_getClass(obj), sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod((CGRect){}, receiver, sel, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	
	// Add block
	[obj setBlockForClassMethod:sel key:nil block:^(Class receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver, sel, origin, size);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		return rect;
	}];
	
	// Call
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)(object_getClass(obj), sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

@end
