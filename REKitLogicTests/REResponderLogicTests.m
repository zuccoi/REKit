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
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		id obj;
		SEL sel = @selector(log);
		NSString *log;
		
		// Make obj
		obj = [[[NSObject alloc] init] autorelease];
		
		// Responds to log method dynamically
		[obj respondsToSelector:sel withKey:nil usingBlock:^NSString*(id receiver) {
//			NSLog(@"obj = %@", obj); // Causes retain cycle. Use receiver.
			NSLog(@"receiver = %@", receiver);
			return @"block1";
		}];
		log = [obj performSelector:sel];
		STAssertEqualObjects(log, @"block1", @"");
		
		// Override dealloc method to check deallocation
		[obj respondsToSelector:@selector(dealloc) withKey:@"dealloc" usingBlock:^(id receiver) {
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"dealloc"])) {
				supermethod(receiver, @selector(dealloc));
			}
			
			// Raise deallocated
			deallocated = YES;
		}];
	}
	
	// Check deallocated
	STAssertTrue(deallocated, @"");
}

- (void)test_overrideHardcodedMethod
{
	__block BOOL deallocated = NO;
	SEL sel;
	
	@autoreleasepool {
		// You can override hardcoded method
		NSString *log;
		RETestObject *obj;
		obj = [RETestObject testObject];
		[obj respondsToSelector:@selector(log) withKey:nil usingBlock:^NSString*(id receiver) {
//			NSLog(@"obj = %@", obj); // Causes retain cycle. Use receiver.
			NSLog(@"receiver = %@", receiver);
			return @"block log";
		}];
		log = [obj log];
		STAssertEqualObjects(log, @"block log", @"");
		
		// The override doesn't affect other instances
		NSString *log2;
		RETestObject *obj2;
		obj2 = [RETestObject testObject];
		log2 = [obj2 log];
		STAssertEqualObjects(log2, @"log", @"");
		
		// Override dealloc method to check deallocation
		[obj respondsToSelector:(sel = @selector(dealloc)) withKey:@"dealloc" usingBlock:^(id receiver) {
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"dealloc"])) {
				supermethod(receiver, sel);
			}
			
			// Raise deallocated
			deallocated = YES;
		}];
	}
	
	STAssertTrue(deallocated, @"");
}

- (void)test_keyOfBlockIsDeallocated
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// Prepare key
		id key;
		key = [[[NSObject alloc] init] autorelease];
		[key respondsToSelector:@selector(dealloc) withKey:@"key" usingBlock:^(id receiver) {
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:@selector(dealloc) forKey:@"key"])) {
				supermethod(receiver, @selector(dealloc));
			}
			
			deallocated = YES;
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

- (void)test_blockIsReleased
{
	SEL sel;
	__block BOOL released = NO;
	
	@autoreleasepool {
		// Make obj
		id obj;
		obj = [[[NSObject alloc] init] autorelease];
		[obj respondsToSelector:(sel = @selector(log)) withKey:@"key" usingBlock:^(id receiver) {
			// Do something
			receiver = receiver;
		}];
		
		// Get block
		id block;
		block = [obj blockForSelector:sel forKey:@"key"];
		[block respondsToSelector:(sel = @selector(release)) withKey:nil usingBlock:^(id receiver) {
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"key"])) {
				supermethod(receiver, sel);
			}
			
			// Update deallocated
			released = YES;
		}];
		[block respondsToSelector:@selector(retain) withKey:nil usingBlock:^(id receiver) {
			STFail(@"");
		}];
		[block respondsToSelector:@selector(copy) withKey:nil usingBlock:^(id receiver) {
			STFail(@"");
		}];
		STAssertEquals(CFGetRetainCount(block), 1L, @"");
	}
	
	// Check
	STAssertTrue(released, @"");
}

- (void)test_allowArguments
{
	id obj;
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block with arguments
	[obj respondsToSelector:@selector(logWithSuffix:) withKey:nil usingBlock:^NSString*(id receiver, NSString *suffix) {
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

- (void)test_blockKey
{
	SEL sel;
	
	// Make block
	void (^block)(id);
	block = ^(id receiver) {
		// Do something
	};
	
	// Add block with key
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	[obj respondsToSelector:(sel = @selector(doSomething)) withKey:@"key" usingBlock:block];
	
	// Check block for key
	STAssertEqualObjects(block, [obj blockForSelector:sel forKey:@"key"], @"");
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
	[obj removeBlockForSelector:@selector(log) forKey:@"key"];
	STAssertFalse([obj respondsToSelector:@selector(log)], @"");
	string = [obj performSelector:@selector(say)];
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[obj removeBlockForSelector:@selector(say) forKey:@"key"];
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
	[obj removeBlockForSelector:@selector(log) forKey:@"key"];
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
	[obj removeBlockForSelector:sel forKey:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel forKey:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel forKey:@"block2"];
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
	[obj respondsToSelector:(sel = @selector(readThis:)) withKey:@"block1" usingBlock:^(id receiver, NSString *string) {
		return string;
	}];
	string = [obj performSelector:sel withObject:@"Read"];
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel forKey:@"block1"];
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
	[obj removeBlockForSelector:sel forKey:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel forKey:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel forKey:@"block2"];
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
	[obj removeBlockForSelector:sel forKey:@"key"];
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
	[obj removeBlockForSelector:sel forKey:@"key"];
	
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
	[obj respondsToSelector:sel withKey:@"logBlock" usingBlock:^(id receiver) {
		NSMutableString *log;
		log = [NSMutableString string];
		
		IMP supermethod;
		supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"logBlock"];
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block1"])) {
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block2"])) {
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block3"])) {
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
	[obj removeBlockForSelector:sel forKey:@"block3"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel forKey:@"block1"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel forKey:@"block2"];
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block1"])) {
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block2"])) {
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
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"block3"])) {
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
	[obj removeBlockForSelector:sel forKey:@"block3"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockForSelector:sel forKey:@"block1"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"log-block2", @"");
	
	// Remove block2
	[obj removeBlockForSelector:sel forKey:@"block2"];
	
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
	[obj respondsToSelector:(sel = @selector(age)) withKey:@"key" usingBlock:^NSUInteger(id receiver) {
		NSUInteger age = 0;
		
		// Get original age
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"key"])) {
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
	[obj respondsToSelector:(sel = @selector(ageAfterYears:)) withKey:@"key" usingBlock:^NSUInteger(id receiver, NSUInteger years) {
		NSUInteger age = 0;
		
		// Get original age
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfBlockForSelector:sel forKey:@"key"])) {
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
	[obj removeBlockForSelector:@selector(log) forKey:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) forKey:@"sayBlock"];
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
	[obj removeBlockForSelector:@selector(log) forKey:@"logBlock"];
	[obj removeBlockForSelector:@selector(say) forKey:@"sayBlock"];
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
	
	// Try to set obj conformable with nil-key
	[obj setConformable:YES toProtocol:protocol withKey:nil];
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
		[key respondsToSelector:@selector(dealloc) withKey:@"key" usingBlock:^(id receiver) {
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfBlockForSelector:@selector(dealloc) forKey:@"key"])) {
				supermethod(receiver, @selector(dealloc));
			}
			
			deallocated = YES;
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

@end
