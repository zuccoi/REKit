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
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
	// Call the sel
	log = objc_msgSend(obj, sel);
	STAssertEqualObjects(log, @"block", @"");
}

- (void)test_methodOfDynamicBlock
{
	SEL sel = @selector(log);
	id obj = [RESubTestObject object];
	
	// Responds to log method dynamically
	RESetBlock([RESubTestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		return @"overridden";
	});
	
	// Check log
	STAssertEqualObjects([[RETestObject object] log], @"overridden", @"");
}

- (void)test_methodOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Override log method
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
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
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	});
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_receiverOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Set block
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	});
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_dynamicBlockAffectSubclasses
{
	SEL sel = @selector(log);
	
	// Responds to log method dynamically
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"RETestObject";
	});
	RESetBlock([RESubTestObject class], sel, NO, @"key", ^(id receiver) {
		return @"RESubTestObject";
	});
	
	// Remove block
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	STAssertEquals([RETestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([RESubTestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	// Add block to NSObject
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectOtherClasses
{
	SEL sel = @selector(log);
	
	// Override
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		return @"block";
	});
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_dynamicBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(subLog);
	NSString *string;
	
	// Add subRect method
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"overridden";
	});
	
	// Check return string
	string = [[RESubTestObject object] subLog];
	STAssertEqualObjects(string, @"subLog", @"");
}

- (void)test_overrideBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(overrideLog);
	NSString *string;
	
	// Override overrideLog
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"overridden";
	});
	
	// Check returned string
	string = [[RESubTestObject object] overrideLog];
	STAssertEqualObjects(string, @"RESubTestObject", @"");
}

- (void)test_addDynamicBlockToSubclassesOneByOne
{
	SEL sel = _cmd;
	
	// Add _cmd
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"NSObject";
	});
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"RETestObject";
	});
	RESetBlock([RESubTestObject class], sel, NO, @"key", ^(id receiver) {
		return @"RESubTestObject";
	});
	
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
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	RESetBlock([RESubTestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Override block of NSObject
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"overridden";
	});
	
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
	RESetBlock([NSObject class], sel, NO, @"key", block);
	RESetBlock([RETestObject class], sel, NO, @"key", block);
	RESetBlock([RESubTestObject class], sel, NO, @"key", block);
	
	// Remove block
	[RETestObject removeBlockForInstanceMethod:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethod:sel key:@"key"];
	
	// Override block with same block
	RESetBlock([NSObject class], sel, NO, @"key", block);
	
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
		NSString *className;
		className = NSStringFromClass(aClass);
		if ([className isEqualToString:@"NSObject"]
			|| [className isEqualToString:@"RETestObject"]
			|| [className isEqualToString:@"RESubTestObject"]
		){
			RESetBlock(aClass, sel, NO, @"key", ^(id receiver) {
				return @"block";
			});
		}
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
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		return @"private";
	});
	RESetBlock([obj class], sel, NO, nil, ^(id receiver) {
		return @"public";
	});
	
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
	RESetBlock([NSObject class], sel, NO, [NSObject class], ^(id receiver) {
		return @"block";
	});
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
		RESetBlock(context, @selector(dealloc), NO, nil, ^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// supermethod
			RESupermethod(nil, receiver);
		});
		
		// Add log method
		RESetBlock([NSObject class], selector, NO, @"key1", ^(id receiver) {
			id ctx;
			ctx = context;
		});
		
		// Override log method
		RESetBlock([NSObject class], selector, NO, @"key2", ^(id receiver) {
			id ctx;
			ctx = context;
		});
		
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
	RESetBlock([NSObject class], selector, NO, nil, ^(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	});
	
	// Call
	log = objc_msgSend([NSObject object], selector, @"suffix");
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	});
	
	// Check rect
	rect = (RE_IMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	SEL sel = @selector(doSomething);
	__block BOOL called = NO;
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		called = YES;
	});
	
	// Call imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	(RE_IMP(void)imp)([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForInstanceMethod_key
{
	SEL sel = @selector(log);
	
	// Has block?
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		// Do something
	});
	
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
	RESetBlock([NSObject class], @selector(log), NO, @"key", ^(id receiver) {
		return @"log";
	});
	
	// Add block for say method with key
	RESetBlock([NSObject class], @selector(say), NO, @"key", ^(id receiver) {
		return @"say";
	});
	
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
	RESetBlock([NSObject class], sel, NO, @"block1", ^(id receiver) {
		return @"block1";
	});
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	RESetBlock([NSObject class], sel, NO, @"block2", ^NSString*(id receiver) {
		return @"block2";
	});
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	RESetBlock([NSObject class], sel, NO, @"block3", ^NSString*(id receiver) {
		return @"block3";
	});
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
	
	RESetBlock([NSObject class], sel, NO, @"block1", ^(id receiver, NSString *string) {
		return string;
	});
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
	RESetBlock([NSString class], sel, NO, @"block1", ^(id receiver, NSString *string) {
		return @"block1";
	});
	
	// Call block1
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block1", @"");
	
	// Add block2
	RESetBlock([NSString class], sel, NO, @"block2", ^(id receiver, NSString *string) {
		return @"block2";
	});
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Add block3
	RESetBlock([NSString class], sel, NO, @"block3", ^(id receiver, NSString *string) {
		return @"block3";
	});
	
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
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block1";
	});
	
	// Override the block
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block2";
	});
	
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
	RESetBlock([NSString class], sel, NO, @"key", ^(id receiver, NSString *string) {
		return @"block1";
	});
	
	// Override block
	RESetBlock([NSString class], sel, NO, @"key", ^(id receiver, NSString *string) {
		return @"block2";
	});
	
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
		RESetBlock(cls, sel, NO, @"key", ^(id receiver) {
			return @"block";
		});
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
		RESetBlock(cls, sel, NO, @"key", ^(id receiver) {
			return @"block";
		});
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
	
	// Add block
	RESetBlock([NSArray class], sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertNil((id)[receiver supermethodOfCurrentBlock:NULL], @"");
		
		called = YES;
	});
	
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
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfCurrentBlock:NULL], originalMethod, @"");
		
		called = YES;
	});
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add log block to RESubTestObject
	RESetBlock([RESubTestObject class], sel, NO, @"key", ^(id receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfCurrentBlock:NULL], [RETestObject instanceMethodForSelector:sel], @"");
		
		called = YES;
	});
	
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
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		called = YES;
	});
	imp = [NSObject instanceMethodForSelector:sel];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock:NULL])) {
			(RE_IMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, imp, @"");
	});
	
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
	RESetBlock([NSObject class], sel, YES, nil, ^(Class receiver) {
		dirty = YES;
	});
	
	// Add instance method
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		// Check supermethod
		STAssertNil((id)[receiver supermethodOfCurrentBlock:NULL], @"");
	});
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(!dirty, @"");
}

