/*
 REResponderInstanceMethodOfClassLogicTests.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderInstanceMethodOfClassLogicTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderInstanceMethodOfClassLogicTests

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

- (void)test_dynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	id obj = [NSObject object];
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertEquals([RETestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([RESubTestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherClass
{
	SEL sel = _cmd;
	
	// Set block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"NSObject";
	}];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"RETestObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"NSObject", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_overridingLastBlockUpdatesSubclasses
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Override block of NSObject
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"overridden", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:block];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:block];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:block];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Override block with same block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:block];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
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
		[aClass setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_setBlockToPublicClass
{
	SEL sel = _cmd;
	
	id obj;
	obj = [RETestObject object];
	
	// Add Block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"private";
	}];
	[[obj class] setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"public";
	}];
	
	// Check
	STAssertTrue([RETestObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend(obj, sel), @"private", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"public", @"");
}

- (void)test_canPsssReceiverAsKey
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add log method
	[NSObject setBlockForInstanceMethod:sel key:[NSObject class] block:^(id receiver) {
		return @"block";
	}];
	log = objc_msgSend([NSObject object], sel);
	
	// Check log
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[NSObject removeBlockForInstanceMethod:sel key:[NSObject class]];
	
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
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver, @selector(dealloc));
		}];
		
		// Add log method
		[NSObject setBlockForInstanceMethod:selector key:@"key1" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[NSObject setBlockForInstanceMethod:selector key:@"key2" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Remove blocks
		[NSObject removeBlockForInstanceMethod:selector key:@"key2"];
		STAssertTrue(!isContextDeallocated, @"");
		[NSObject removeBlockForInstanceMethod:selector key:@"key1"];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
}

- (void)test_allowArguments
{
	SEL selector = @selector(logWithSuffix:);
	NSString *log;
	
	// Add block
	[NSObject setBlockForInstanceMethod:selector key:nil block:^(id receiver, NSString *suffix) {
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
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Check rect
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	SEL sel = @selector(doSomething);
	__block BOOL called = NO;
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	(REIMP(void)imp)([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForInstanceMethod_key
{
	SEL sel = @selector(log);
	
	// Has block?
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Has block?
	STAssertTrue(![NSObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:@""], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:nil], @"");
	STAssertTrue(![RESubTestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Add block for log method with key
	[NSObject setBlockForInstanceMethod:@selector(log) key:@"key" block:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[NSObject setBlockForInstanceMethod:@selector(say) key:@"key" block:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = objc_msgSend([NSObject object], @selector(log));
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[NSObject removeBlockForInstanceMethod:@selector(log) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(log)], @"");
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[NSObject removeBlockForInstanceMethod:@selector(say) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(say)], @"");
}

- (void)test_stackOfDynamicBlocks
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		return @"block1";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethod:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethod:sel key:@"block3"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethod:sel key:@"block1"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethod:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_connectToForwardingMethod
{
	SEL sel = @selector(readThis:);
	NSString *string = nil;
	
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return string;
	}];
	string = objc_msgSend([NSObject object], sel, @"Read");
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethod:sel key:@"block1"];
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertEquals([NSObject instanceMethodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_stackOfOverrideBlocks
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Call block1
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block1", @"");
	
	// Add block2
	[NSString setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Add block3
	[NSString setBlockForInstanceMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		return @"block3";
	}];
	
	// Call block3
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block3", @"");
	
	// Remove block3
	[NSString removeBlockForInstanceMethod:sel key:@"block3"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block1
	[NSString removeBlockForInstanceMethod:sel key:@"block1"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block2
	[NSString removeBlockForInstanceMethod:sel key:@"block2"];
	
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block1";
	}];
	
	// Override the block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block2";
	}];
	
	// Get log
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Override
	[NSString setBlockForInstanceMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Override block
	[NSString setBlockForInstanceMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block
	[NSString removeBlockForInstanceMethod:sel key:@"key"];
	
	// Call original
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	for (Class cls in @[[NSObject class], [NSObject class]]) {
		[cls setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_canShareBlock
{
	SEL sel = _cmd;
	
	// Share block
	for (Class cls in @[[NSObject class], [NSObject class], [RETestObject class]]) {
		[cls setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from NSObject
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from RETestObject
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertFalse([[RETestObject object] respondsToSelector:sel], @"");
}

- (void)test_supermethodPointsToNil
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add block
	[NSArray setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Check supermethod
		STAssertNil((id)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)), @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([NSArray array], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToOriginalMethod
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	IMP originalMethod;
	originalMethod = [RETestObject instanceMethodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override log method
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Check supermethod
		STAssertEquals((IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)), originalMethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add log block to RESubTestObject
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Check supermethod
		STAssertEquals((IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)), [RETestObject instanceMethodForSelector:sel], @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RESubTestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToInstancesBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Get imp
	IMP imp;
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		called = YES;
	}];
	imp = [NSObject instanceMethodForSelector:sel];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		IMP supermethod;
		if ((supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, imp, @"");
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
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
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		dirty = YES;
	}];
	
	// Add instance method
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// Check supermethod
		STAssertNil((id)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)), @"");
	}];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(!dirty, @"");
}

- (void)test_supermethodOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block1"];
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block2"];
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethod:sel key:@"block3" block:^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block3"];
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethod:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethod:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethod:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, sel, string), @"-block1"];
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1", @"");
	
	// Add block2
	[NSString setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, sel, string), @"-block2"];
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Add block3
	[NSString setBlockForInstanceMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, sel, string), @"-block3"];
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2-block3", @"");
	
	// Remove block3
	[NSString removeBlockForInstanceMethod:sel key:@"block3"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Remove block1
	[NSString removeBlockForInstanceMethod:sel key:@"block1"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block2", @"");
	
	// Remove block2
	[NSString removeBlockForInstanceMethod:sel key:@"block2"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel = @selector(age);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override age method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return (RESupermethod(0, receiver, sel) + 1);
	}];
	
	// Check age
	STAssertEquals(obj.age, (NSUInteger)11, @"");
}

- (void)test_supermethodWithArgumentReturningScalar
{
	SEL sel = @selector(ageAfterYears:);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override ageAfterYears: method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSUInteger years) {
		return (RESupermethod(years, receiver, sel, years) + 1);
	}];
	
	// Check age
	NSUInteger age;
	age = [obj ageAfterYears:3];
	STAssertEquals(age, (NSUInteger)14, @"");
}

- (void)test_supermethodReturningStructure
{
	SEL sel = @selector(rect);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.rect = CGRectMake(10.0f, 20.0f, 30.0f, 40.0f);
	
	// Override rect method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return CGRectInset(RESupermethod(CGRectZero, receiver, sel), 3.0, 6.0);
	}];
	
	// Get rect
	CGRect rect;
	rect = obj.rect;
	STAssertEquals(rect, CGRectMake(13.0f, 26.0f, 24.0f, 28.0f), @"");
}

- (void)test_supermethodReturningVoid
{
	SEL sel = @selector(sayHello);
	__block BOOL called = NO;
	
	// Override sayHello
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))) {
			supermethod(receiver, sel);
			called = YES;
		}
	}];
	[[RETestObject object] sayHello];
	
	// Called?
	STAssertTrue(called, @"");
}

- (void)test_supermethod__order
{
	SEL sel = _cmd;
	__block NSMutableArray *imps;
	imps = [NSMutableArray array];
	
	id testObj;
	id obj;
	testObj = [RETestObject object];
	obj = [NSObject object];
	
	// Add block to testObj
	[testObj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp1;
	imp1 = [testObj methodForSelector:sel];
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp2;
	imp2 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp3;
	imp3 = [obj methodForSelector:sel];
	
	// Add block to RETestObject
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp4;
	imp4 = [RETestObject instanceMethodForSelector:sel];
	
	// Add block to NSObject
	[[obj class] setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp5;
	imp5 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp6;
	imp6 = [obj methodForSelector:sel];
	
	// Add block to testObj
	[testObj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp7;
	imp7 = [testObj methodForSelector:sel];
	
	// Add block to RETestObject
	[[testObj class] setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = (IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock));
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp8;
	imp8 = [RETestObject instanceMethodForSelector:sel];
	
	// Call
	[imps addObject:[NSValue valueWithPointer:[testObj methodForSelector:sel]]];
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

- (void)test_supermethod__obtainFromOutsideOfBlock
{
	IMP supermethod;
	supermethod = (IMP)objc_msgSend([NSObject class], @selector(supermethodOfCurrentBlock));
	STAssertNil((id)supermethod, @"");
}

- (void)test_removeBlockForInstanceMethod_key
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Check imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_removeBlockForInstanceMethod_key__doesNotAffectObjectBlock
{
	SEL sel = _cmd;
	__block NSUInteger count = 0;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Set object block
	[obj setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		count++;
	}];
	
	// Set instances block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		STFail(@"");
	}];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertEquals(count, (NSUInteger)1, @"");
	
	// Remove instances block
	[NSObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertEquals(count, (NSUInteger)2, @"");
}

- (void)test_removeCurrentBlock
{
	SEL sel = @selector(oneShot);
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	objc_msgSend([NSObject object], sel);
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		[receiver removeCurrentBlock];
		return @"block1-";
	}];
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"block2"];
	}];
	
	// Call
	string = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend([NSObject object], sel);
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
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Check doSomething method
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_doNotChangeClass
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Get original class
	Class class;
	class = [obj class];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
	}];
	
	// Check class
	STAssertEquals([obj class], class, @"");
	STAssertEquals(object_getClass(obj), class, @"");
}

- (void)test_REIMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		called = YES;
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		(REIMP(void)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
	}];
	
	// Call
	objc_msgSend([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_REIMP__id
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		return @"hello";
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		NSString *res;
		res = (REIMP(id)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
		return res;
	}];
	
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"hello", @"");
}

- (void)test_REIMP__scalar
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		return 1;
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		NSInteger i;
		i = (REIMP(NSInteger)(IMP)objc_msgSend(receiver, @selector(supermethodOfCurrentBlock)))(receiver, sel);
		return i + 1;
	}];
	
	STAssertEquals((NSInteger)objc_msgSend([NSObject object], sel), (NSInteger)2, @"");
}

- (void)test_REIMP__CGRect
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver, sel);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Check rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, sel, string);
		STAssertEqualObjects(string, @"block", @"");
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, sel, @"block");
		STAssertEqualObjects(string, @"string", @"");
	}];
	
	// Call
	objc_msgSend([NSObject object], sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, sel, @"Wow"), string];
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, sel, @"block1"), string];
	}];
	
	// Call
	NSString *string;
	string = objc_msgSend([NSObject object], sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, sel, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, sel, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend([NSObject object], sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod((CGRect){}, receiver, sel, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
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
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_dynamicBlockBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
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

- (void)test_overrideBlockBeforeKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
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

- (void)test_dynamicBlockAfterKVO
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
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_overrideBlockAfterKVO
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
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"block", @"");
}

- (void)test_hasDynamicBlockForInstanceMethod__KVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_hasOverrideBlockForInstanceMethod__KVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_supermethodOfDynamicBlockAddedBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"1"];
	}];
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"2"];
	}];
	
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
	[RETestObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"1"];
	}];
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"2"];
	}];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
}

@end
