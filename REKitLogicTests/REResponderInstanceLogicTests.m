/*
 REResponderInstanceLogicTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderInstanceLogicTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderInstanceLogicTests

- (void)_resetClasses
{
	// Reset all classes
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		// Remove blocks
		NSMutableDictionary *blocks;
		blocks = [aClass associatedValueForKey:@"REResponder_blocks"];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[blockInfos enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForSelector:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		blocks = [aClass associatedValueForKey:@"REResponder_instaceBlocks"];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[blockInfos enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForInstanceMethodForSelector:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
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

- (void)test_dynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	id obj = [NSObject object];
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Call the sel
	log = objc_msgSend(obj, sel);
	STAssertEqualObjects(log, @"block", @"");
}

- (void)test_methodOfDynamicBlock
{
	SEL sel = @selector(log);
	id obj = [RESubTestObject object];
	
	// Responds to log method dynamically
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	STAssertTrue([RESubTestObject instancesRespondToSelector:sel], @"");
	
	// Get method
	IMP method;
	method = [RESubTestObject instanceMethodForSelector:sel];
	
	// Don't affet class method
	STAssertTrue([RESubTestObject methodForSelector:sel] != method, @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
	
	// Affect to instance
	STAssertEquals([obj methodForSelector:sel], method, @"");
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Don't affect superclass
	STAssertTrue([NSObject methodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue([NSObject instanceMethodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue([[NSObject object] methodForSelector:sel] != method, @"");
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_overrideBlock
{
	SEL sel = @selector(log);
	
	// Override
	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check log
	STAssertEqualObjects([[RETestObject object] log], @"overridden", @"");
}

- (void)test_methodOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Override log method
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	STAssertTrue([RETestObject instancesRespondToSelector:sel], @"");
	
	// Get method
	IMP method;
	method = [RETestObject instanceMethodForSelector:sel];
	
	// Don't affect class method
	STAssertTrue([RETestObject methodForSelector:sel] != method, @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	
	// Affect instance
	STAssertEquals([obj methodForSelector:sel], method, @"");
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Don't affect superclass
	STAssertTrue([NSObject methodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue([NSObject instanceMethodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue([[NSObject object] methodForSelector:sel] != method, @"");
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_receiverOfDynamicBlock
{
	SEL sel = @selector(log);
	id obj = [NSObject object];
	
	// Set block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	}];
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_receiverOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Set block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	}];
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_dynamicBlockAffectSubclasses
{
	SEL sel = @selector(log);
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Responds?
	STAssertTrue([NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue([@(1) respondsToSelector:sel], @"");
	
	// Check log
	STAssertEqualObjects(objc_msgSend(@(1), sel), @"block", @"");
}

- (void)test_dynamicBlockAffectSubclassesConnectedToForwardingMethod
{
	SEL sel = _cmd;
	
	// Add block
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertEquals([RETestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([RESubTestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
}

- (void)test_overrideBlockAffectSubclasses
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Override
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherClass
{
	SEL sel = _cmd;
	
	// Set block
	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectOtherClasses
{
	SEL sel = @selector(log);
	
	// Override
	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_dynamicBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(subLog);
	NSString *string;
	
	// Add subRect method
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check return string
	string = [[RESubTestObject object] subLog];
	STAssertEqualObjects(string, @"subLog", @"");
}

- (void)test_overrideBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(overrideLog);
	NSString *string;
	
	// Override overrideLog
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	string = [[RESubTestObject object] overrideLog];
	STAssertEqualObjects(string, @"RESubTestObject", @"");
}

- (void)test_addDynamicBlockToSubclassesOneByOne
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"NSObject";
	}];
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"RETestObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"NSObject", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_overridingLastBlockUpdatesSubclasses
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Override block of NSObject
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"overridden", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_overrideLastBlockWithSameBlock
{
	SEL sel = _cmd;
	
	// Make block
	NSString *(^block)(id receiver);
	block = ^(id receiver) {
		return @"block";
	};
	
	// Set block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:block];
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:block];
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:block];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Override block with same block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:block];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_addDynamicBlockToSubclasses
{
	SEL sel = _cmd;
	
	// Add block
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		[aClass setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_canPsssReceiverAsKey
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add log method
	[NSObject setBlockForInstanceMethodForSelector:sel key:[NSObject class] block:^(id receiver) {
		return @"block";
	}];
	log = objc_msgSend([NSObject object], sel);
	
	// Check log
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:[NSObject class]];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_contextOfRemovedBlockIsDeallocated
{
	SEL selector = @selector(log);
	__block BOOL isContextDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		[context setBlockForSelector:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Add log method
		[NSObject setBlockForInstanceMethodForSelector:selector key:@"key1" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[NSObject setBlockForInstanceMethodForSelector:selector key:@"key2" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Remove blocks
		[NSObject removeBlockForInstanceMethodForSelector:selector key:@"key2"];
		STAssertTrue(!isContextDeallocated, @"");
		[NSObject removeBlockForInstanceMethodForSelector:selector key:@"key1"];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
}

- (void)test_allowArguments
{
	SEL selector = @selector(logWithSuffix:);
	NSString *log;
	
	// Add block
	[NSObject setBlockForInstanceMethodForSelector:selector key:nil block:^(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call
	log = objc_msgSend([NSObject object], selector, @"suffix");
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Add block
	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Call the method
	NSInvocation *invocation;
	CGPoint origin;
	CGSize size;
	origin = CGPointMake(10.0f, 20.0f);
	size = CGSizeMake(30.0f, 40.0f);
	invocation = [NSInvocation invocationWithMethodSignature:[NSObject methodSignatureForSelector:sel]];
	[invocation setTarget:[NSObject object]];
	[invocation setSelector:sel];
	[invocation setArgument:&origin atIndex:2];
	[invocation setArgument:&size atIndex:3];
	[invocation invoke];
	[invocation getReturnValue:&rect];
	STAssertEquals(rect, CGRectMake(10.0f, 20.0f, 30.0f, 40.0f), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	SEL sel = @selector(doSomething);
	__block BOOL called = NO;
	
	// Add block
	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	REVoidIMP imp;
	imp = (REVoidIMP)[NSObject instanceMethodForSelector:sel];
	imp([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForInstanceMethodForSelector_key
{
	SEL sel = @selector(log);
	
	// Has block?
	STAssertTrue(![RETestObject hasBlockForInstanceMethodForSelector:sel key:@"key"], @"");
	
	// Add block
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Has block?
	STAssertTrue(![NSObject hasBlockForInstanceMethodForSelector:sel key:@"key"], @"");
	STAssertTrue([RETestObject hasBlockForInstanceMethodForSelector:sel key:@"key"], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethodForSelector:sel key:@""], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethodForSelector:sel key:nil], @"");
	STAssertTrue(![RESubTestObject hasBlockForInstanceMethodForSelector:sel key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Add block for log method with key
	[NSObject setBlockForInstanceMethodForSelector:@selector(log) key:@"key" block:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[NSObject setBlockForInstanceMethodForSelector:@selector(say) key:@"key" block:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = objc_msgSend([NSObject object], @selector(log));
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[NSObject removeBlockForInstanceMethodForSelector:@selector(log) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(log)], @"");
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[NSObject removeBlockForInstanceMethodForSelector:@selector(say) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(say)], @"");
}

- (void)test_stackOfDynamicBlocks
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block1" block:^(id receiver) {
		return @"block1";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_recoonectedToForwardingMethod
{
	SEL sel = @selector(readThis:);
	NSString *string = nil;
	
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block1" block:^(id receiver, NSString *string) {
		return string;
	}];
	string = objc_msgSend([NSObject object], sel, @"Read");
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertEquals([NSObject instanceMethodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_stackOfOverrideBlocks
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForInstanceMethodForSelector:sel key:@"block1" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Call block1
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block1", @"");
	
	// Add block2
	[NSString setBlockForInstanceMethodForSelector:sel key:@"block2" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Add block3
	[NSString setBlockForInstanceMethodForSelector:sel key:@"block3" block:^(id receiver, NSString *string) {
		return @"block3";
	}];
	
	// Call block3
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block3", @"");
	
	// Remove block3
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block1
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block2
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	
	// Call original
	STAssertTrue([[NSString string] respondsToSelector:sel], @"");
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block1";
	}];
	
	// Override the block
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block2";
	}];
	
	// Get log
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Override
	[NSString setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Override block
	[NSString setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Call original
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	for (Class cls in @[[NSObject class], [NSObject class]]) {
		[cls setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_canShareBlock
{
	SEL sel = _cmd;
	
	// Share block
	for (Class cls in @[[NSObject class], [NSObject class], [RETestObject class]]) {
		[cls setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([[RETestObject object] respondsToSelector:sel], @"");
}

- (void)test_supermethodOf1stDynamicBlock // Check in other test cases >>>
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add block
	[NSString setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		// Get supermethod
		REVoidIMP supermethod;
		supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock];
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([NSString string], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToNil // Check in other test cases >>>
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add block
	[NSArray setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([NSArray array], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass // Check in other test cases >>>
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add log block to RESubTestObject
	[RESubTestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		// supermethod
		id res = nil;
		typedef id (*id_IMP)(id, SEL, ...);
		id_IMP supermethod;
		if ((supermethod = (id_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, [RETestObject instanceMethodForSelector:sel], @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RESubTestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToOriginalMethod // Check in other test cases
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	IMP originalMethod;
	originalMethod = [RETestObject instanceMethodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override log method
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		// supermethod
		NSString *res = nil;
		typedef id (*id_IMP)(id, SEL, ...);
		id_IMP supermethod;
		if ((supermethod = (id_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, originalMethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Get imp
	IMP imp;
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		called = YES;
	}];
	imp = [NSObject instanceMethodForSelector:sel];
	
	// Add block
	[RETestObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, imp, @"");
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_orderOfSupermethod
{
// ?????
return;
	SEL sel = _cmd;
	__block NSMutableArray *imps;
	imps = [NSMutableArray array];
	
	id testObj;
	id obj;
	testObj = [RETestObject object];
	obj = [NSObject object];
	
	// Add block to testObj
	[testObj setBlockForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp1;
	imp1 = [testObj methodForSelector:sel];
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp2;
	imp2 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp3;
	imp3 = [obj methodForSelector:sel];
	
	// Add block to RETestObject
	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp4;
	imp4 = [RETestObject instanceMethodForSelector:sel];
	
	// Add block to NSObject
	[[obj class] setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp5;
	imp5 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp6;
	imp6 = [obj methodForSelector:sel];
	
	// Add block to testObj
	[testObj setBlockForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp7;
	imp7 = [testObj methodForSelector:sel];
	
	// Add block to RETestObject
	[[testObj class] setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
		}
		[imps addObject:[NSValue valueWithPointer:supermethod]];
	}];
	IMP imp8;
	imp8 = [RETestObject instanceMethodForSelector:sel];
// ?????
NSLog(@"imp7 = %p", imp7);
NSLog(@"imp1 = %p", imp1);
NSLog(@"imp8 = %p", imp8);
NSLog(@"imp4 = %p", imp4);
NSLog(@"imp5 = %p", imp5);
NSLog(@"imp2 = %p", imp2);
	
	// Call
	objc_msgSend(testObj, sel);
	
	// Check
	NSArray *expected;
	expected = @[
		[NSValue valueWithPointer:imp7],
		[NSValue valueWithPointer:imp1],
		[NSValue valueWithPointer:imp8],
		[NSValue valueWithPointer:imp4],
		[NSValue valueWithPointer:imp5],
		[NSValue valueWithPointer:imp2],
	];
	STAssertEqualObjects(imps, expected, @"");
}

- (void)test_supermethodOfDynamicBlock
{
// ?????
return;
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block1" block:^(id receiver) {
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append supermethod's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block2" block:^(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append supermethod's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"block3" block:^NSString*(id receiver) {
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
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

//- (void)test_supermethodOfOverrideBlock
//{
//	SEL sel = @selector(stringWithString:);
//	NSString *string;
//	
//	// Add block1
//	[NSString setBlockForInstanceMethodForSelector:sel key:@"block1" block:^(id receiver, NSString *string) {
//		NSMutableString *str;
//		str = [NSMutableString string];
//		
//		// Append supermethod's string
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			[str appendString:supermethod(receiver, sel, string)];
//		}
//		
//		// Append my string
//		[str appendString:@"-block1"];
//		
//		return str;
//	}];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string-block1", @"");
//	
//	// Add block2
//	[NSString setBlockForInstanceMethodForSelector:sel key:@"block2" block:^(id receiver, NSString *string) {
//		NSMutableString *str;
//		str = [NSMutableString string];
//		
//		// Append supermethod's string
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			[str appendString:supermethod(receiver, sel, string)];
//		}
//		
//		// Append my string
//		[str appendString:@"-block2"];
//		
//		return str;
//	}];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string-block1-block2", @"");
//	
//	// Add block3
//	[NSString setBlockForInstanceMethodForSelector:sel key:@"block3" block:^(id receiver, NSString *string) {
//		NSMutableString *str;
//		str = [NSMutableString string];
//		
//		// Append supermethod's string
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			[str appendString:supermethod(receiver, sel, string)];
//		}
//		
//		// Append my string
//		[str appendString:@"-block3"];
//		
//		return str;
//	}];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string-block1-block2-block3", @"");
//	
//	// Remove block3
//	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block3"];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string-block1-block2", @"");
//	
//	// Remove block1
//	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block1"];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string-block2", @"");
//	
//	// Remove block2
//	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block2"];
//	
//	// Call
//	string = objc_msgSend([NSString class], sel, @"string");
//	STAssertEqualObjects(string, @"string", @"");
//}
//
//- (void)test_supermethodReturningScalar
//{
//	SEL sel = @selector(version);
//	
//	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
//		NSInteger version = -1;
//		
//		// Get original version
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			version = (NSInteger)supermethod(receiver, sel);
//		}
//		
//		// Increase version
//		version++;
//		
//		return version;
//	}];
//	
//	// Call
//	NSInteger version;
//	version = [NSObject version];
//	STAssertEquals(version, (NSInteger)1, @"");
//}
//
//- (void)test_supermethodWithArgumentReturningScalar
//{
//	SEL sel = @selector(integerWithInteger:);
//	
//	// Override
//	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver, NSInteger integer) {
//		NSInteger intg = -1;
//		
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			intg = (NSInteger)supermethod(receiver, sel, integer);
//		}
//		
//		// Increase inteer
//		intg++;
//		
//		return intg;
//	}];
//	
//	// Call
//	NSInteger integer;
//	integer = [RETestObject integerWithInteger:3];
//	STAssertEquals(integer, (NSInteger)4, @"");
//}
//
//- (void)test_supermethodReturningStructure
//{
//	SEL sel = @selector(theRect);
//	
//	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
//		// supermethod
//		CGRect res;
//		typedef CGRect (*CGRect_IMP)(id, SEL, ...);
//		CGRect_IMP supermethod;
//		if ((supermethod = (CGRect_IMP)[receiver supermethodOfCurrentBlock])) {
//			res = supermethod(receiver, sel);
//		}
//		
//		// Inset
//		return CGRectInset(res, 10.0, 20.0);
//	}];
//	
//	// Get rect
//	CGRect rect;
//	rect = [RETestObject theRect];
//	STAssertEquals(rect, CGRectMake(110.0, 220.0, 280.0, 360.0), @"");
//}
//
//- (void)test_supermethodReturningVoid
//{
//	SEL sel = @selector(sayHello);
//	__block BOOL called = NO;
//	[RETestObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
//		// supermethod
//		IMP supermethod;
//		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//			supermethod(receiver, sel);
//			called = YES;
//		}
//	}];
//	[RETestObject sayHello];
//	
//	STAssertTrue(called, @"");
//}
//
//- (void)test_getSupermethodFromOutsideOfBlock
//{
//	IMP supermethod;
//	supermethod = [NSObject supermethodOfCurrentBlock];
//	STAssertNil((id)supermethod, @"");
//}

- (void)test_removeBlockForInstanceMethodForSelector_key
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Check imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

//- (void)test_removeCurrentBlock
//{
//	SEL sel = @selector(doSomething);
//	
//	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
//		// Remove currentBlock
//		[receiver removeCurrentBlock];
//	}];
//	STAssertTrue([NSObject respondsToSelector:sel], @"");
//	objc_msgSend([NSObject class], sel);
//	STAssertFalse([NSObject respondsToSelector:sel], @"");
//}
//
//- (void)test_canCallRemoveCurrentBlockFromOutsideOfBlock
//{
//	SEL sel = @selector(doSomething);
//	
//	// Call removeCurrentBlock
//	STAssertNoThrow([NSObject removeCurrentBlock], @"");
//	
//	// Add doSomething method
//	[NSObject setBlockForInstanceMethodForSelector:sel key:@"key" block:^(id receiver) {
//		// Do something
//	}];
//	
//	// Call removeCurrentBlock
//	STAssertNoThrow([NSObject removeCurrentBlock], @"");
//	
//	// Check doSomething method
//	STAssertTrue([NSObject respondsToSelector:sel], @"");
//}
//
//- (void)test_doNotChangeClass
//{
//	Class cls;
//	cls = [NSMutableString class];
//	
//	[NSMutableString setBlockForInstanceMethodForSelector:@selector(stringWithString:) key:nil block:^(id receiver, NSString *string) {
//		// Do something
//	}];
//	
//	// Check class
//	STAssertEquals([NSMutableString class], cls, @"");
//	STAssertEquals([NSMutableString superclass], [NSString class], @"");
//}
//
//- (void)test_setConformableToProtocol
//{
//	// Make elements
//	Protocol *protocol;
//	NSString *key;
//	id obj;
//	protocol = @protocol(NSCopying);
//	key = NSStringFromSelector(_cmd);
//	obj = [NSObject object];
//	
//	// Check
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Set NSObject conformable to protocol
//	[NSObject setConformable:YES toProtocol:protocol key:key];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Set NSObject not-conformable to protocol
//	[NSObject setConformable:NO toProtocol:protocol key:key];
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
//}
//
//- (void)test_setConformableToProtocol__conformsToIncorporatedProtocols
//{
//	id obj;
//	obj = [NSObject object];
//	
//	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//}
//
//- (void)test_setConformableToProtocol__canNotRemoveIncorporatedProtocol
//{
//	id obj;
//	obj = [NSObject object];
//	
//	// Set NSObject conformable to NSSecureCoding
//	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
//	
//	// Set NSobject not conformable to NSCoding
//	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//}
//
//- (void)test_setConformableToProtocol__managesProtocolsBySpecifiedProtocol
//{
//	id obj;
//	obj = [NSObject object];
//	
//	// Set NSObject conformable to NSSecureCoding and NSCoding then remove NSSecureCoding
//	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
//	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
//	[NSObject setConformable:NO toProtocol:@protocol(NSSecureCoding) key:@"key"];
//	STAssertTrue(![NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue(![obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue(![RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue(![[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//	
//	// Set NSObject conformable to NSSecureCoding and NSCoding then remove NSCoding
//	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
//	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
//	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//}
//
//- (void)test_setConformableToProtocol__withNilKey
//{
//	id obj;
//	obj = [NSObject object];
//	
//	// Set conformable
//	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:nil];
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//}
//
//- (void)test_setConformableToProtocol__withInvalidArguments
//{
//	// Make elements
//	Protocol *protocol;
//	NSString *key;
//	id obj;
//	protocol = @protocol(NSCopying);
//	key = NSStringFromSelector(_cmd);
//	obj = [NSObject object];
//	
//	// Try to set NSObject conformable with nil-protocol
//	[NSObject setConformable:YES toProtocol:nil key:key];
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//	
//	// Set NSObject conformable to protocol
//	[NSObject setConformable:YES toProtocol:protocol key:key];
//	
//	// Try to set NSObject not-conformable with nil-protocol
//	[NSObject setConformable:NO toProtocol:nil key:key];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Try to set NSObject not-conformable with nil-key
//	[NSObject setConformable:NO toProtocol:protocol key:nil];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Set NSObject not-conformable
//	[NSObject setConformable:NO toProtocol:protocol key:key];
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//}
//
//- (void)test_setConformableToProtocol__stacksKeys
//{
//	// Make elements
//	Protocol *protocol;
//	NSString *key;
//	id obj;
//	protocol = @protocol(NSCopying);
//	key = NSStringFromSelector(_cmd);
//	obj = [NSObject object];
//	
//	// Set NSObject conformable to the protocol with key
//	[NSObject setConformable:YES toProtocol:protocol key:key];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Set NSObject conformable to the protocol with other key
//	[NSObject setConformable:YES toProtocol:protocol key:@"OtherKey"];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Try to set NSObject not-conformable to the protocol
//	[NSObject setConformable:NO toProtocol:protocol key:@"OtherKey"];
//	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
//	STAssertTrue([obj conformsToProtocol:protocol], @"");
//	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
//	
//	// Set NSObject not-conformable to the protocol
//	[NSObject setConformable:NO toProtocol:protocol key:key];
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
//}
//
//- (void)test_setConformableToProtocol__doesNotStackSameKeyForAProtocol
//{
//	Protocol *protocol;
//	NSString *key;
//	id obj;
//	protocol = @protocol(NSCopying);
//	key = NSStringFromSelector(_cmd);
//	obj = [NSObject object];
//	
//	// Set NSObject conformable to the protocol
//	[NSObject setConformable:YES toProtocol:protocol key:key];
//	[NSObject setConformable:YES toProtocol:protocol key:key];
//	[NSObject setConformable:NO toProtocol:protocol key:key];
//	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
//	STAssertFalse([obj conformsToProtocol:protocol], @"");
//	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
//}
//
//- (void)test_setConformableToProtocol__allowsSameKeyForOtherProtocol
//{
//	// Get elements
//	NSString *key;
//	id obj;
//	key = NSStringFromSelector(_cmd);
//	obj = [NSObject object];
//	
//	// Set obj conformable to NSCopying and NSCoding
//	[NSObject setConformable:YES toProtocol:@protocol(NSCopying) key:key];
//	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:key];
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//	
//	// Set obj not-conformable to NSCopying
//	[NSObject setConformable:NO toProtocol:@protocol(NSCopying) key:key];
//	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//	
//	// Set obj not-conformable to NSCoding
//	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:key];
//	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
//	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertFalse([obj conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
//	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
//}
//
//- (void)test_setConformableToProtocol__keyIsDeallocated
//{
//	__block BOOL deallocated = NO;
//	
//	@autoreleasepool {
//		// Prepare key
//		id key;
//		key = [NSObject object];
//		[key setBlockForInstanceMethodForSelector:@selector(dealloc) key:nil block:^(id receiver) {
//			// Raise deallocated flag
//			deallocated = YES;
//			
//			// super
//			IMP supermethod;
//			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
//				supermethod(receiver, @selector(dealloc));
//			}
//		}];
//		
//		// Set NSObject conformable to NSCopying
//		[NSObject setConformable:YES toProtocol:@protocol(NSCopying) key:key];
//		
//		// Reset
//		[NSObject setConformable:NO toProtocol:@protocol(NSCopying) key:key];
//	}
//	
//	// Check
//	STAssertTrue(deallocated, @"");
//}
//
//- (void)test_respondsToSelector__callWithNil
//{
//	// Make obj
//	BOOL responds;
//	STAssertNoThrow(responds = [NSObject respondsToSelector:nil], @"");
//	STAssertFalse(responds, @"");
//}
//
//- (void)test_conformsToProtocol__callWithNil
//{
//	// Make obj
//	BOOL conforms;
//	STAssertNoThrow(conforms = [NSObject conformsToProtocol:nil], @"");
//	STAssertFalse(conforms, @"");
//}

@end