- (void)test_supermethodOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	RESetBlock([NSObject class], sel, NO, @"block1", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block1"];
	});
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	RESetBlock([NSObject class], sel, NO, @"block2", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block2"];
	});
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	RESetBlock([NSObject class], sel, NO, @"block3", ^NSString*(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"-block3"];
	});
	
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
	RESetBlock([NSString class], sel, NO, @"block1", ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, string), @"-block1"];
	});
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1", @"");
	
	// Add block2
	RESetBlock([NSString class], sel, NO, @"block2", ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, string), @"-block2"];
	});
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Add block3
	RESetBlock([NSString class], sel, NO, @"block3", ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(string, receiver, string), @"-block3"];
	});
	
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		return (RESupermethod(0, receiver, sel) + 1);
	});
	
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver, NSUInteger years) {
		return (RESupermethod(years, receiver, years) + 1);
	});
	
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		return CGRectInset(RESupermethod(CGRectZero, receiver, sel), 3.0, 6.0);
	});
	
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock:NULL])) {
			supermethod(receiver, sel);
			called = YES;
		}
	});
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
	RESetBlock(testObj, sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp1;
	imp1 = [testObj methodForSelector:sel];
	
	// Add block to NSObject
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp2;
	imp2 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp3;
	imp3 = [obj methodForSelector:sel];
	
	// Add block to RETestObject
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp4;
	imp4 = [RETestObject instanceMethodForSelector:sel];
	
	// Add block to NSObject
	RESetBlock([obj class], sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp5;
	imp5 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	RESetBlock(obj, sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp6;
	imp6 = [obj methodForSelector:sel];
	
	// Add block to testObj
	RESetBlock(testObj, sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
	IMP imp7;
	imp7 = [testObj methodForSelector:sel];
	
	// Add block to RETestObject
	RESetBlock([testObj class], sel, NO, nil, ^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock:NULL];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(RE_IMP(void)supermethod)(receiver, sel);
		}
	});
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

- (void)test_removeBlockForInstanceMethod_key
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Responds to log method dynamically
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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
	RESetBlock(obj, sel, NO, @"key", ^(id receiver) {
		count++;
	});
	
	// Set instances block
	RESetBlock([NSObject class], sel, NO, @"key", ^(id receiver) {
		STFail(@"");
	});
	
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
	
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		// Remove currentBlock
		RERemoveCurrentBlock();
	});
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	objc_msgSend([NSObject object], sel);
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Add block1
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		RERemoveCurrentBlock();
		return @"block1-";
	});
	
	// Add block2
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"block2"];
	});
	
	// Call
	string = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(string, @"block2", @"");
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
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
	});
	
	// Check class
	STAssertEquals([obj class], class, @"");
	STAssertEquals(object_getClass(obj), class, @"");
}

