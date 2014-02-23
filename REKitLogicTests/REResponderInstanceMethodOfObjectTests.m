/*
 REResponderInstanceMethodOfObjectTests.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderInstanceMethodOfObjectTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Check if sueprmethodOfCurrentBlock: returns correct selector >>>


@implementation REResponderInstanceMethodOfObjectTests

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
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Responds to log method dynamically
	RESetBlock(obj, sel, NO, nil, ^NSString*(id receiver) {
		return @"block";
	});
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block", @"");
	
	// Don't affect class
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertFalse([NSObject instancesRespondToSelector:sel], @"");
	STAssertFalse([[obj class] respondsToSelector:sel], @"");
}

- (void)test_overrideHardcodedMethod
{
	SEL sel = @selector(log);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Responds?
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
	
	// You can override hardcoded method
	RESetBlock(obj, sel, NO, nil, ^NSString*(id receiver) {
		return @"Overridden log";
	});
	STAssertEqualObjects([obj log], @"Overridden log", @"");
	
	// Don't affect to class
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue([RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![[obj class] respondsToSelector:sel], @"");
	STAssertTrue([[obj class] instancesRespondToSelector:sel], @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherInstances
{
	// Make obj and otherObj
	id obj;
	id otherObj;
	obj = [NSObject object];
	otherObj = [NSObject object];
	
	// Add dynamic block to obj
	RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
		return @"Dynamic log";
	});
	
	// Check
	STAssertFalse([otherObj respondsToSelector:@selector(log)], @"");
}

- (void)test_overrideBlockDoesNotAffectOtherInstances
{
	NSString *string;
	
	// Make obj and otherObj
	RETestObject *obj;
	RETestObject *otherObj;
	obj = [RETestObject object];
	otherObj = [RETestObject object];
	
	// Override log method of obj
	RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
		return @"Overridden log";
	});
	
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
		obj = [NSObject object];
		
		// Add log method
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use obj
			id object;
			object = obj;
		});
		
		// Override dealloc method
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
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
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use obj
			id object;
			object = obj;
		});
		
		// Override dealloc method
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
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
		RESetBlock(obj, @selector(dealloc), NO, obj, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
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
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Do something…
			receiver = receiver;
		});
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
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
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
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
		RESetBlock(key, @selector(dealloc), NO, nil, ^(id receiver) {
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

//- (void)test_blockIsReleased
//{
//	__block BOOL released = NO;
//	
//	@autoreleasepool {
//		// Make obj
//		id obj;
//		obj = [NSObject object];
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do something…
//		});
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		});
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
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
//		obj = [NSObject object];
//		
//		// Add log method
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do nothing…
//		});
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		});
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
//		
//		// Override log method
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// supermethod
//			RESupermethod(nil, receiver);
//		});
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
//		obj = [NSObject object];
//		
//		// Add log method
//		[obj setBlockForSelector:@selector(log) key:nil block:^(id receiver) {
//			// Do nothing…
//		});
//		
//		// Get block
//		id block;
//		block = imp_getBlock([obj methodForSelector:@selector(log)]);
//		[block setBlockForSelector:@selector(release) key:nil block:^(id receiver) {
//			released = YES;
//		});
//		[block setBlockForSelector:@selector(retain) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
//		[block setBlockForSelector:@selector(copy) key:nil block:^(id receiver) {
//			STFail(@"");
//		});
//		
//		// Override log method
//		[obj setBlockForSelector:@selector(log) key:@"key" block:^(id receiver) {
//			// Do nothing…
//		});
//		
//		// Remove top log block
//		[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
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
		RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
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
			ctx = context;
		});
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
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
		RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
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
			ctx = context;
		});
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Do nothing…
			id ctx;
			ctx = context;
		});
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
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
		RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Add log method
		RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
		});
		
		// Override log method
		RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
			// Use context
			id ctx;
			ctx = context;
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
		RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
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
		RESetBlock(obj, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise isObjDeallocated
			isObjDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, dealloc);
		});
		
		@autoreleasepool {
			// Make context
			__autoreleasing id context;
			context = [NSObject object];
			RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
				// Raise deallocated flag
				isContextDeallocated = YES;
				
				// supermethod
				RESupermethod(nil, receiver, dealloc);
			});
			
			// Add log block
			RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
				id ctx;
				ctx = context;
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
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [NSObject object];
		
		@autoreleasepool {
			// Make context
			RETestObject *context;
			context = [RETestObject object];
			RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
				// Raise deallocated flag
				deallocated = YES;
				
				// supermethod
				RESupermethod(nil, receiver);
			});
			
			// Associate context
			[obj setAssociatedValue:context forKey:@"context" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
			
			// Add log block
			RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
				id ctx;
				ctx = [receiver associatedValueForKey:@"context"];
			});
			
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
	obj = [NSObject object];
	
	// Add block with arguments
	RESetBlock(obj, @selector(logWithSuffix:), NO, nil, ^NSString*(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	});
	
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
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"block", ^CGRect(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	});
	
	// Check rect
	rect = (RE_IMP(CGRect)objc_msgSend_stret)(obj, sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add doSomething method
	RESetBlock(obj, @selector(doSomething), NO, nil, ^(id receiver) {
		called = YES;
	});
	
	// Call imp
	IMP imp;
	imp = [obj methodForSelector:@selector(doSomething)];
	(RE_IMP(void)imp)(obj, @selector(doSomething));
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForInstanceMethod_key
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add log block
	RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
		// Do something
		receiver = receiver;
	});
	STAssertTrue([obj hasBlockForInstanceMethod:@selector(log) key:@"key"], @"");
	
	// Remove log block
	[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
	STAssertTrue(![obj hasBlockForInstanceMethod:@selector(log) key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block for log method with key
	RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
		return @"log";
	});
	
	// Add block for say method with key
	RESetBlock(obj, @selector(say), NO, @"key", ^(id receiver) {
		return @"say";
	});
	
	// Perform log
	string = [obj performSelector:@selector(log)];
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(log)], @"");
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[obj removeBlockForInstanceMethod:@selector(say) key:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(say)], @"");
}

- (void)test_replaceBlock
{
	NSString *string;
	
	// Make test obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Add log block
	RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
		return @"Overridden log";
	});
	
	// Replace log block
	RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
		return @"Replaced log";
	});
	
	// Remove block for key
	[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
	string = [obj log];
	STAssertEqualObjects(string, @"log", @"");
}

- (void)test_stackOfDynamicBlocks
{
	id obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [NSObject object];
	STAssertFalse([obj respondsToSelector:sel], @"");
	
	// Add block1
	RESetBlock(obj, sel, NO, @"block1", ^NSString*(id receiver) {
		return @"block1";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	RESetBlock(obj, sel, NO, @"block2", ^NSString*(id receiver) {
		return @"block2";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	RESetBlock(obj, sel, NO, @"block3", ^NSString*(id receiver) {
		return @"block3";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForInstanceMethod:sel key:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForInstanceMethod:sel key:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForInstanceMethod:sel key:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
	STAssertNotNil((id)[obj methodForSelector:sel], @"");
	STAssertEquals([obj methodForSelector:sel], [obj methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_connectToForwardingMethod
{
	NSString *string = nil;
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Add block1
	RESetBlock(obj, (sel = @selector(readThis:)), NO, @"block1", ^(id receiver, NSString *string) {
		return string;
	});
	string = [obj performSelector:sel withObject:@"Read"];
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[obj removeBlockForInstanceMethod:sel key:@"block1"];
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
	obj = [RETestObject object];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Add bock1
	RESetBlock(obj, sel, NO, @"block1", ^NSString*(id receiver) {
		return @"block1";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	RESetBlock(obj, sel, NO, @"block2", ^NSString*(id receiver) {
		return @"block2";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	RESetBlock(obj, sel, NO, @"block3", ^NSString*(id receiver) {
		return @"block3";
	});
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockForInstanceMethod:sel key:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForInstanceMethod:sel key:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForInstanceMethod:sel key:@"block2"];
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
	obj = [NSObject object];
	
	// Add block with key
	RESetBlock(obj, sel, NO, @"key", ^NSString*(id receiver) {
		return @"block1";
	});
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	RESetBlock(obj, sel, NO, @"key", ^NSString*(id receiver) {
		return @"block2";
	});
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	RETestObject *obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [RETestObject object];
	
	// Add block with key
	RESetBlock(obj, sel, NO, @"key", ^NSString*(id receiver) {
		return @"block1";
	});
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	RESetBlock(obj, sel, NO, @"key", ^NSString*(id receiver) {
		return @"block2";
	});
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:sel key:@"key"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	id obj;
	obj = [NSObject object];
	for (id anObj in @[obj, obj]) {
		RESetBlock(anObj, sel, NO, @"key", ^(id receiver) {
			return @"block";
		});
	}
	
	// Call log
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_overrideBySameBlock
{
	SEL sel = @selector(log);
	
	id obj;
	obj = [RETestObject object];
	for (id anObj in @[obj, obj]) {
		RESetBlock(anObj, sel, NO, @"key", ^(id receiver) {
			return @"block";
		});
	}
	
	// Call log
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:sel key:@"key"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log", @"");
}

- (void)test_canShareBlock
{
	SEL sel = @selector(log);
	
	id obj1, obj2;
	RETestObject *obj3;
	obj1 = [NSObject object];
	obj2 = [NSObject object];
	obj3 = [RETestObject object];
	
	// Share block
	for (id obj in @[obj1, obj2, obj3]) {
		RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
			return @"block";
		});
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend(obj2, sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"block", @"");
	
	// Remove block from obj2
	[obj2 removeBlockForInstanceMethod:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertFalse([obj2 respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"block", @"");
	
	// Remove block from obj3
	[obj3 removeBlockForInstanceMethod:sel key:@"key"];
	STAssertEqualObjects(objc_msgSend(obj1, sel), @"block", @"");
	STAssertFalse([obj2 respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj3, sel), @"log", @"");
	
	// Remove block from obj1
	[obj1 removeBlockForInstanceMethod:sel key:@"key"];
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
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"key", block);
	
	// Call
	STAssertTrue([obj respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_receiverIsObject
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, Nil, ^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		called = YES;
		RERemoveCurrentBlock();
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToNil
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSArray array];
	
	// Add block
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertNil((id)[receiver supermethodOfInstanceMethod:re_selector key:re_key], @"");
		
		called = YES;
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToOriginalMethod
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	IMP originalMethod;
	originalMethod = [obj methodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override log method
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfInstanceMethod:re_selector key:re_key], originalMethod, @"");
		
		called = YES;
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RESubTestObject object];
	
	// Add log block
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfInstanceMethod:re_selector key:re_key], [RETestObject instanceMethodForSelector:sel], @"");
		
		called = YES;
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToInstancesBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add method to NSObject
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		called = YES;
	});
	
	// Get imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	
	// Add method to obj
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfInstanceMethod:re_selector key:re_key];
		STAssertEquals(supermethod, imp, @"");
		
		// supermethod
		RESupermethod(nil, receiver);
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToClassMethod
{
	SEL sel = _cmd;
	__block BOOL dirty = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add class method
	RESetBlock([NSObject class], sel, YES, nil, ^(Class receiver) {
		dirty = YES;
	});
	
	// Add object method
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		IMP supermethod;
		supermethod = [receiver supermethodOfInstanceMethod:re_selector key:re_key];
		STAssertNil((id)supermethod, @"");
		
		// supermethod
		RESupermethod(nil, receiver);
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(!dirty, @"");
}

- (void)test_supermethodOfDynamicBlock
{
	id obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [NSObject object];
	
	// Add block1
	RESetBlock(obj, sel, NO, @"block1", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block1"];
	});
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	RESetBlock(obj, sel, NO, @"block2", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block2"];
	});
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	RESetBlock(obj, sel, NO, @"block3", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block3"];
	});
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForInstanceMethod:sel key:@"block3"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForInstanceMethod:sel key:@"block1"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockForInstanceMethod:sel key:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	RETestObject *obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [RETestObject object];
	
	// Add block1
	RESetBlock(obj, sel, NO, @"block1", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block1"];
	});
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1", @"");
	
	// Add block2
	RESetBlock(obj, sel, NO, @"block2", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block2"];
	});
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Add block3
	RESetBlock(obj, sel, NO, @"block3", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"-block3"];
	});
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockForInstanceMethod:sel key:@"block3"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForInstanceMethod:sel key:@"block1"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block2", @"");
	
	// Remove block2
	[obj removeBlockForInstanceMethod:sel key:@"block2"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel;
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override age method
	RESetBlock(obj, (sel = @selector(age)), NO, nil, ^NSUInteger(id receiver) {
		return (RESupermethod(0, receiver) + 1);
	});
	
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
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override age method
	RESetBlock(obj, (sel = @selector(ageAfterYears:)), NO, nil, ^NSUInteger(id receiver, NSUInteger years) {
		return (RESupermethod(years, receiver, years) + 1);
	});
	
	// Get age
	NSUInteger age;
	age = [obj ageAfterYears:3];
	STAssertEquals(age, (NSUInteger)14, @"");
}

- (void)test_supermethodReturningStructure
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.rect = CGRectMake(10.0f, 20.0f, 30.0f, 40.0f);
	
	// Override rect method
	RESetBlock(obj, @selector(rect), NO, nil, ^(id receiver) {
		return CGRectInset(RESupermethod(CGRectZero, receiver), 3.0f, 6.0f);
	});
	
	// Get rect
	CGRect rect;
	rect = obj.rect;
	STAssertEquals(rect, CGRectMake(13.0f, 26.0f, 24.0f, 28.0f), @"");
}

- (void)test_supermethodReturningVoid
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	RESetBlock(obj, @selector(sayHello), NO, nil, ^(id receiver) {
		// supermethod
		RESupermethod(nil, receiver);
	});
	[obj sayHello];
}

- (void)test_removeBlockForInstanceMethod_key
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add log method
	RESetBlock(obj, @selector(log), NO, @"key", ^(id receiver) {
		// Do something
	});
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Remove block
	[obj removeBlockForInstanceMethod:@selector(log) key:@"key"];
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
	obj = [NSObject object];
	
	// Add log method
	RESetBlock(obj, @selector(log), NO, nil, ^(id receiver) {
		// Remove currentBlock
		RERemoveCurrentBlock();
	});
	
	// Check
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	[obj performSelector:@selector(log)];
	STAssertTrue(![obj respondsToSelector:@selector(log)], @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block1
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		RERemoveCurrentBlock();
		return @"block1-";
	});
	
	// Add block2
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"block2"];
	});
	
	// Call
	string = objc_msgSend(obj, sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend(obj, sel);
	STAssertEqualObjects(string, @"block2", @"");
}

- (void)test_doNotChangeClassFrequentlyWithDynamicBlockManagement
{
	// Make obj
	NSObject *obj;
	obj = [RETestObject object];
	
	// Add log method
	RESetBlock(obj, @selector(log), NO, @"logBlock", ^(id receiver) {
		return @"Dynamic log";
	});
	STAssertTrue([obj class] == [RETestObject class], @"");
	STAssertTrue(REGetClass(obj) != [RETestObject class], @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
	STAssertTrue(REGetSuperclass(obj) != [RETestObject superclass], @"");
	
	// Record new class
	Class newClass;
	newClass = REGetClass(obj);
	
	// Add say method
	RESetBlock(obj, @selector(say), NO, @"sayBlock", ^(id receiver) {
		return @"Dynamic say";
	});
	STAssertEquals([obj class], [RETestObject class], @"");
	STAssertEquals(REGetClass(obj), newClass, @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
	
	// Remove blocks
	[obj removeBlockForInstanceMethod:@selector(log) key:@"logBlock"];
	[obj removeBlockForInstanceMethod:@selector(say) key:@"sayBlock"];
	STAssertTrue([obj class] == [RETestObject class], @"");
	STAssertEquals(REGetClass(obj), newClass, @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
}

- (void)test_doNotChangeClassFrequentlyWithOverrideBlockManagement
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override log method
	RESetBlock(obj, @selector(log), NO, @"logBlock", ^(id receiver) {
		return @"Overridden log";
	});
	STAssertTrue([obj class] == [RETestObject class], @"");
	STAssertTrue(REGetClass(obj) != [RETestObject class], @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
	STAssertTrue(REGetSuperclass(obj) != [RETestObject superclass], @"");
	
	// Record new class
	Class newClass;
	newClass = REGetClass(obj);
	
	// Override say method
	RESetBlock(obj, @selector(say), NO, @"sayBlock", ^(id receiver) {
		return @"Overridden say";
	});
	STAssertEquals([obj class], [RETestObject class], @"");
	STAssertEquals(REGetClass(obj), newClass, @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
	
	// Remove blocks
	[obj removeBlockForInstanceMethod:@selector(log) key:@"logBlock"];
	[obj removeBlockForInstanceMethod:@selector(say) key:@"sayBlock"];
	STAssertTrue([obj class] == [RETestObject class], @"");
	STAssertEquals(REGetClass(obj), newClass, @"");
	STAssertTrue([obj superclass] == [RETestObject superclass], @"");
}

- (void)test_replacedClassIsKindOfOriginalClass
{
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	
	// Override log method
	RESetBlock(obj, @selector(log), NO, @"logBlock", ^(id receiver) {
		return @"Overridden log";
	});
	
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

- (void)test_setConformableToProtocol__conformsToIncorporatedProtocols
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Set obj conformable to NSSecureCoding
	[obj setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__canNotRemoveIncorporatedProtocol
{
	// Make obj
	id obj;
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
	obj = [NSObject object];
	
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
		key = [NSObject object];
		RESetBlock(key, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Make obj
		id obj;
		obj = [NSObject object];
		
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
	obj = [NSObject object];
	STAssertNoThrow(responds = [obj respondsToSelector:nil], @"");
	STAssertTrue(!responds, @"");
}

- (void)test_conformsToProtocol__callWithNil
{
	// Make obj
	id obj;
	obj = [NSObject object];
	STAssertNoThrow([obj conformsToProtocol:nil], @"");
}

- (void)test_respondsToUnimplementedMethod_class
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Check NSObject
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	RESetBlock([NSObject class], sel, YES, @"key", ^(Class receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	});
	
	// Responds to selector?
	STAssertTrue([[NSObject class] respondsToSelector:sel], @"");
	
	// Call the sel
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block", @"");
	
	// Don't affect to instances
	id obj;
	obj = [NSObject object];
	STAssertFalse([obj respondsToSelector:sel], @"");
	
	// Remove block
	[NSObject removeBlockForClassMethod:sel key:@"key"];
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

- (void)test_removeBlockForInstanceMethod_key_class
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	RESetBlock([NSObject class], sel, YES, @"key", ^(Class receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	});
	
	// Remove block
	[NSObject removeBlockForClassMethod:sel key:@"key"];
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

- (void)test_RE_IMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		called = YES;
	});
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		(RE_IMP(void)[receiver supermethodOfInstanceMethod:re_selector key:re_key])(receiver, sel);
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(called, @"");
}

- (void)test_RE_IMP__id
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"hello";
	});
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		NSString *res;
		res = (RE_IMP(id)[receiver supermethodOfInstanceMethod:re_selector key:re_key])(receiver, sel);
		return res;
	});
	
	STAssertEqualObjects(objc_msgSend(obj, sel), @"hello", @"");
}

- (void)test_RE_IMP__scalar
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return 1;
	});
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		NSInteger i;
		i = (RE_IMP(NSInteger)[receiver supermethodOfInstanceMethod:re_selector key:re_key])(receiver, sel);
		return i + 1;
	});
	
	STAssertEquals((NSInteger)objc_msgSend(obj, sel), (NSInteger)2, @"");
}

- (void)test_RE_IMP__CGRect
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	});
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	});
	
	// Check rect
	CGRect rect;
	rect = (RE_IMP(CGRect)objc_msgSend_stret)(obj, sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, string);
		STAssertEqualObjects(string, @"block", @"");
	});
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, @"block");
		STAssertEqualObjects(string, @"string", @"");
	});
	
	// Call
	objc_msgSend(obj, sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, @"Wow"), string];
	});
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, @"block1"), string];
	});
	
	// Call
	NSString *string;
	string = objc_msgSend(obj, sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	});
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	});
	
	// Call
	NSInteger value;
	value = objc_msgSend(obj, sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod((CGRect){}, receiver, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	});
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver, origin, size);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		return rect;
	});
	
	// Call
	CGRect rect;
	rect = (RE_IMP(CGRect)objc_msgSend_stret)(obj, sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_KVODoesNotChangeClassImarginary
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertEqualObjects(NSStringFromClass([obj class]), @"RETestObject", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_REResponderDoesNotChangeClassImaginary
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Check
	STAssertEqualObjects(NSStringFromClass([obj class]), @"RETestObject", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_dynamicBlockAddedBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_overrideBlockAddedBeforeKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_dynamicBlockAddedAfterKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_overrideBlockAddedAfterKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_hasDynamicBlockAddedBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Make originalObj
	id originalObj;
	originalObj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_hasOverrideBlockAddedBeforeKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Make originalObj
	id originalObj;
	originalObj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertTrue([obj hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_hasDynamicBlockAddedAfterKVO
{
	// Not Implemented >>>
}

- (void)test_hasOverrideBlockAddedAfterKVO
{
	// Not Implemented >>>
}

- (void)test_supermethodOfDynamicBlockAddedBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"block1", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"1"];
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock(obj, sel, NO, @"block2", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"2"];
	});
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"12", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"12", @"");
}

- (void)test_supermethodOfOverrideBlockAddedBeforeKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock(obj, sel, NO, @"block1", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"1"];
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock(obj, sel, NO, @"block2", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver), @"2"];
	});
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
}

@end
