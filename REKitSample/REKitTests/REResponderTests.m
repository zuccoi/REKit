/*
 REResponderTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REResponderTests.h"
#import "REKit.h"


@interface Logger : NSObject
- (NSString*)log;
@end

@implementation Logger
- (NSString*)log
{
	return @"-[Logger log]";
}
@end

#pragma mark -


@implementation REResponderTests

- (void)test_overrideHardcodedMethod
{
	__block BOOL deallocated = NO;
	
	@autoreleasepool {
		// You can override hardcoded method
		NSString *log;
		Logger *obj;
		obj = [[[Logger alloc] init] autorelease];
		[obj respondsToSelector:@selector(log) withBlockName:nil usingBlock:^NSString*(id me) {
//			NSLog(@"obj = %@", obj); // Causes memory leak. Use me.
			return @"block log";
		}];
		log = [obj log];
		STAssertEqualObjects(log, @"block log", @"");
		
		// The override doesn't affect other instances
		NSString *log2;
		Logger *obj2;
		obj2 = [[[Logger alloc] init] autorelease];
		log2 = [obj2 log];
		STAssertEqualObjects(log2, @"-[Logger log]", @"");
		
		// Override dealloc method to check deallocation
		[obj respondsToSelector:@selector(dealloc) withBlockName:@"dealloc" usingBlock:^(id me) {
			// super
			IMP supermethod;
			if ((supermethod = [me supermethodOfBlockNamed:@"dealloc"])) {
				supermethod(me, @selector(dealloc));
			}
			
			// Raise deallocated
			deallocated = YES;
		}];
	}
	
	STAssertTrue(deallocated, @"");
}

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
		[obj respondsToSelector:sel withBlockName:nil usingBlock:^NSString*(id me) {
			return @"block1";
		}];
		log = [obj performSelector:sel];
		STAssertEqualObjects(log, @"block1", @"");
		
		// Override dealloc method to check deallocation
		[obj respondsToSelector:@selector(dealloc) withBlockName:@"dealloc" usingBlock:^(id me) {
			// super
			IMP supermethod;
			if ((supermethod = [me supermethodOfBlockNamed:@"dealloc"])) {
				supermethod(me, @selector(dealloc));
			}
			
			// Raise deallocated
			deallocated = YES;
		}];
	}
	
	// Check deallocated
	STAssertTrue(deallocated, @"");
}

- (void)test_allowArguments
{
	id obj;
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block with arguments
	[obj respondsToSelector:@selector(logWithSuffix:) withBlockName:nil usingBlock:^NSString*(id me, NSString *suffix) {
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
	[obj respondsToSelector:sel withBlockName:@"block" usingBlock:^CGRect(id me, CGPoint origin, CGSize size) {
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

- (void)test_blockName
{
	// Make block
	void (^block)(id);
	block = ^(id me) {
		// Do something
	};
	
	// Add block with name
	id obj;
	obj = [[[NSObject alloc] init] autorelease];
	[obj respondsToSelector:@selector(doSomething) withBlockName:@"name" usingBlock:block];
	
	// Check name of block
	STAssertEqualObjects(block, [obj blockNamed:@"name"], @"");
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
	[obj respondsToSelector:sel withBlockName:@"block1" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withBlockName:@"block2" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withBlockName:@"block3" usingBlock:^NSString*(id me) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockNamed:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockNamed:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockNamed:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_stackOfOverrideBlocks
{
	Logger *obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[Logger alloc] init] autorelease];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Add bock1
	[obj respondsToSelector:sel withBlockName:@"block1" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withBlockName:@"block2" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withBlockName:@"block3" usingBlock:^NSString*(id me) {
		return @"block3";
	}];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[obj removeBlockNamed:@"block3"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[obj removeBlockNamed:@"block1"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[obj removeBlockNamed:@"block2"];
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	id obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block with name
	[obj respondsToSelector:sel withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj respondsToSelector:sel withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockNamed:@"name"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	Logger *obj;
	SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[Logger alloc] init] autorelease];
	
	// Add block with name
	[obj respondsToSelector:sel withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Override the block
	[obj respondsToSelector:sel withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[obj removeBlockNamed:@"name"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]", @"");
}

- (void)test_denyDynamicBlockIfTheNameExistsForOtherSelector
{
	id obj;
	NSString *log;
	BOOL res;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block
	res = [obj respondsToSelector:@selector(log) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	STAssertTrue(res, @"");
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Call log method
	log = [obj performSelector:@selector(log)];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Try to add block
	res = [obj respondsToSelector:@selector(other) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	STAssertFalse(res, @"");
	STAssertFalse([obj respondsToSelector:@selector(other)], @"");
	
	// Call log method
	log = [obj performSelector:@selector(log)];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Remove block
	[obj removeBlockNamed:@"name"];
	STAssertFalse([obj respondsToSelector:@selector(log)], @"");
	
	// Try to add block
	res = [obj respondsToSelector:@selector(other) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"Other";
	}];
	STAssertTrue(res, @"");
	STAssertTrue([obj respondsToSelector:@selector(other)], @"");
	
	// Call other method
	log = [obj performSelector:@selector(other)];
	STAssertEqualObjects(log, @"Other", @"");
}

- (void)test_denyOverrideBlockIfTheNameExistsForOtherSelector
{
	Logger *obj;
	NSString *log;
	BOOL res;
	
	// Make obj
	obj = [[[Logger alloc] init] autorelease];
	
	// Add block
	res = [obj respondsToSelector:@selector(log) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block1";
	}];
	STAssertTrue(res, @"");
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Try to add block
	res = [obj respondsToSelector:@selector(other) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"block2";
	}];
	STAssertFalse(res, @"");
	STAssertFalse([obj respondsToSelector:@selector(other)], @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"block1", @"");
	
	// Remove block
	[obj removeBlockNamed:@"name"];
	STAssertTrue([obj respondsToSelector:@selector(log)], @"");
	
	// Try to add block
	res = [obj respondsToSelector:@selector(other) withBlockName:@"name" usingBlock:^NSString*(id me) {
		return @"Other";
	}];
	STAssertTrue(res, @"");
	STAssertTrue([obj respondsToSelector:@selector(other)], @"");
	
	// Call other method
	log = [obj performSelector:@selector(other)];
	STAssertEqualObjects(log, @"Other", @"");
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]", @"");
}

- (void)test_supermethodOfDynamicBlock
{
	id obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[NSObject alloc] init] autorelease];
	
	// Add block1
	[obj respondsToSelector:sel withBlockName:@"block1" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block1"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withBlockName:@"block2" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block2"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withBlockName:@"block3" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block3"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block3"];
		
		return log;
	}];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockNamed:@"block3"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockNamed:@"block1"];
	
	// Call log method
	log = [obj performSelector:sel];
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[obj removeBlockNamed:@"block2"];
	STAssertFalse([obj respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	Logger *obj;
	__block SEL sel = @selector(log);
	NSString *log;
	
	// Make obj
	obj = [[[Logger alloc] init] autorelease];
	
	// Add block1
	[obj respondsToSelector:sel withBlockName:@"block1" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block1"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]-block1", @"");
	
	// Add block2
	[obj respondsToSelector:sel withBlockName:@"block2" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block2"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]-block1-block2", @"");
	
	// Add block3
	[obj respondsToSelector:sel withBlockName:@"block3" usingBlock:^NSString*(id me) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [me supermethodOfBlockNamed:@"block3"])) {
			[log appendString:supermethod(me, sel)];
		}
		
		// Append my log
		[log appendString:@"-block3"];
		
		return log;
	}];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]-block1-block2-block3", @"");
	
	// Remove block3
	[obj removeBlockNamed:@"block3"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]-block1-block2", @"");
	
	// Remove block1
	[obj removeBlockNamed:@"block1"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]-block2", @"");
	
	// Remove block2
	[obj removeBlockNamed:@"block2"];
	
	// Call log method
	log = [obj log];
	STAssertEqualObjects(log, @"-[Logger log]", @"");
}

@end
