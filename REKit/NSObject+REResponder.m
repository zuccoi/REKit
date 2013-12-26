/*
 REResponder.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <dlfcn.h>
#import "execinfo.h"
#import "NSObject+REResponder.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kClassNamePrefix = @"REResponder";
static NSString* const kProtocolsAssociationKey = @"REResponder_protocols";
static NSString* const kBlocksAssociationKey = @"REResponder_blocks";
static NSString* const kBlockInfosMethodSignatureAssociationKey = @"methodSignature";
static NSString* const kBlockInfosOriginalMethodAssociationKey = @"originalMethod";

// Keys for protocolInfo
static NSString* const kProtocolInfoKeysKey = @"keys";
static NSString* const kProtocolInfoIncorporatedProtocolNamesKey = @"incorporatedProtocolNames";

// Keys for blockInfo
static NSString* const kBlockInfoImpKey = @"imp";
static NSString* const kBlockInfoKeyKey = @"key";

// Class Variables
static NSMutableDictionary *_blockRetainCounts = nil;


@implementation NSObject (REResponder)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

+ (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (!protocol) {
		return NO;
	}
	
	// original
	if ([self REResponder_X_conformsToProtocol:protocol]) {
		return YES;
	}
	
	// Check protocols
	@synchronized (self) {
		// Get protocols
		NSMutableDictionary *protocols;
		protocols = [self associatedValueForKey:kProtocolsAssociationKey];
		if (!protocols) {
			return NO;
		}
		
		// Find protocolName
		NSString *protocolName;
		__block BOOL found = NO;
		protocolName = NSStringFromProtocol(protocol);
		[protocols enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *aProtocolName, NSMutableDictionary *protocolInfo, BOOL *stop) {
			if ([aProtocolName isEqualToString:protocolName]
				|| [protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey] containsObject:protocolName]
			){
				found = YES;
				*stop = YES;
			}
		}];
		
		return found;
	}
}

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (!protocol) {
		return NO;
	}
	
	// original
	if ([self REResponder_X_conformsToProtocol:protocol]) {
		return YES;
	}
	
	// Check protocols
	@synchronized (self) {
		// Get protocols
		NSMutableDictionary *protocols;
		protocols = [self associatedValueForKey:kProtocolsAssociationKey];
		if (!protocols) {
			return NO;
		}
		
		// Find protocolName
		NSString *protocolName;
		__block BOOL found = NO;
		protocolName = NSStringFromProtocol(protocol);
		[protocols enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *aProtocolName, NSMutableDictionary *protocolInfo, BOOL *stop) {
			if ([aProtocolName isEqualToString:protocolName]
				|| [protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey] containsObject:protocolName]
			){
				found = YES;
				*stop = YES;
			}
		}];
		
		return found;
	}
}

+ (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	@synchronized (self) {
		BOOL responds;
		responds = [self REResponder_X_respondsToSelector:aSelector];
		if (responds) {
			// Forwarding method?
			if ([self methodForSelector:aSelector] == [self REResponder_dynamicForwardingMethod]) {
				responds = NO;
			}
		}
		
		return responds;
	}
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	@synchronized (self) {
		BOOL responds;
		responds = [self REResponder_X_respondsToSelector:aSelector];
		if (responds) {
			// Forwarding method?
			if ([self methodForSelector:aSelector] == [self REResponder_dynamicForwardingMethod]) {
				responds = NO;
			}
		}
		
		return responds;
	}
}

- (void)REResponder_X_dealloc
{
	@autoreleasepool {
		@synchronized (self) {
			// Remove protocols
			[self setAssociatedValue:nil forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			
			// Remove blocks
			NSMutableDictionary *blocks;
			blocks = [self associatedValueForKey:kBlocksAssociationKey];
			[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
				while ([blockInfos count]) {
					NSDictionary *blockInfo;
					blockInfo = [blockInfos lastObject];
					[self removeBlockForSelector:NSSelectorFromString(selectorName) key:blockInfo[kBlockInfoKeyKey]];
				}
			}];
			[self setAssociatedValue:nil forKey:kBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			
			// Dispose classes
			NSString *className;
			className = [NSString stringWithUTF8String:class_getName([self class])];
			if ([className hasPrefix:kClassNamePrefix]) {
				// Dispose NSKVONotifying subclass
				Class kvoClass;
				kvoClass = NSClassFromString([NSString stringWithFormat:@"NSKVONotifying_%@", className]);
				if (kvoClass) {
					objc_disposeClassPair(kvoClass);
				}
				
				// Dispose class
				Class class;
				class = [self class];
				[self willChangeClass:[self superclass]];
				object_setClass(self, [self superclass]);
				[self didChangeClass:class];
				objc_disposeClassPair(class);
			}
		}
	}
	
	// original
	[self REResponder_X_dealloc];
}

+ (void)load
{
	@autoreleasepool {
		// Exchange class methods
		[self exchangeClassMethodsWithAdditiveSelectorPrefix:@"REResponder_X_" selectors:
			@selector(conformsToProtocol:),
			@selector(respondsToSelector:),
			nil
		];
		
		// Exchange instance methods
		[self exchangeInstanceMethodsWithAdditiveSelectorPrefix:@"REResponder_X_" selectors:
			@selector(conformsToProtocol:),
			@selector(respondsToSelector:),
			@selector(dealloc),
			nil
		];
		
		// Create _blockRetainCounts
		_blockRetainCounts = [[NSMutableDictionary alloc] init];
	}
}

//--------------------------------------------------------------//
#pragma mark -- Util --
//--------------------------------------------------------------//

+ (IMP)REResponder_dynamicForwardingMethod
{
	return [self methodForSelector:@selector(REResponder_UnexistingMethod)];
}

- (IMP)REResponder_dynamicForwardingMethod
{
	return [self methodForSelector:@selector(REResponder_UnexistingMethod)];
}

+ (NSDictionary*)REResponder_blockInfoForSelector:(SEL)selector key:(id)key blockInfos:(NSMutableArray**)outBlockInfos
{
	@synchronized (self) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		NSMutableArray *blockInfos;
		blockInfos = [self associatedValueForKey:kBlocksAssociationKey][NSStringFromSelector(selector)];
		[blockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stop) {
			if ([aBlockInfo[kBlockInfoKeyKey] isEqual:key]) {
				blockInfo = aBlockInfo;
				*stop = YES;
			}
		}];
		if (outBlockInfos) {
			*outBlockInfos = blockInfos;
		}
		
		return blockInfo;
	}
}

- (NSDictionary*)REResponder_blockInfoForSelector:(SEL)selector key:(id)key blockInfos:(NSMutableArray**)outBlockInfos
{
	@synchronized (self) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		NSMutableArray *blockInfos;
		blockInfos = [self associatedValueForKey:kBlocksAssociationKey][NSStringFromSelector(selector)];
		[blockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stop) {
			if ([aBlockInfo[kBlockInfoKeyKey] isEqual:key]) {
				blockInfo = aBlockInfo;
				*stop = YES;
			}
		}];
		if (outBlockInfos) {
			*outBlockInfos = blockInfos;
		}
		
		return blockInfo;
	}
}

+ (NSDictionary*)REResponder_blockInfoWithImplementation:(IMP)imp blockInfos:(NSMutableArray**)outBlockInfos selector:(SEL*)outSelector
{
	@synchronized (self) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		[[self associatedValueForKey:kBlocksAssociationKey] enumerateKeysAndObjectsUsingBlock:^(NSString *aSelectorName, NSMutableArray *aBlockInfos, BOOL *stopA) {
			[aBlockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stopB) {
				if (REBlockGetImplementation(imp_getBlock([aBlockInfo[kBlockInfoImpKey] pointerValue])) == imp) {
					blockInfo = aBlockInfo;
					*stopB = YES;
				}
			}];
			if (blockInfo) {
				if (outSelector) {
					*outSelector = NSSelectorFromString(aSelectorName);
				}
				if (outBlockInfos) {
					*outBlockInfos = aBlockInfos;
				}
				*stopA = YES;
			}
		}];
		
		return blockInfo;
	}
}

- (NSDictionary*)REResponder_blockInfoWithImplementation:(IMP)imp blockInfos:(NSMutableArray**)outBlockInfos selector:(SEL*)outSelector
{
	@synchronized (self) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		[[self associatedValueForKey:kBlocksAssociationKey] enumerateKeysAndObjectsUsingBlock:^(NSString *aSelectorName, NSMutableArray *aBlockInfos, BOOL *stopA) {
			[aBlockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stopB) {
				if (REBlockGetImplementation(imp_getBlock([aBlockInfo[kBlockInfoImpKey] pointerValue])) == imp) {
					blockInfo = aBlockInfo;
					*stopB = YES;
				}
			}];
			if (blockInfo) {
				if (outSelector) {
					*outSelector = NSSelectorFromString(aSelectorName);
				}
				if (outBlockInfos) {
					*outBlockInfos = aBlockInfos;
				}
				*stopA = YES;
			}
		}];
		
		return blockInfo;
	}
}

+ (IMP)REResponder_implementationWithBacktraceDepth:(int)depth
{
	// Get trace
	int num;
	void *trace[depth + 1];
	num = backtrace(trace, (depth + 1));
	if (num < (depth + 1)) {
		return NULL;
	}
	
	// Get imp
	IMP imp;
	Dl_info callerInfo;
	if (!dladdr(trace[depth], &callerInfo)) {
		NSLog(@"ERROR: Failed to get callerInfo with error:%s «%s-%d", dlerror(), __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	imp = callerInfo.dli_saddr;
	if (!imp) {
		NSLog(@"ERROR: Failed to get imp from callerInfo «%s-%d", __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	
	return imp;
}

- (IMP)REResponder_implementationWithBacktraceDepth:(int)depth
{
	// Get trace
	int num;
	void *trace[depth + 1];
	num = backtrace(trace, (depth + 1));
	if (num < (depth + 1)) {
		return NULL;
	}
	
	// Get imp
	IMP imp;
	Dl_info callerInfo;
	if (!dladdr(trace[depth], &callerInfo)) {
		NSLog(@"ERROR: Failed to get callerInfo with error:%s «%s-%d", dlerror(), __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	imp = callerInfo.dli_saddr;
	if (!imp) {
		NSLog(@"ERROR: Failed to get imp from callerInfo «%s-%d", __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	
	return imp;
}

//--------------------------------------------------------------//
#pragma mark -- Block --
//--------------------------------------------------------------//

+ (void)setBlockForSelector:(SEL)selector key:(id)inKey block:(id)block
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Get key
	id key;
	key = (inKey != nil ? inKey : REUUIDString());
	
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(selector);
	
	// Make signatures
	NSMethodSignature *blockSignature;
	NSMethodSignature *methodSignature;
	NSMutableString *objCTypes;
	blockSignature = [NSMethodSignature signatureWithObjCTypes:REBlockGetObjCTypes(block)];
	objCTypes = [NSMutableString stringWithFormat:@"%@@:", [NSString stringWithCString:[blockSignature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 2; i < [blockSignature numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[blockSignature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	methodSignature = [NSMethodSignature signatureWithObjCTypes:[objCTypes cStringUsingEncoding:NSUTF8StringEncoding]];
	if (!methodSignature) {
		NSLog(@"Failed to get signature for key %@", key);
		return;
	}
	
	// Update blocks
	@synchronized (self) {
		// Remove old one
		[self removeBlockForSelector:selector key:key];
		
		// Get blocks
		NSMutableDictionary *blocks;
		blocks = [self associatedValueForKey:kBlocksAssociationKey];
		
		// Get blockInfos
		NSMutableArray *blockInfos;
		blockInfos = blocks[selectorName];
		if (!blockInfos) {
			// Make blocks
			if (!blocks) {
				blocks = [NSMutableDictionary dictionary];
				[self setAssociatedValue:blocks forKey:kBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Make blockInfos
			blockInfos = [NSMutableArray array];
			[blockInfos setAssociatedValue:methodSignature forKey:kBlockInfosMethodSignatureAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			
			// Associate original method
			IMP originalMethod;
			originalMethod = [self methodForSelector:selector];
			if (originalMethod && originalMethod != [self REResponder_dynamicForwardingMethod]) {
				[blockInfos setAssociatedValue:[NSValue valueWithPointer:originalMethod] forKey:kBlockInfosOriginalMethodAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			[blocks setObject:blockInfos forKey:selectorName];
		}
		
		// Replace method
		class_replaceMethod(object_getClass(self), selector, imp_implementationWithBlock(block), [objCTypes UTF8String]);
		
		// Add blockInfo to blockInfos
		NSDictionary *blockInfo;
		IMP imp;
		imp = [self methodForSelector:selector];
		blockInfo = @{
			kBlockInfoImpKey : [NSValue valueWithPointer:imp],
			kBlockInfoKeyKey : key,
		};
		[blockInfos addObject:blockInfo];
		
		// Increase retain ount of block
		NSUInteger retainCount;
		NSValue *blockImpKey;
		blockImpKey = [NSValue valueWithPointer:REBlockGetImplementation(imp_getBlock([blockInfo[kBlockInfoImpKey] pointerValue]))];
		retainCount = [_blockRetainCounts[blockImpKey] unsignedIntegerValue];
		_blockRetainCounts[blockImpKey] = @(++retainCount);
	}
}

- (void)setBlockForSelector:(SEL)selector key:(id)inKey block:(id)block
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Get key
	id key;
	key = (inKey != nil ? inKey : REUUIDString());
	
	// Get selectorName
	NSString *selectorName;
	selectorName = NSStringFromSelector(selector);
	
	// Make signatures
	NSMethodSignature *blockSignature;
	NSMethodSignature *methodSignature;
	NSMutableString *objCTypes;
	blockSignature = [NSMethodSignature signatureWithObjCTypes:REBlockGetObjCTypes(block)];
	objCTypes = [NSMutableString stringWithFormat:@"%@@:", [NSString stringWithCString:[blockSignature methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 2; i < [blockSignature numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[blockSignature getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	methodSignature = [NSMethodSignature signatureWithObjCTypes:[objCTypes cStringUsingEncoding:NSUTF8StringEncoding]];
	if (!methodSignature) {
		NSLog(@"Failed to get signature for key %@", key);
		return;
	}
	
	// Update blocks
	@synchronized (self) {
		// Remove old one
		[self removeBlockForSelector:selector key:key];
		
		// Get blocks
		NSMutableDictionary *blocks;
		blocks = [self associatedValueForKey:kBlocksAssociationKey];
		
		// Get blockInfos
		NSMutableArray *blockInfos;
		blockInfos = blocks[selectorName];
		if (!blockInfos) {
			// Make blocks
			if (!blocks) {
				blocks = [NSMutableDictionary dictionary];
				[self setAssociatedValue:blocks forKey:kBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Make blockInfos
			blockInfos = [NSMutableArray array];
			[blockInfos setAssociatedValue:methodSignature forKey:kBlockInfosMethodSignatureAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			[blocks setObject:blockInfos forKey:selectorName];
		}
		
		// Become subclass
		if (![NSStringFromClass([self class]) hasPrefix:kClassNamePrefix]) {
			Class originalClass;
			Class subclass;
			NSString *className;
			originalClass = [self class];
			className = [NSString stringWithFormat:@"%@_%@_%@", kClassNamePrefix, REUUIDString(), NSStringFromClass([self class])];
			subclass = objc_allocateClassPair(originalClass, [className UTF8String], 0);
			objc_registerClassPair(subclass);
			[self willChangeClass:subclass];
			object_setClass(self, subclass);
			[self didChangeClass:originalClass];
		}
		
		// Replace method
		class_replaceMethod([self class], selector, imp_implementationWithBlock(block), [objCTypes UTF8String]);
		
		// Add blockInfo to blockInfos
		NSDictionary *blockInfo;
		IMP imp;
		imp = [self methodForSelector:selector];
		blockInfo = @{
			kBlockInfoImpKey : [NSValue valueWithPointer:imp],
			kBlockInfoKeyKey : key,
		};
		[blockInfos addObject:blockInfo];
		
		// Increase retain ount of block
		NSUInteger retainCount;
		NSValue *blockImpKey;
		blockImpKey = [NSValue valueWithPointer:REBlockGetImplementation(imp_getBlock([blockInfo[kBlockInfoImpKey] pointerValue]))];
		retainCount = [_blockRetainCounts[blockImpKey] unsignedIntegerValue];
		_blockRetainCounts[blockImpKey] = @(++retainCount);
	}
}

+ (BOOL)hasBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (!selector || !key) {
		return NO;
	}
	
	// Get block
	IMP blockImp;
	@synchronized (self) {
		// Get blockInfo
		NSDictionary *blockInfo;
		blockInfo = [self REResponder_blockInfoForSelector:selector key:key blockInfos:nil];
		blockImp = [blockInfo[kBlockInfoImpKey] pointerValue];
	}
	
	return (blockImp != NULL);
}

- (BOOL)hasBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (!selector || !key) {
		return NO;
	}
	
	// Get block
	IMP blockImp;
	@synchronized (self) {
		// Get blockInfo
		NSDictionary *blockInfo;
		blockInfo = [self REResponder_blockInfoForSelector:selector key:key blockInfos:nil];
		blockImp = [blockInfo[kBlockInfoImpKey] pointerValue];
	}
	
	return (blockImp != NULL);
}

+ (void)removeBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (!selector || !key) {
		return;
	}
	
	// Remove
	@synchronized (self) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = [self REResponder_blockInfoForSelector:selector key:key blockInfos:&blockInfos];
		if (blockInfo && blockInfos) {
			// Replace method
			if (blockInfo == [blockInfos lastObject]) {
				// Get objCTypes
				const char *objCTypes;
				objCTypes = [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes];
				
				// Get supermethod
				IMP supermethod = NULL;
				NSUInteger index;
				index = [blockInfos indexOfObject:blockInfo];
				if (index == 0) {
					supermethod = [[blockInfos associatedValueForKey:kBlockInfosOriginalMethodAssociationKey] pointerValue];
				}
				else {
					supermethod = (IMP)[blockInfos[index-1][kBlockInfoImpKey] pointerValue];
				}
				if (!supermethod) {
					supermethod = [self REResponder_dynamicForwardingMethod];
				}
				
				// Replace method
				class_replaceMethod(object_getClass(self), selector, supermethod, objCTypes);
			}
			
			// Get retainCount of block
			NSUInteger retainCount;
			NSValue *blockImpKey;
			blockImpKey = [NSValue valueWithPointer:REBlockGetImplementation(imp_getBlock([blockInfo[kBlockInfoImpKey] pointerValue]))];
			retainCount = [_blockRetainCounts[blockImpKey] unsignedIntegerValue];
			if (retainCount <= 1) {
				// Remove entry for block
				[_blockRetainCounts removeObjectForKey:blockImpKey];
				
				// Remove implementation
				imp_removeBlock([blockInfo[kBlockInfoImpKey] pointerValue]);
			}
			else {
				// Decrease retainCount
				_blockRetainCounts[blockImpKey] = @(--retainCount);
			}
			
			// Remove blockInfo
			[blockInfos removeObject:blockInfo];
		}
	}
}

- (void)removeBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (!selector || !key) {
		return;
	}
	
	// Remove
	@synchronized (self) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = [self REResponder_blockInfoForSelector:selector key:key blockInfos:&blockInfos];
		if (blockInfo && blockInfos) {
			// Replace method
			if (blockInfo == [blockInfos lastObject]) {
				// Get objCTypes
				const char *objCTypes;
				objCTypes = [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes];
				
				// Get supermethod
				IMP supermethod = NULL;
				NSUInteger index;
				index = [blockInfos indexOfObject:blockInfo];
				if (index == 0) {
					// supermethod is superclass's instance method
					supermethod = method_getImplementation(class_getInstanceMethod([[self class] superclass], selector));
				}
				else {
					// supermethod is superblock's IMP
					supermethod = (IMP)[blockInfos[index-1][kBlockInfoImpKey] pointerValue];
				}
				if (!supermethod) {
					supermethod = [self REResponder_dynamicForwardingMethod];
				}
				
				// Replace method
				class_replaceMethod([self class], selector, supermethod, objCTypes);
			}
			
			// Get retainCount of block
			NSUInteger retainCount;
			NSValue *blockImpKey;
			blockImpKey = [NSValue valueWithPointer:REBlockGetImplementation(imp_getBlock([blockInfo[kBlockInfoImpKey] pointerValue]))];
			retainCount = [_blockRetainCounts[blockImpKey] unsignedIntegerValue];
			if (retainCount <= 1) {
				// Remove entry for block
				[_blockRetainCounts removeObjectForKey:blockImpKey];
				
				// Remove implementation
				imp_removeBlock([blockInfo[kBlockInfoImpKey] pointerValue]);
			}
			else {
				// Decrease retainCount
				_blockRetainCounts[blockImpKey] = @(--retainCount);
			}
			
			// Remove blockInfo
			[blockInfos removeObject:blockInfo];
		}
	}
}

//--------------------------------------------------------------//
#pragma mark -- Current Block --
//--------------------------------------------------------------//

+ (IMP)supermethodOfCurrentBlock
{
	// Get imp of current block
	IMP imp;
	imp = [self REResponder_implementationWithBacktraceDepth:2];
	if (!imp) {
		return NULL;
	}
	
	// Get supermethod
	IMP supermethod = NULL;
	@synchronized (self) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		SEL selector;
		Class class;
		class = self;
		while (YES) {
			blockInfo = [class REResponder_blockInfoWithImplementation:imp blockInfos:&blockInfos selector:&selector];
			if (blockInfo) {
				break;
			}
			class = [class superclass];
			if (!class) {
				break;
			}
		}
		if (!blockInfo || !blockInfos || !selector) {
			return NULL;
		}
		
		// Check index of blockInfo
		NSUInteger index;
		index = [blockInfos indexOfObject:blockInfo];
		if (index == 0) {
			NSValue *originalMethodValue;
			originalMethodValue = [blockInfos associatedValueForKey:kBlockInfosOriginalMethodAssociationKey];
			if (originalMethodValue) {
				supermethod = [originalMethodValue pointerValue];
			}
			else {
				supermethod = method_getImplementation(class_getClassMethod([class superclass], selector));
			}
		}
		else {
			supermethod = [[blockInfos objectAtIndex:(index - 1)][kBlockInfoImpKey] pointerValue];
		}
	}
	if (supermethod == [self REResponder_dynamicForwardingMethod]) {
		return NULL;
	}
	
	return supermethod;
}

- (IMP)supermethodOfCurrentBlock
{
	// Get imp of current block
	IMP imp;
	imp = [self REResponder_implementationWithBacktraceDepth:2];
	if (!imp) {
		return NULL;
	}
	
	// Get supermethod
	IMP supermethod = NULL;
	@synchronized (self) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		SEL selector;
		blockInfo = [self REResponder_blockInfoWithImplementation:imp blockInfos:&blockInfos selector:&selector];
		if (!blockInfo || !blockInfos || !selector) {
			return NULL;
		}
		
		// Check index of blockInfo
		NSUInteger index;
		index = [blockInfos indexOfObject:blockInfo];
		if (index == 0) {
			// supermethod is superclass's instance method
			supermethod = method_getImplementation(class_getInstanceMethod([[self class] superclass], selector));
		}
		else {
			// supermethod is superblock's IMP
			supermethod = [[blockInfos objectAtIndex:(index - 1)][kBlockInfoImpKey] pointerValue];
		}
	}
	
	return supermethod;
}

+ (void)removeCurrentBlock
{
	// Get imp of current block
	IMP imp;
	imp = [self REResponder_implementationWithBacktraceDepth:2];
	if (!imp) {
		return;
	}
	
	// Get elements
	NSDictionary *blockInfo;
	SEL selector;
	blockInfo = [self REResponder_blockInfoWithImplementation:imp blockInfos:nil selector:&selector];
	if (!blockInfo || !selector) {
		return;
	}
	
	// Call removeBlockForSelector:forKey:
	[self removeBlockForSelector:selector key:blockInfo[kBlockInfoKeyKey]];
}

- (void)removeCurrentBlock
{
	// Get imp of current block
	IMP imp;
	imp = [self REResponder_implementationWithBacktraceDepth:2];
	if (!imp) {
		return;
	}
	
	// Get elements
	NSDictionary *blockInfo;
	SEL selector;
	blockInfo = [self REResponder_blockInfoWithImplementation:imp blockInfos:nil selector:&selector];
	if (!blockInfo || !selector) {
		return;
	}
	
	// Call removeBlockForSelector:forKey:
	[self removeBlockForSelector:selector key:blockInfo[kBlockInfoKeyKey]];
}

//--------------------------------------------------------------//
#pragma mark -- Conformance --
//--------------------------------------------------------------//

+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)inKey
{
	// Filter
	if (!protocol || (!conformable && !inKey)) {
		return;
	}
	
	// Get key
	id key;
	key = inKey ? inKey : REUUIDString();
	
	// Update REResponder_protocols
	@synchronized (self) {
		// Get elements
		NSString *protocolName;
		NSMutableDictionary *protocols;
		NSMutableDictionary *protocolInfo;
		protocolName = NSStringFromProtocol(protocol);
		protocols = [self associatedValueForKey:kProtocolsAssociationKey];
		protocolInfo = protocols[protocolName];
		
		// Add key
		if (conformable) {
			// Associate protocols
			if (!protocols) {
				protocols = [NSMutableDictionary dictionary];
				[self setAssociatedValue:protocols forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Set protocolInfo to protocols
			if (!protocolInfo) {
				protocolInfo = [NSMutableDictionary dictionary];
				protocolInfo[kProtocolInfoKeysKey] = [NSMutableSet set];
				protocols[protocolName] = protocolInfo;
			}
			
			// Make incorporatedProtocolNames
			NSMutableSet *incorporatedProtocolNames;
			incorporatedProtocolNames = protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey];
			if (!incorporatedProtocolNames) {
				// Set incorporatedProtocolNames to protocolInfo
				incorporatedProtocolNames = [NSMutableSet set];
				protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey] = incorporatedProtocolNames;
				
				// Add protocol names
				unsigned int count;
				Protocol **protocols;
				Protocol *aProtocol;
				protocols = protocol_copyProtocolList(protocol, &count);
				for (int i = 0; i < count; i++) {
					aProtocol = protocols[i];
					[incorporatedProtocolNames addObject:NSStringFromProtocol(aProtocol)];
				}
			}
			
			// Add key to keys
			NSMutableSet *keys;
			keys = protocolInfo[kProtocolInfoKeysKey];
			if ([keys containsObject:key]) {
				return;
			}
			[keys addObject:key];
		}
		// Remove key
		else {
			// Filter
			if (!protocolInfo) {
				return;
			}
			
			// Remove key from keys
			NSMutableSet *keys;
			keys = protocolInfo[kProtocolInfoKeysKey];
			[keys removeObject:key];
			
			// Remove protocolInfo
			if (![keys count]) {
				[protocols removeObjectForKey:protocolName];
			}
		}
	}
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)inKey
{
	// Filter
	if (!protocol || (!conformable && !inKey)) {
		return;
	}
	
	// Get key
	id key;
	key = inKey ? inKey : REUUIDString();
	
	// Update REResponder_protocols
	@synchronized (self) {
		// Get elements
		NSString *protocolName;
		NSMutableDictionary *protocols;
		NSMutableDictionary *protocolInfo;
		protocolName = NSStringFromProtocol(protocol);
		protocols = [self associatedValueForKey:kProtocolsAssociationKey];
		protocolInfo = protocols[protocolName];
		
		// Add key
		if (conformable) {
			// Associate protocols
			if (!protocols) {
				protocols = [NSMutableDictionary dictionary];
				[self setAssociatedValue:protocols forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Set protocolInfo to protocols
			if (!protocolInfo) {
				protocolInfo = [NSMutableDictionary dictionary];
				protocolInfo[kProtocolInfoKeysKey] = [NSMutableSet set];
				protocols[protocolName] = protocolInfo;
			}
			
			// Make incorporatedProtocolNames
			NSMutableSet *incorporatedProtocolNames;
			incorporatedProtocolNames = protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey];
			if (!incorporatedProtocolNames) {
				// Set incorporatedProtocolNames to protocolInfo
				incorporatedProtocolNames = [NSMutableSet set];
				protocolInfo[kProtocolInfoIncorporatedProtocolNamesKey] = incorporatedProtocolNames;
				
				// Add protocol names
				unsigned int count;
				Protocol **protocols;
				Protocol *aProtocol;
				protocols = protocol_copyProtocolList(protocol, &count);
				for (int i = 0; i < count; i++) {
					aProtocol = protocols[i];
					[incorporatedProtocolNames addObject:NSStringFromProtocol(aProtocol)];
				}
			}
			
			// Add key to keys
			NSMutableSet *keys;
			keys = protocolInfo[kProtocolInfoKeysKey];
			if ([keys containsObject:key]) {
				return;
			}
			[keys addObject:key];
		}
		// Remove key
		else {
			// Filter
			if (!protocolInfo) {
				return;
			}
			
			// Remove key from keys
			NSMutableSet *keys;
			keys = protocolInfo[kProtocolInfoKeysKey];
			[keys removeObject:key];
			
			// Remove protocolInfo
			if (![keys count]) {
				[protocols removeObjectForKey:protocolName];
			}
		}
	}
}

@end

#pragma mark -


@implementation NSObject (REResponder_Deprecated)

- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated))
{
	[self setBlockForSelector:selector key:key block:block];
}

- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	return [self hasBlockForSelector:selector key:key];
}

- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	[self removeBlockForSelector:selector key:key];
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated))
{
	[self setConformable:conformable toProtocol:protocol key:key];
}

@end