- (void)test_RE_IMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		called = YES;
	});
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		(RE_IMP(void)[receiver supermethodOfCurrentBlock:NULL])(receiver, sel);
	});
	
	// Call
	objc_msgSend([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_RE_IMP__id
{
	SEL sel = _cmd;
	
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		return @"hello";
	});
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		NSString *res;
		res = (RE_IMP(id)[receiver supermethodOfCurrentBlock:NULL])(receiver, sel);
		return res;
	});
	
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"hello", @"");
}

- (void)test_RE_IMP__scalar
{
	SEL sel = _cmd;
	
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		return 1;
	});
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		NSInteger i;
		i = (RE_IMP(NSInteger)[receiver supermethodOfCurrentBlock:NULL])(receiver, sel);
		return i + 1;
	});
	
	STAssertEquals((NSInteger)objc_msgSend([NSObject object], sel), (NSInteger)2, @"");
}

- (void)test_RE_IMP__CGRect
{
	SEL sel = _cmd;
	
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	});
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver) {
		// supermethod
		CGRect rect;
		rect = RESupermethod(CGRectZero, receiver, sel);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	});
	
	// Check rect
	CGRect rect;
	rect = (RE_IMP(CGRect)objc_msgSend_stret)([NSObject object], sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, string);
		STAssertEqualObjects(string, @"block", @"");
	});
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSString *string) {
		RESupermethod(nil, receiver, @"block");
		STAssertEqualObjects(string, @"string", @"");
	});
	
	// Call
	objc_msgSend([NSObject object], sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, @"Wow"), string];
	});
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(nil, receiver, @"block1"), string];
	});
	
	// Call
	NSString *string;
	string = objc_msgSend([NSObject object], sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	});
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(0, receiver, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	});
	
	// Call
	NSInteger value;
	value = objc_msgSend([NSObject object], sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethod((CGRect){}, receiver, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	});
	
	// Add block
	RESetBlock([NSObject class], sel, NO, nil, ^(id receiver, CGPoint origin, CGSize size) {
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
	rect = (RE_IMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_dynamicBlockAddedBeforeKVO
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
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
	RESetBlock([RETestObject class], sel, NO, nil, ^(id receiver) {
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
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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

- (void)test_hasOverrideBlockAddedBeforeKVO
{
	SEL sel = @selector(log);
	
	// Make obj
	id obj;
	obj = [RETestObject object];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, @"key", ^(id receiver) {
		return @"block";
	});
	
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
	RESetBlock([RETestObject class], sel, NO, @"block1", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"1"];
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, @"block2", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"2"];
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
	RESetBlock([RETestObject class], sel, NO, @"block1", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"1"];
	});
	
	// Start observing
	id observer;
	observer = [NSObject object];
	[obj addObserver:observer forKeyPath:@"name" options:0 context:nil];
	
	// Add block
	RESetBlock([RETestObject class], sel, NO, @"block2", ^(id receiver) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(@"", receiver, sel), @"2"];
	});
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
	
	// Stop observing
	[obj removeObserver:observer forKeyPath:@"name"];
	
	// Check
	STAssertEqualObjects(objc_msgSend(obj, sel), @"log12", @"");
}

@end
