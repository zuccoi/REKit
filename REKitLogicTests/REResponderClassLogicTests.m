/*
 REResponderClassLogicTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderClassLogicTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderClassLogicTests

- (void)_resetClasses
{
	// Reset all classes
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		// Remove blocks
		NSDictionary *blocks;
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_blocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForSelector:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_instaceBlocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
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

- (void)test_respondsToUnimplementedMethod
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	}];
	
	// Responds to selector?
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	
	// Call the sel
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block", @"");
	
	// Don't affect to instances
	id obj;
	obj = [NSObject object];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_overrideHardcodedMethod
{
	SEL selector = @selector(object);
	
	// Override
	[RETestObject setBlockForClassMethod:selector key:nil block:^(id receiver) {
		RETestObject *obj;
		obj = [[[RETestObject alloc] init] autorelease];
		obj.name = @"overridden";
		return obj;
	}];
	
	RETestObject *obj;
	obj = [RETestObject object];
	STAssertEqualObjects(obj.name, @"overridden", @"");
}

- (void)test_dynamicBlockAffectSubclasses
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Responds to log method dynamically
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// NSNumber responds to log method?
	STAssertTrue([[NSNumber class] respondsToSelector:sel], @"");
	
	// Call the sel
	log = objc_msgSend([NSNumber class], sel);
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[NSObject removeBlockForSelector:sel key:@"key"];
	STAssertFalse([NSNumber respondsToSelector:sel], @"");
}

- (void)test_dynamicBlockAffectSubclassesConnectedToForwardingMethod
{
	SEL sel = _cmd;
	
	// Add block
	[RETestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"RESubTestObject";
	}];
	
	// Remove block
	[RETestObject removeBlockForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForSelector:sel key:@"key"];
	STAssertEquals([RETestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([RESubTestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	// Add block to NSObject
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"block", @"");
}

- (void)test_overrideBlockAffectSubclasses
{
	SEL sel = @selector(version);
	NSInteger version;
	
	// Override +[NSObject version]
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return 3;
	}];
	
	// Check version of NSArray
	version = [NSArray version];
	STAssertEquals(version, (NSInteger)3, @"");
	
	// Remove the block
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Check version of NSArray
	version = [NSArray version];
	STAssertEquals(version, (NSInteger)0, @"");
}

- (void)test_dynamicBlockDoesNotAffectSuperclass
{
	SEL selector = @selector(log);
	
	// Override
	[RETestObject setBlockForClassMethod:selector key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// NSString responds to log methods?
	STAssertFalse([NSString respondsToSelector:selector], @"");
	STAssertEquals([NSString methodForSelector:selector], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_overrideBlockDoesNotAffectSuperclass
{
	SEL selector = @selector(integerWithInteger:);
	
	// Override
	[RESubTestObject setBlockForClassMethod:selector key:nil block:^(id receiver, NSInteger integer) {
		return integer + 3;
	}];
	
	STAssertEquals((NSInteger)objc_msgSend([RETestObject class], selector, 2), (NSInteger)2, @"");
}

- (void)test_dynamicBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(subRect);
	
	// Add subRect method
	[RETestObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return CGRectZero;
	}];
	
	// Get rect
	CGRect rect;
	rect = [RESubTestObject subRect];
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_overrideBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(theRect);
	
	// Override theRect
	[RETestObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return CGRectZero;
	}];
	
	// Get rect
	CGRect rect;
	rect = [RESubTestObject theRect];
	STAssertEquals(rect, CGRectMake(100.0, 200.0, 300.0, 400.0), @"");
}

- (void)test_addDynamicBlockToSubclassesOneByOne
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"NSObject";
	}];
	[RETestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"RESubTestObject";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"RETestObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"RESubTestObject", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"RESubTestObject", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"NSObject", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_overridingLastBlockUpdatesSubclasses
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block";
	}];
	[RETestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block";
	}];
	[RESubTestObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		return @"block";
	}];
	
	// Remove block of RETestObject
	[RETestObject removeBlockForSelector:sel key:@"key"];
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForSelector:sel key:@"key"];
	
	// Override block of NSObject
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"overridden", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_overrideLastBlockWithSameBlock
{
	SEL sel = _cmd;
	
	// Make block
	NSString *(^block)(Class receiver);
	block = ^(Class receiver) {
		return @"block";
	};
	
	// Set block
	[NSObject setBlockForClassMethod:sel key:@"key" block:block];
	[RETestObject setBlockForClassMethod:sel key:@"key" block:block];
	[RESubTestObject setBlockForClassMethod:sel key:@"key" block:block];
	
	// Remove block
	[RETestObject removeBlockForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForSelector:sel key:@"key"];
	
	// Override block
	[NSObject setBlockForClassMethod:sel key:@"key" block:block];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_addDynamicBlockToSubclasses
{
	SEL sel = _cmd;
	
	// Add block
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		[aClass setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"block", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"block", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject class], sel), @"block", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_receiverIsClass
{
	SEL sel = @selector(version);
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		STAssertEquals(receiver, [NSObject class], @"");
	}];
	[NSObject version];
}

- (void)test_receiverCanBeSubclass
{
	SEL sel = @selector(version);
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		STAssertEquals(receiver, [NSArray class], @"");
	}];
	[NSArray version];
}

- (void)test_canPsssReceiverAsKey
{
	SEL selector = @selector(log);
	NSString *log;
	
	// Add log method
	[NSObject setBlockForClassMethod:selector key:[NSObject class] block:^(id receiver) {
		return @"block";
	}];
	log = objc_msgSend([NSObject class], selector);
	
	// Check log
	STAssertEqualObjects(log, @"block", @"");
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
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Add log method
		[NSObject setBlockForClassMethod:selector key:@"key1" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[NSObject setBlockForClassMethod:selector key:@"key2" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Remove blocks
		[NSObject removeBlockForSelector:selector key:@"key2"];
		STAssertFalse(isContextDeallocated, @"");
		[NSObject removeBlockForSelector:selector key:@"key1"];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
}

- (void)test_allowArguments
{
	SEL selector = @selector(logWithSuffix:);
	NSString *log;
	
	// Add block
	[NSObject setBlockForClassMethod:selector key:nil block:^(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call the method
	log = objc_msgSend([NSObject class], selector, @"suffix");
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Check rect
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject class], sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	SEL selector = @selector(doSomething);
	__block BOOL called = NO;
	
	// Add block
	[NSObject setBlockForClassMethod:selector key:nil block:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	IMP imp;
	imp = [NSObject methodForSelector:selector];
	(REIMP(void)imp)([NSObject class], selector);
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForSelector_forKey
{
	SEL selector = @selector(log);
	
	// Add block
	[NSObject setBlockForClassMethod:selector key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Has block?
	STAssertTrue([NSObject hasBlockForSelector:selector key:@"key"], @"");
	
	// Remove block
	[NSObject removeBlockForSelector:selector key:@"key"];
	
	// Has block?
	STAssertFalse([NSObject hasBlockForSelector:selector key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Add block for log method with key
	[NSObject setBlockForClassMethod:@selector(log) key:@"key" block:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[NSObject setBlockForClassMethod:@selector(say) key:@"key" block:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = objc_msgSend([NSObject class], @selector(log));
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = objc_msgSend([NSObject class], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[NSObject removeBlockForSelector:@selector(log) key:@"key"];
	STAssertFalse([NSObject respondsToSelector:@selector(log)], @"");
	string = objc_msgSend([NSObject class], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[NSObject removeBlockForSelector:@selector(say) key:@"key"];
	STAssertFalse([NSObject respondsToSelector:@selector(say)], @"");
}

- (void)test_stackOfDynamicBlocks
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Responds?
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	
	// Add block1
	[NSObject setBlockForClassMethod:sel key:@"block1" block:^(id receiver) {
		return @"block1";
	}];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[NSObject setBlockForClassMethod:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[NSObject setBlockForClassMethod:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[NSObject removeBlockForSelector:sel key:@"block3"];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[NSObject removeBlockForSelector:sel key:@"block1"];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[NSObject removeBlockForSelector:sel key:@"block2"];
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([NSObject methodForSelector:sel], [RETestObject methodForSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
}

- (void)test_recoonectedToForwardingMethod
{
	SEL sel = @selector(readThis:);
	NSString *string = nil;
	
	[NSObject setBlockForClassMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return string;
	}];
	string = objc_msgSend([NSObject class], sel, @"Read");
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[NSObject removeBlockForSelector:sel key:@"block1"];
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_stackOfOverrideBlocks
{
	SEL sel = @selector(stringWithString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForClassMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Call block1
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"block1", @"");
	
	// Add block2
	[NSString setBlockForClassMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call block2
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Add block3
	[NSString setBlockForClassMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		return @"block3";
	}];
	
	// Call block3
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"block3", @"");
	
	// Remove block3
	[NSString removeBlockForSelector:sel key:@"block3"];
	
	// Call block2
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block1
	[NSString removeBlockForSelector:sel key:@"block1"];
	
	// Call block2
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block2
	[NSString removeBlockForSelector:sel key:@"block2"];
	
	// Call original
	STAssertTrue([[NSString class] respondsToSelector:sel], @"");
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return @"block1";
	}];
	
	// Override the block
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		return @"block2";
	}];
	
	// Get log
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	SEL sel = @selector(stringWithString:);
	
	// Override
	[NSString setBlockForClassMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Override block
	[NSString setBlockForClassMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Remove block
	[NSString removeBlockForSelector:sel key:@"key"];
	
	// Call original
	NSString *string;
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	for (Class cls in @[[NSObject class], [NSObject class]]) {
		[cls setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

- (void)test_canShareBlock
{
	SEL sel = _cmd;
	
	// Share block
	for (Class cls in @[[NSObject class], [NSObject class], [RETestObject class]]) {
		[cls setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	
	// Remove block from NSObject
	[[NSObject class] removeBlockForSelector:sel key:@"key"];
	STAssertFalse([NSObject respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([RETestObject class], sel), @"block", @"");
	
	// Remove block from RETestObject
	[[RETestObject class] removeBlockForSelector:sel key:@"key"];
	STAssertFalse([RETestObject respondsToSelector:sel], @"");
}

- (void)test_canPassAlreadyExistBlock
{
	SEL sel = @selector(log);
	
	// Make block
	NSString *(^block)(Class receiver);
	block = ^(Class receiver) {
		return @"block";
	};
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:@"key" block:block];
	
	// Call
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	STAssertFalse([NSObject respondsToSelector:sel], @"");
}

- (void)test_supermethodPointsToNil
{
	SEL sel = @selector(log);
	
	// Add block
	[NSString setBlockForClassMethod:sel key:nil block:^(id receiver) {
		// Get supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		STAssertNil((id)supermethod, @"");
	}];
	
	// Call
	objc_msgSend([NSString class], sel);
}

- (void)test_supermethodPointsToOriginalMethod
{
	SEL sel = @selector(version);
	__block BOOL called = NO;
	
	// Get originalMethod
	IMP originalMethod;
	originalMethod = [NSObject methodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		// supermethod
		NSInteger res = -1;
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, originalMethod, @"");
		
		called = YES;
	}];
	
	// Call
	[NSObject version];
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass
{
	SEL sel = @selector(version);
	__block BOOL called = NO;
	
	[NSArray setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		NSInteger res = -1;
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, [NSObject methodForSelector:sel], @"");
		
		called = YES;
	}];
	
	// Call
	[NSArray version];
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToInstancesBlock
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Add instances block
	IMP imp;
	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
	}];
	imp = [NSObject instanceMethodForSelector:sel];
	
	STAssertTrue([NSObject methodForSelector:sel] != imp, @"");
	
	// Add class block
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([NSObject class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToInstancesBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Add instances block
	[NSObject setBlockForInstanceMethodForSelector:sel key:nil block:^(id receiver) {
	}];
	
	// Add class block
	[RETestObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject class], sel);
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
	[[obj class] setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([obj class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToObjectBlockOfSuperclass
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
	[RETestObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertNil((id)supermethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassMethodOfSuperclass
{
	SEL sel = @selector(version);
	__block BOOL called = NO;
	
	// Override
	[RETestObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfCurrentBlock], [NSObject methodForSelector:sel], @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToClassBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = YES;
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
	}];
	
	// Get imp
	IMP imp;
	imp = [NSObject methodForSelector:sel];
	
	// Add block
	[RETestObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// Check supermethod
		STAssertEquals([receiver supermethodOfCurrentBlock], imp, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject class], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodOfSubclass
{
	SEL sel = @selector(version);
	NSInteger version;
	
	// Record original version of NSArray
	NSInteger originalVersion;
	originalVersion = [NSArray version];
	
	// Override version
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		// supermethod
		NSInteger res = -1;
		typedef NSInteger (*NSInteger_IMP)(id, SEL, ...);
		NSInteger_IMP supermethod;
		if ((supermethod = (NSInteger_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		return res;
	}];
	
	// Get version of NSArray
	version = [NSArray version];
	STAssertEquals(version, originalVersion, @"");
	
	// Remove the block
	[NSObject removeBlockForSelector:sel key:@"key"];
	version = [NSArray version];
	STAssertEquals(version, originalVersion, @"");
}

- (void)test_supermethodOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForClassMethod:sel key:@"block1" block:^(id receiver) {
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
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[NSObject setBlockForClassMethod:sel key:@"block2" block:^(id receiver) {
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
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[NSObject setBlockForClassMethod:sel key:@"block3" block:^NSString*(id receiver) {
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
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[NSObject removeBlockForSelector:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[NSObject removeBlockForSelector:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[NSObject removeBlockForSelector:sel key:@"block2"];
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	SEL sel = @selector(stringWithString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForClassMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block1"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string-block1", @"");
	
	// Add block2
	[NSString setBlockForClassMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block2"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Add block3
	[NSString setBlockForClassMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block3"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2-block3", @"");
	
	// Remove block3
	[NSString removeBlockForSelector:sel key:@"block3"];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Remove block1
	[NSString removeBlockForSelector:sel key:@"block1"];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string-block2", @"");
	
	// Remove block2
	[NSString removeBlockForSelector:sel key:@"block2"];
	
	// Call
	string = objc_msgSend([NSString class], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel = @selector(version);
	
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		NSInteger version = -1;
		
		// Get original version
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			version = (NSInteger)supermethod(receiver, sel);
		}
		
		// Increase version
		version++;
		
		return version;
	}];
	
	// Call
	NSInteger version;
	version = [NSObject version];
	STAssertEquals(version, (NSInteger)1, @"");
}

- (void)test_supermethodWithArgumentReturningScalar
{
	SEL sel = @selector(integerWithInteger:);
	
	// Override
	[RETestObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger intg = -1;
		
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			intg = (NSInteger)supermethod(receiver, sel, integer);
		}
		
		// Increase inteer
		intg++;
		
		return intg;
	}];
	
	// Call
	NSInteger integer;
	integer = [RETestObject integerWithInteger:3];
	STAssertEquals(integer, (NSInteger)4, @"");
}

- (void)test_supermethodReturningStructure
{
	SEL sel = @selector(theRect);
	
	[RETestObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		// supermethod
		CGRect res;
		typedef CGRect (*CGRect_IMP)(id, SEL, ...);
		CGRect_IMP supermethod;
		if ((supermethod = (CGRect_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Inset
		return CGRectInset(res, 10.0, 20.0);
	}];
	
	// Get rect
	CGRect rect;
	rect = [RETestObject theRect];
	STAssertEquals(rect, CGRectMake(110.0, 220.0, 280.0, 360.0), @"");
}

- (void)test_superBlockReturningStructure
{
	SEL sel = @selector(rect);
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		CGRect rect;
		rect = RESupermethodStret(CGRectZero, receiver, sel);
		
		// Modify rect
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Get rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject class], sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_supermethodReturningVoid
{
	SEL sel = @selector(sayHello);
	__block BOOL called = NO;
	[RETestObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
			called = YES;
		}
	}];
	[RETestObject sayHello];
	
	STAssertTrue(called, @"");
}

- (void)test_getSupermethodFromOutsideOfBlock
{
	IMP supermethod;
	supermethod = [NSObject supermethodOfCurrentBlock];
	STAssertNil((id)supermethod, @"");
}

- (void)test_removeBlockForSelector_key
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(id receiver) {
		// Check receiver
		STAssertTrue(receiver == [NSObject class], @"");
		
		return @"block";
	}];
	
	// Remove block
	[NSObject removeBlockForSelector:sel key:@"key"];
	
	// Responds?
	STAssertFalse([[NSObject class] respondsToSelector:sel], @"");
	
	// Check imp
	IMP imp;
	imp = [NSObject methodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_removeCurrentBlock
{
	SEL sel = @selector(doSomething);
	
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	STAssertTrue([NSObject respondsToSelector:sel], @"");
	objc_msgSend([NSObject class], sel);
	STAssertFalse([NSObject respondsToSelector:sel], @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Add block1
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		[receiver removeCurrentBlock];
		return @"block1-";
	}];
	
	// Add block2
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel)];
		}
		
		[str appendString:@"block2"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend([NSObject class], sel);
	STAssertEqualObjects(string, @"block2", @"");
}

- (void)test_canCallRemoveCurrentBlockFromOutsideOfBlock
{
	SEL sel = @selector(doSomething);
	
	// Call removeCurrentBlock
	STAssertNoThrow([NSObject removeCurrentBlock], @"");
	
	// Add doSomething method
	[NSObject setBlockForClassMethod:sel key:@"key" block:^(Class receiver) {
		// Do something
	}];
	
	// Call removeCurrentBlock
	STAssertNoThrow([NSObject removeCurrentBlock], @"");
	
	// Check doSomething method
	STAssertTrue([NSObject respondsToSelector:sel], @"");
}

- (void)test_doNotChangeClass
{
	Class cls;
	cls = [NSMutableString class];
	
	[NSMutableString setBlockForClassMethod:@selector(stringWithString:) key:nil block:^(id receiver, NSString *string) {
		// Do something
	}];
	
	// Check class
	STAssertEquals([NSMutableString class], cls, @"");
	STAssertEquals([NSMutableString superclass], [NSString class], @"");
}

- (void)test_setConformableToProtocol
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	id obj;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	obj = [NSObject object];
	
	// Check
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Set NSObject conformable to protocol
	[NSObject setConformable:YES toProtocol:protocol key:key];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Set NSObject not-conformable to protocol
	[NSObject setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__conformsToIncorporatedProtocols
{
	id obj;
	obj = [NSObject object];
	
	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__canNotRemoveIncorporatedProtocol
{
	id obj;
	obj = [NSObject object];
	
	// Set NSObject conformable to NSSecureCoding
	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	
	// Set NSobject not conformable to NSCoding
	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__managesProtocolsBySpecifiedProtocol
{
	id obj;
	obj = [NSObject object];
	
	// Set NSObject conformable to NSSecureCoding and NSCoding then remove NSSecureCoding
	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
	[NSObject setConformable:NO toProtocol:@protocol(NSSecureCoding) key:@"key"];
	STAssertTrue(![NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue(![obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue(![RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue(![[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set NSObject conformable to NSSecureCoding and NSCoding then remove NSCoding
	[NSObject setConformable:YES toProtocol:@protocol(NSSecureCoding) key:@"key"];
	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:@"key"];
	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:@"key"];
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSSecureCoding)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__withNilKey
{
	id obj;
	obj = [NSObject object];
	
	// Set conformable
	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:nil];
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__withInvalidArguments
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	id obj;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	obj = [NSObject object];
	
	// Try to set NSObject conformable with nil-protocol
	[NSObject setConformable:YES toProtocol:nil key:key];
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	
	// Set NSObject conformable to protocol
	[NSObject setConformable:YES toProtocol:protocol key:key];
	
	// Try to set NSObject not-conformable with nil-protocol
	[NSObject setConformable:NO toProtocol:nil key:key];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Try to set NSObject not-conformable with nil-key
	[NSObject setConformable:NO toProtocol:protocol key:nil];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Set NSObject not-conformable
	[NSObject setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__stacksKeys
{
	// Make elements
	Protocol *protocol;
	NSString *key;
	id obj;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	obj = [NSObject object];
	
	// Set NSObject conformable to the protocol with key
	[NSObject setConformable:YES toProtocol:protocol key:key];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Set NSObject conformable to the protocol with other key
	[NSObject setConformable:YES toProtocol:protocol key:@"OtherKey"];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Try to set NSObject not-conformable to the protocol
	[NSObject setConformable:NO toProtocol:protocol key:@"OtherKey"];
	STAssertTrue([NSObject conformsToProtocol:protocol], @"");
	STAssertTrue([obj conformsToProtocol:protocol], @"");
	STAssertTrue([RETestObject conformsToProtocol:protocol], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:protocol], @"");
	
	// Set NSObject not-conformable to the protocol
	[NSObject setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__doesNotStackSameKeyForAProtocol
{
	Protocol *protocol;
	NSString *key;
	id obj;
	protocol = @protocol(NSCopying);
	key = NSStringFromSelector(_cmd);
	obj = [NSObject object];
	
	// Set NSObject conformable to the protocol
	[NSObject setConformable:YES toProtocol:protocol key:key];
	[NSObject setConformable:YES toProtocol:protocol key:key];
	[NSObject setConformable:NO toProtocol:protocol key:key];
	STAssertFalse([NSObject conformsToProtocol:protocol], @"");
	STAssertFalse([obj conformsToProtocol:protocol], @"");
	STAssertFalse([RETestObject conformsToProtocol:protocol], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:protocol], @"");
}

- (void)test_setConformableToProtocol__allowsSameKeyForOtherProtocol
{
	// Get elements
	NSString *key;
	id obj;
	key = NSStringFromSelector(_cmd);
	obj = [NSObject object];
	
	// Set obj conformable to NSCopying and NSCoding
	[NSObject setConformable:YES toProtocol:@protocol(NSCopying) key:key];
	[NSObject setConformable:YES toProtocol:@protocol(NSCoding) key:key];
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCopying
	[NSObject setConformable:NO toProtocol:@protocol(NSCopying) key:key];
	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertTrue([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertTrue([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
	
	// Set obj not-conformable to NSCoding
	[NSObject setConformable:NO toProtocol:@protocol(NSCoding) key:key];
	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([obj conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCopying)], @"");
	STAssertFalse([NSObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertFalse([obj conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertFalse([RETestObject conformsToProtocol:@protocol(NSCoding)], @"");
	STAssertFalse([[RETestObject object] conformsToProtocol:@protocol(NSCoding)], @"");
}

- (void)test_setConformableToProtocol__keyIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [NSObject object];
		[key setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			deallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Set NSObject conformable to NSCopying
		[NSObject setConformable:YES toProtocol:@protocol(NSCopying) key:key];
		
		// Reset
		[NSObject setConformable:NO toProtocol:@protocol(NSCopying) key:key];
	}
	
	// Check
	STAssertTrue(deallocated, @"");
}

- (void)test_respondsToSelector__callWithNil
{
	// Make obj
	BOOL responds;
	STAssertNoThrow(responds = [NSObject respondsToSelector:nil], @"");
	STAssertFalse(responds, @"");
}

- (void)test_conformsToProtocol__callWithNil
{
	// Make obj
	BOOL conforms;
	STAssertNoThrow(conforms = [NSObject conformsToProtocol:nil], @"");
	STAssertFalse(conforms, @"");
}

- (void)test_REIMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		called = YES;
	}];
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		(REIMP(void)[receiver supermethodOfCurrentBlock])(receiver, sel);
	}];
	
	// Call
	objc_msgSend([NSObject class], sel);
	STAssertTrue(called, @"");
}

- (void)test_REIMP__id
{
	SEL sel = _cmd;
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return @"hello";
	}];
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		NSString *res;
		res = (REIMP(id)[receiver supermethodOfCurrentBlock])(receiver, sel);
		return res;
	}];
	
	STAssertEqualObjects(objc_msgSend([NSObject class], sel), @"hello", @"");
}

- (void)test_REIMP__scalar
{
	SEL sel = _cmd;
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		return 1;
	}];
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		NSInteger i;
		i = (REIMP(NSInteger)[receiver supermethodOfCurrentBlock])(receiver, sel);
		return i + 1;
	}];
	
	STAssertEquals((NSInteger)objc_msgSend([NSObject class], sel), (NSInteger)2, @"");
}

- (void)test_REIMP__CGRect
{
	SEL sel = _cmd;
	
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(CGRect)supermethod)(receiver, sel);
		}
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		CGRect rect;
		rect = (REIMP(CGRect)[receiver supermethodOfCurrentBlock])(receiver, sel);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Check rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject class], sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(void, receiver, sel, string);
		STAssertEqualObjects(string, @"block", @"");
	}];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(void, receiver, sel, @"block");
		STAssertEqualObjects(string, @"string", @"");
	}];
	
	// Call
	objc_msgSend([NSObject class], sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(id, receiver, sel, @"Wow"), string];
	}];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(id, receiver, sel, @"block1"), string];
	}];
	
	// Call
	NSString *string;
	string = objc_msgSend([NSObject class], sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(NSInteger, receiver, sel, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	}];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(NSInteger, receiver, sel, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend([NSObject class], sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethodStret((CGRect){}, receiver, sel, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	
	// Add block
	[NSObject setBlockForClassMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethodStret(CGRectZero, receiver, sel, origin, size);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		return rect;
	}];
	
	// Call
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject class], sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

@end
