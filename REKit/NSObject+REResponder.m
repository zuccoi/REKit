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
NSString* const REResponderOriginalImplementationBlockName = @"REResponderOriginalImplementationBlockName";
static NSString* const kProtocolsKey = @"REResponder_protocols";
static NSString* const kBlocksKey = @"REResponder_blocks";
static NSString* const kBlockKey = @"block";
static NSString* const kNameKey = @"name";
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

static const char* REBlockGetObjCTypes(id _block)
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

static void* REBlockGetImplementation(id block)
{
	return ((struct Block*)block)->invoke;
}

static void RELogSignature(NSMethodSignature *signature)
{
	// Make log
	NSMutableString *log;
	log = [NSMutableString string];
	[log appendString:[NSString stringWithCString:[signature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (int i = 0; i < [signature numberOfArguments]; i++) {
		[log appendString:[NSString stringWithCString:[signature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	
	// Log
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
	[self exchangeInstanceMethodForSelector:@selector(conformsToProtocol:) withForSelector:@selector(REResponder_X_conformsToProtocol:)];
	
	// respondsToSelector:
	[self exchangeInstanceMethodForSelector:@selector(respondsToSelector:) withForSelector:@selector(REResponder_X_respondsToSelector:)];
	
	// methodSignatureForSelector:
	[self exchangeInstanceMethodForSelector:@selector(methodSignatureForSelector:) withForSelector:@selector(REResponder_X_methodSignatureForSelector:)];
	
	// forwardInvocation:
	[self exchangeInstanceMethodForSelector:@selector(forwardInvocation:) withForSelector:@selector(REResponder_X_forwardInvocation:)];
	
	// dealloc
	[self exchangeInstanceMethodForSelector:@selector(dealloc) withForSelector:@selector(REResponder_X_dealloc)];
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSDictionary*)REResponder_blockInfoWithName:(NSString*)blockName blockInfos:(NSMutableArray**)blockInfos
{
	// Get blockInfo
	__block NSDictionary *blockInfo = nil;
	@synchronized (self) {
		[[[self associatedValueForKey:kBlocksKey] allValues] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSMutableArray *infos, NSUInteger idx, BOOL *stop) {
			NSUInteger index;
			NSArray *names;
			names = [infos valueForKey:kNameKey];
			index = [names indexOfObject:blockName];
			if (index != NSNotFound) {
				blockInfo = [infos objectAtIndex:index];
				if (blockInfos) {
					*blockInfos = infos;
				}
				*stop = YES;
			}
		}];
	}
	if (!blockInfo && blockInfos) {
		*blockInfos = nil;
	}
	
	return blockInfo;
}

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (void)REResponder_X_dealloc
{
	// Release protocols
	[self associateValue:nil forKey:kProtocolsKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// Release blocks
	NSArray *blockNames;
	NSMutableDictionary *blocks;
	blocks = [self associatedValueForKey:kBlocksKey];
	if ([blocks count]) {
		blockNames = [[blocks allValues] valueForKey:kNameKey];
		blockNames = [blockNames valueForKeyPath:@"@unionOfArrays.self"];
		[blockNames enumerateObjectsUsingBlock:^(NSString *blockName, NSUInteger idx, BOOL *stop) {
			[self removeBlockNamed:blockName];
		}];
		[self associateValue:nil forKey:kBlocksKey policy:OBJC_ASSOCIATION_RETAIN];
	}
	
	// original
	[self REResponder_X_dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol
{
	// Filter
	if (!protocol) {
		return;
	}
	
	// Update REResponder_protocols
	@synchronized (self) {
		// Get protocolName
		NSString *protocolName;
		protocolName = NSStringFromProtocol(protocol);
		
		// Get protocols
		NSMutableSet *protocols;
		protocols = [self associatedValueForKey:kProtocolsKey];
		
		// Add protocol
		if (flag) {
			if (!protocols) {
				protocols = [NSMutableSet set];
				[self associateValue:protocols forKey:kProtocolsKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			[protocols addObject:protocolName];
		}
		// Remove protocol
		else {
			[protocols removeObject:protocolName];
		}
	}
}

//--------------------------------------------------------------//
#pragma mark -- Block --
//--------------------------------------------------------------//

- (void)respondsToSelector:(SEL)selector usingBlock:(id)block blockName:(NSString**)name
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Get blockName
	NSString *blockName;
	if (!name || ![*name length]) {
		// Make blockName
		CFUUIDRef uuid;
		NSString* uuidString;
		uuid = CFUUIDCreate(NULL);
		uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
		CFRelease(uuid);
		blockName = uuidString;
		if (name) {
			*name = blockName;
		}
	}
	else {
		blockName = *name;
	}
	
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(selector);
	
	// Make signature
	NSMethodSignature *signature;
	NSMutableString *objCTypes;
	NSMethodSignature *blockSignature;
	blockSignature = [NSMethodSignature signatureWithObjCTypes:REBlockGetObjCTypes(block)];
	objCTypes = [NSMutableString stringWithFormat:@"%@@:", [NSString stringWithCString:[blockSignature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 1; i < [blockSignature numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[blockSignature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	signature = [NSMethodSignature signatureWithObjCTypes:[objCTypes cStringUsingEncoding:NSUTF8StringEncoding]];
	if (!signature) {
		return;
	}
	
	// Make blockInfo
	NSDictionary *blockInfo;
	blockInfo = @{
		kBlockKey : Block_copy(block),
		kNameKey : blockName,
		kSignatureKey : signature
	};
	
	// Set blockInfo to blocks
	@synchronized (self) {
		// Get blocks
		NSMutableDictionary *blocks;
		blocks = [self associatedValueForKey:kBlocksKey];
		
		// Check blockName
		NSArray *blockNames;
		blockNames = [[blocks allValues] valueForKey:kNameKey];
		if ([blockNames containsObject:blockName]) {
			NSLog(@"Could not add block with name %@ 'cos it exists", blockName);
			return;
		}
		
		// Add blockInfo
		NSMutableArray *blockInfos;
		blockInfos = [blocks objectForKey:selectorName];
		if (!blockInfos) {
			// Make blocks
			if (!blocks) {
				blocks = [NSMutableDictionary dictionary];
				[self associateValue:blocks forKey:kBlocksKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Make blockInfos
			blockInfos = [NSMutableArray array];
			[blocks setObject:blockInfos forKey:selectorName];
		}
		[blockInfos addObject:blockInfo];
	}
}

- (id)blockNamed:(NSString*)blockName
{
	// Get block
	id block;
	@synchronized (self) {
		// Get blockInfo
		NSDictionary *blockInfo;
		blockInfo = [self REResponder_blockInfoWithName:blockName blockInfos:nil];
		block = [blockInfo objectForKey:kBlockKey];
	}
	
	return block;
}

- (id)superBlockOfBlockNamed:(NSString*)blockName
{
	// Filter
	if (![blockName length]) {
		return nil;
	}
	
	// Get superBlock
	id superBlock = nil;
	@synchronized (self) {
		// Get blockInfo and blockInfos
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = [self REResponder_blockInfoWithName:blockName blockInfos:&blockInfos];
		if (blockInfo && blockInfos) {
			NSUInteger index;
			index = [blockInfos indexOfObject:blockInfo];
			if (index > 0) {
				superBlock = [[blockInfos objectAtIndex:(index - 1)] objectForKey:kBlockKey];
			}
		}
	}
	
	return superBlock;
}

- (void)removeBlockNamed:(NSString*)blockName
{
	@synchronized (self) {
		// Get blockInfo and blockInfos
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = [self REResponder_blockInfoWithName:blockName blockInfos:&blockInfos];
		if (blockInfo && blockInfos) {
			// Release block
			id block;
			block = [blockInfo objectForKey:kBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove blockInfo
			[blockInfos removeObject:blockInfo];
		}
	}
}

//--------------------------------------------------------------//
#pragma mark -- Messaging --
//--------------------------------------------------------------//

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)aProtocol
{
	// Handle registered protocol
	@synchronized (self) {
		if ([[self associatedValueForKey:kProtocolsKey] containsObject:NSStringFromProtocol(aProtocol)]) {
			return YES;
		}
	}
	
	// original
	return [self REResponder_X_conformsToProtocol:aProtocol];
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(aSelector);
	
	// Hadle registered selector
	@synchronized (self) {
		if ([[[self associatedValueForKey:kBlocksKey] objectForKey:selectorName] count]) {
			return YES;
		}
	}
	
	// original
	return [self REResponder_X_respondsToSelector:aSelector];
}

- (NSMethodSignature*)REResponder_X_methodSignatureForSelector:(SEL)aSelector
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(aSelector);
	
	// Handle registered selector
	@synchronized (self) {
		NSDictionary *blockInfo;
		blockInfo = [[[self associatedValueForKey:kBlocksKey] objectForKey:selectorName] lastObject];
		if (blockInfo) {
			return [blockInfo objectForKey:kSignatureKey];
		}
	}
	
	// original
	return [self REResponder_X_methodSignatureForSelector:aSelector];
}

- (void)REResponder_X_forwardInvocation:(NSInvocation*)invocation
{
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector([invocation selector]);
	
	// Handle registered selector
	@synchronized (self) {
		// Get blockInfo
		NSDictionary *blockInfo;
		blockInfo = [[[self associatedValueForKey:kBlocksKey] objectForKey:selectorName] lastObject];
		if (!blockInfo) {
			goto ORIGINAL;
		}
		
		// Get elements
		id block;
		NSMethodSignature *signature;
		NSUInteger argc;
		block = [blockInfo objectForKey:kBlockKey];
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
		blockInvocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:REBlockGetObjCTypes(block)]];
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
		[blockInvocation invokeUsingIMP:REBlockGetImplementation(block)];
		
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
	[self REResponder_X_forwardInvocation:invocation];
}

@end
