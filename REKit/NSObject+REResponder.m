/*
 REResponder.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "NSObject+REResponder.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kProtocolsKey = @"REResponder_protocols";
static NSString* const kBlocksKey = @"REResponder_blocks";
static NSString* const kBlockKey = @"block";
static NSString* const kSignatureKey = @"signature";


// BlockDescriptor
struct BlockDescriptor
{
	unsigned long reserved;
	unsigned long size;
	void *rest[1];
};

// Block
struct Block
{
	void *isa;
	int flags;
	int reserved;
	void *invoke;
	struct BlockDescriptor *descriptor;
};

// Flags of Block
enum {
	BLOCK_HAS_COPY_DISPOSE =	(1 << 25),
	BLOCK_HAS_CTOR =			(1 << 26), // helpers have C++ code
	BLOCK_IS_GLOBAL =			(1 << 28),
	BLOCK_HAS_STRET =			(1 << 29), // IFF BLOCK_HAS_SIGNATURE
	BLOCK_HAS_SIGNATURE =		(1 << 30), 
};


//--------------------------------------------------------------//
#pragma mark -- Functions --
//--------------------------------------------------------------//

static const char* RESBlockGetSignature(id _block)
{
	// Get descriptor of block
	struct BlockDescriptor *descriptor;
	struct Block *block;
	block = (void*)_block;
	descriptor = block->descriptor;
	
	// Get index of rest
	int index = 0;
	if (block->flags & BLOCK_HAS_COPY_DISPOSE) {
		index += 2;
	}
	
	return descriptor->rest[index];
}

static void* RESBlockGetImplementation(id block)
{
	return ((struct Block*)block)->invoke;
}

static void RESLogSignature(NSMethodSignature *signature)
{
	NSMutableString *log;
	log = [NSMutableString string];
	[log appendString:[NSString stringWithCString:[signature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (int i = 0; i < [signature numberOfArguments]; i++) {
		[log appendString:[NSString stringWithCString:[signature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	
	NSLog(@"signature = %@", log);
}

#pragma mark -


@interface NSInvocation ()
- (void)invokeUsingIMP:(IMP)imp;
@end

#pragma mark -


@implementation NSObject (REResponder)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

+ (void)load
{
	// Exchange methods…
	
	// conformsToProtocol:
	[self exchangeInstanceMethodForSelector:@selector(conformsToProtocol:) withForSelector:@selector(RESX_conformsToProtocol:)];
	
	// respondsToSelector:
	[self exchangeInstanceMethodForSelector:@selector(respondsToSelector:) withForSelector:@selector(RESX_respondsToSelector:)];
	
	// methodSignatureForSelector:
	[self exchangeInstanceMethodForSelector:@selector(methodSignatureForSelector:) withForSelector:@selector(RESX_methodSignatureForSelector:)];
	
	// forwardInvocation:
	[self exchangeInstanceMethodForSelector:@selector(forwardInvocation:) withForSelector:@selector(RESX_forwardInvocation:)];
	
	// dealloc
	[self exchangeInstanceMethodForSelector:@selector(dealloc) withForSelector:@selector(RESX_dealloc)];
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSMutableSet*)RES_protocols
{
	// Get protocols
	NSMutableSet *protocols;		// {(protocolName, ...)}
	@synchronized (self) {
		protocols = [self associatedValueForKey:kProtocolsKey];
		if (!protocols) {
			protocols = [NSMutableSet set];
			[self associateValue:protocols forKey:kProtocolsKey policy:OBJC_ASSOCIATION_RETAIN];
		}
	}
	
	return protocols;
}

- (NSMutableDictionary*)RES_blocks
{
	// Get blocks
	NSMutableDictionary *blocks;		// {selectorName : {"block":id, "signature":NSMethodSignature}}
	@synchronized (self) {
		blocks = [self associatedValueForKey:kBlocksKey];
		if (!blocks) {
			blocks = [NSMutableDictionary dictionary];
			[self associateValue:blocks forKey:kBlocksKey policy:OBJC_ASSOCIATION_RETAIN];
		}
	}
	
	return blocks;
}

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (void)RESX_dealloc
{
	// Release protocols
	[self associateValue:nil forKey:kProtocolsKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// Release blocks
	NSMutableDictionary *blocks;
	blocks = [self associatedValueForKey:kBlocksKey];
	while ([blocks count]) {
		[self removeBlockForSelector:NSSelectorFromString([[blocks allKeys] lastObject])];
	}
	[self associateValue:nil forKey:kBlocksKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// original
	[self RESX_dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Responds --
//--------------------------------------------------------------//

- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol
{
	// Filter
	if (!protocol) {
		return;
	}
	
	// Update RES_protocols
	@synchronized (self) {
		// Get name of protocol
		NSString *name;
		name = NSStringFromProtocol(protocol);
		
		// Add or remove protocol
		if (flag) {
			[[self RES_protocols] addObject:name];
		}
		else {
			[[self RES_protocols] removeObject:name];
		}
	}
}

- (void)respondsToSelector:(SEL)selector usingBlock:(id)block
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(selector);
	
	// Make signature
	NSMethodSignature *signature;
	NSMutableString *objCTypes;
	NSMethodSignature *blockSignature;
	blockSignature = [NSMethodSignature signatureWithObjCTypes:RESBlockGetSignature(block)];
	objCTypes = [NSMutableString stringWithFormat:@"%@@:", [NSString stringWithCString:[blockSignature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 1; i < [blockSignature numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[blockSignature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	signature = [NSMethodSignature signatureWithObjCTypes:[objCTypes cStringUsingEncoding:NSUTF8StringEncoding]];
	if (!signature) {
		return;
	}
	
	// Make dict
	NSDictionary *dict;
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
		Block_copy(block), kBlockKey,
		signature, kSignatureKey,
		nil];
	
	// Set dict to blocks
	@synchronized (self) {
		// Remove old one
		[self removeBlockForSelector:selector];
		
		// Set dict
		[[self RES_blocks] setObject:dict forKey:selectorName];
	}
}

- (id)blockForSelector:(SEL)selector
{
	return [[[self RES_blocks] objectForKey:NSStringFromSelector(selector)] objectForKey:kBlockKey];
}

- (void)removeBlockForSelector:(SEL)selector
{
	// Filter
	if (!selector) {
		return;
	}
	
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(selector);
	
	@synchronized (self) {
		// Get blocks
		NSMutableDictionary *blocks;
		blocks = [self RES_blocks];
		
		// Get dict
		NSDictionary *dict;
		dict = [blocks objectForKey:selectorName];
		if (!dict) {
			return;
		}
		
		// Release block
		Block_release([dict objectForKey:kBlockKey]);
		
		// Remove dict
		[blocks removeObjectForKey:selectorName];
	}
}

//--------------------------------------------------------------//
#pragma mark -- Messaging --
//--------------------------------------------------------------//

- (BOOL)RESX_conformsToProtocol:(Protocol*)aProtocol
{
	// Handle registered protocol
	@synchronized (self) {
		if ([[self RES_protocols] containsObject:NSStringFromProtocol(aProtocol)]) {
			return YES;
		}
	}
	
	// original
	return [self RESX_conformsToProtocol:aProtocol];
}

- (BOOL)RESX_respondsToSelector:(SEL)aSelector
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(aSelector);
	
	// Hadle registered selector
	@synchronized (self) {
		if ([[self RES_blocks] objectForKey:selectorName]) {
			return YES;
		}
	}
	
	// original
	return [self RESX_respondsToSelector:aSelector];
}

- (NSMethodSignature*)RESX_methodSignatureForSelector:(SEL)aSelector
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(aSelector);
	
	// Handle registered selector
	@synchronized (self) {
		NSDictionary *dict;
		dict = [[self RES_blocks] objectForKey:selectorName];
		if (dict) {
			return [dict objectForKey:kSignatureKey];
		}
	}
	
	// original
	return [self RESX_methodSignatureForSelector:aSelector];
}

- (void)RESX_forwardInvocation:(NSInvocation*)invocation
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector([invocation selector]);
	
	// Handle registered selector
	@synchronized (self) {
		// Get dict
		NSDictionary *dict;
		dict = [[self RES_blocks] objectForKey:selectorName];
		if (!dict) {
			goto ORIGINAL;
		}
		
		// Get elements
		id block;
		NSMethodSignature *signature;
		NSUInteger argc;
		block = [dict objectForKey:kBlockKey];
		if (!block) {
			goto ORIGINAL;
		}
		signature = [invocation methodSignature];
		argc = [signature numberOfArguments];
		
		// Make blockInvocation
		NSInvocation *blockInvocation;
		const char *argType;
		NSUInteger length;
		void *argBuffer;
		NSData *argument;
		blockInvocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:RESBlockGetSignature(block)]];
		[blockInvocation setTarget:block];
		for (NSInteger i = 2; i < argc; i++) {
			// Get argType and length
			argType = [signature getArgumentTypeAtIndex:i];
			NSGetSizeAndAlignment(argType, &length, NULL);
			
			// Prepare argBuffer
			argBuffer = malloc(length);
			[invocation getArgument:argBuffer atIndex:i];
			
			// Add argument
			argument = [NSData dataWithBytesNoCopy:argBuffer length:length];
			[blockInvocation setArgument:(void*)[argument bytes] atIndex:(i - 1)];
		}
		
		// Invoke blockInvocation
		[blockInvocation invokeUsingIMP:RESBlockGetImplementation(block)];
		
		// Set return value to invocation
		NSUInteger returnLength;
		returnLength = [signature methodReturnLength];
		if (returnLength > 0) {
			// Get return value
			void *returnBuffer;
			returnBuffer = malloc(returnLength);
			[blockInvocation getReturnValue:returnBuffer];
			
			// Set return value
			NSData *returnData;
			static void *returnDataKey;
			returnData = [NSData dataWithBytesNoCopy:returnBuffer length:returnLength];
			[invocation setReturnValue:(void*)returnData.bytes];
			[invocation associateValue:returnData forKey:&returnDataKey policy:OBJC_ASSOCIATION_RETAIN];
		}
		
		return;
	}
	
	// original
	ORIGINAL: {}
	[self RESX_forwardInvocation:invocation];
}

@end
