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
static NSString* const kInstancesBlocksAssociationKey = @"REResponder_instaceBlocks";
static NSString* const kBlockInfosMethodSignatureAssociationKey = @"methodSignature";
static NSString* const kBlockInfosOriginalMethodAssociationKey = @"originalMethod";

// Keys for protocolInfo
static NSString* const kProtocolInfoKeysKey = @"keys";
static NSString* const kProtocolInfoIncorporatedProtocolNamesKey = @"incorporatedProtocolNames";

// Keys for blockInfo
static NSString* const kBlockInfoImpKey = @"imp";
static NSString* const kBlockInfoKeyKey = @"key";
static NSString* const kBlockInfoOperationKey = @"op";

// REResponderOperation
typedef NS_ENUM(NSInteger, REResponderOperation) {
	REResponderOperationClass,
	REResponderOperationInstances,
	REResponderOperationObject,
};


@implementation NSObject (REResponder)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

BOOL REREsponderConformsToProtocol(id receiver, Protocol *protocol)
{
	// Filter
	if (!protocol) {
		return NO;
	}
	
	// original
	if ([receiver REResponder_X_conformsToProtocol:protocol]) {
		return YES;
	}
	
	// Check protocols
	@synchronized (receiver) {
		// Get protocols
		NSMutableDictionary *protocols;
		protocols = [receiver associatedValueForKey:kProtocolsAssociationKey];
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

+ (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (self != [self class]) {
		return NO;
	}
	
	// Conforms?
	BOOL conforms = NO;
	Class class;
	class = self;
	while (!conforms && class) {
		conforms = REREsponderConformsToProtocol(class, protocol);
		class = [class superclass];
	}
	
	return conforms;
}

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (self == [self class]) {
		return NO;
	}
	
	return (REREsponderConformsToProtocol(self, protocol) || [[self class] conformsToProtocol:protocol]);
}

BOOL REResponderRespondsToSelector(id receiver, SEL aSelector, REResponderOperation op)
{
	@synchronized (receiver) {
		BOOL responds;
		if (op == REResponderOperationInstances) {
			responds = [receiver REResponder_X_instancesRespondToSelector:aSelector];
			if (responds) {
				// Forwarding method?
				if ([receiver instanceMethodForSelector:aSelector] == REResponderForwardingMethod()) {
					responds = NO;
				}
			}
		}
		else {
			responds = [receiver REResponder_X_respondsToSelector:aSelector];
			if (responds) {
				// Forwarding method?
				if ([receiver methodForSelector:aSelector] == REResponderForwardingMethod()) {
					responds = NO;
				}
			}
		}
		
		return responds;
	}
}

+ (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Filter
	if (self != [self class]) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationClass);
}

+ (BOOL)REResponder_X_instancesRespondToSelector:(SEL)aSelector
{
	// Filter
	if (self != [self class]) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationInstances);
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Filter
	if (self == [self class]) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationObject);
}

- (void)REResponder_X_dealloc
{
	@autoreleasepool {
		@synchronized (self) {
			// Remove protocols
			[self setAssociatedValue:nil forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			
			// Remove blocks
			NSDictionary *blocks;
			blocks = [NSDictionary dictionaryWithDictionary:[self associatedValueForKey:kBlocksAssociationKey]];
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
			@selector(instancesRespondToSelector:),
			nil
		];
		
		// Exchange instance methods
		[self exchangeInstanceMethodsWithAdditiveSelectorPrefix:@"REResponder_X_" selectors:
			@selector(conformsToProtocol:),
			@selector(respondsToSelector:),
			@selector(dealloc),
			nil
		];
	}
}

//--------------------------------------------------------------//
#pragma mark -- Util --
//--------------------------------------------------------------//

IMP REResponderForwardingMethod()
{
	return [NSObject methodForSelector:@selector(REResponder_UnexistingMethod)];
}

IMP REResponderImplementationWithBacktraceDepth(int depth)
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

NSMutableDictionary* REResponderBlocks(id receiver, REResponderOperation op, BOOL create)
{
	NSMutableDictionary *blocks;
	NSString *key;
	key = (op == REResponderOperationInstances ? kInstancesBlocksAssociationKey : kBlocksAssociationKey);
	blocks = [receiver associatedValueForKey:key];
	if (!blocks && create) {
		blocks = [NSMutableDictionary dictionary];
		[receiver setAssociatedValue:blocks forKey:key policy:OBJC_ASSOCIATION_RETAIN];
	}
	
	return blocks;
}

NSDictionary* REResponderBlockInfoForSelector(id receiver, SEL selector, id key, NSMutableArray **outBlockInfos, REResponderOperation op)
{
	@synchronized (receiver) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		NSMutableArray *blockInfos;
		NSMutableDictionary *blocks;
		blocks = REResponderBlocks(receiver, op, NO);
		blockInfos = blocks[NSStringFromSelector(selector)];
		[blockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stop) {
			if ([aBlockInfo[kBlockInfoOperationKey] integerValue] == op
				&& [aBlockInfo[kBlockInfoKeyKey] isEqual:key]
			){
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

+ (NSDictionary*)REResponder_blockInfoForSelector:(SEL)selector key:(id)key blockInfos:(NSMutableArray**)outBlockInfos operation:(REResponderOperation)op
{
	// Filter
	if (self != [self class]) {
		return nil;
	}
	
	return REResponderBlockInfoForSelector(self, selector, key, outBlockInfos, op);
}

- (NSDictionary*)REResponder_blockInfoForSelector:(SEL)selector key:(id)key blockInfos:(NSMutableArray**)outBlockInfos operation:(REResponderOperation)op
{
	// Filter
	if (self == [self class]) {
		return nil;
	}
	
	return REResponderBlockInfoForSelector(self, selector, key, outBlockInfos, op);
}

NSDictionary* REResponderBlockInfoWithImplementation(id receiver, IMP imp, NSMutableArray **outBlockInfos, SEL *outSelector)
{
	@synchronized (receiver) {
		// Get blockInfo 
		__block NSDictionary *blockInfo = nil;
		
		// Make blockInfoBlock
		void (^blockInfoBlock)(NSMutableDictionary *blocks);
		blockInfoBlock = ^(NSMutableDictionary *blocks) {
			[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *aSelectorName, NSMutableArray *aBlockInfos, BOOL *stopA) {
				[aBlockInfos enumerateObjectsUsingBlock:^(NSDictionary *aBlockInfo, NSUInteger idx, BOOL *stopB) {
					IMP aImp;
					aImp = [aBlockInfo[kBlockInfoImpKey] pointerValue];
					if (aImp == imp || REBlockGetImplementation(imp_getBlock(aImp)) == imp) {
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
		};
		
		// Search object block
		if (receiver != [receiver class]) {
			blockInfoBlock(REResponderBlocks(receiver, REResponderOperationObject, NO));
		}
		if (blockInfo) {
			return blockInfo;
		}
		
		// Search instances block
		blockInfoBlock(REResponderBlocks([receiver class], REResponderOperationInstances, NO));
		if (blockInfo) {
			return blockInfo;
		}
		
		// Search class block
		blockInfoBlock(REResponderBlocks([receiver class], REResponderOperationClass, NO));
		
		return blockInfo;
	}
}

+ (NSDictionary*)REResponder_blockInfoWithImplementation:(IMP)imp blockInfos:(NSMutableArray**)outBlockInfos selector:(SEL*)outSelector
{
	// Filter
	if (self != [self class]) {
		return nil;
	}
	
	return REResponderBlockInfoWithImplementation(self, imp, outBlockInfos, outSelector);
}

- (NSDictionary*)REResponder_blockInfoWithImplementation:(IMP)imp blockInfos:(NSMutableArray**)outBlockInfos selector:(SEL*)outSelector
{
	// Filter
	if (self == [self class]) {
		return nil;
	}
	
	return REResponderBlockInfoWithImplementation(self, imp, outBlockInfos, outSelector);
}

IMP REResponderSupermethodWithImp(id receiver, IMP imp)
{
	// Filter
	if (!imp) {
		return NULL;
	}
	
	// Get supermethod
	IMP supermethod = NULL;
	@synchronized (receiver) {
		// Get elements
		NSDictionary *blockInfo = nil;
		NSMutableArray *blockInfos = nil;
		SEL selector;
		Class classHavingBlockinfo = NULL;
		blockInfo = [receiver REResponder_blockInfoWithImplementation:imp blockInfos:&blockInfos selector:&selector];
		if (blockInfo) {
			classHavingBlockinfo = [receiver class];
		}
		else {
			// Search blockInfo of superclasses
			Class superclass;
			superclass = [[receiver class] superclass];
			while (superclass) {
				blockInfo = [superclass REResponder_blockInfoWithImplementation:imp blockInfos:&blockInfos selector:&selector];
				if (blockInfo) {
					classHavingBlockinfo = superclass;
					break;
				}
				superclass = [superclass superclass];
			}
		}
		if (!blockInfo) {
			return NULL;
		}
		
		// Check index of blockInfo
		NSUInteger index;
		index = [blockInfos indexOfObject:blockInfo];
		if (index == 0) {
			NSValue *originalMethodValue;
			originalMethodValue = [blockInfos associatedValueForKey:kBlockInfosOriginalMethodAssociationKey];
			if (originalMethodValue) {
				// supermethod is original method
				supermethod = [originalMethodValue pointerValue];
			}
			else {
				// supermethod is superclass's method
				Class superclass;
				REResponderOperation op;
				op = [blockInfo[kBlockInfoOperationKey] integerValue];
				superclass = [classHavingBlockinfo superclass];
				while (superclass && !supermethod) {
					if (op == REResponderOperationClass) {
						supermethod = method_getImplementation(class_getClassMethod(superclass, selector));
					}
					else {
						supermethod = method_getImplementation(class_getInstanceMethod(superclass, selector));
					}
					if (supermethod == imp) {
						supermethod = NULL;
					}
					superclass = [superclass superclass];
				}
			}
		}
		else {
			supermethod = [[blockInfos objectAtIndex:(index - 1)][kBlockInfoImpKey] pointerValue];
		}
	}
	if (supermethod == REResponderForwardingMethod()) {
		return NULL;
	}
	
	return supermethod;
}

+ (IMP)REResponder_supermethodWithImp:(IMP)imp
{
	// Filter
	if (self != [self class]) {
		return NULL;
	}
	
	return REResponderSupermethodWithImp(self, imp);
}

- (IMP)REResponder_supermethodWithImp:(IMP)imp
{
	// Filter
	if (self == [self class]) {
		return NULL;
	}
	
	return REResponderSupermethodWithImp(self, imp);
}

//--------------------------------------------------------------//
#pragma mark -- Block --
//--------------------------------------------------------------//

void REResponderSetBlockForSelector(id receiver, SEL selector, id inKey, id block, REResponderOperation op)
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Don't set block to private class
	if (op != REResponderOperationObject) {
		NSString *className;
		className = NSStringFromClass(receiver);
//		if ([className hasPrefix:kClassNamePrefix] || [className hasPrefix:@"__"]) { // Should I filter concreate class of class cluster ????? How can I distinct such classes ?????
		if ([className hasPrefix:kClassNamePrefix]) {
			// Search valid superclass
			Class superclass;
			superclass = [[receiver class] superclass];
			while (superclass) {
				if (![NSStringFromClass(superclass) hasPrefix:kClassNamePrefix]) {
					REResponderSetBlockForSelector(superclass, selector, inKey, block, op);
					return;
				}
			}
			return;
		}
	}
	
	// Get key
	id key;
	key = (inKey ? inKey : REUUIDString());
	
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
	@synchronized (receiver) {
		// Get elements
		NSMutableDictionary *blocks;
		NSMutableArray *blockInfos;
		NSDictionary *oldBlockInfo;
		IMP oldBlockMethod;
		IMP currentMethod;
		blocks = REResponderBlocks(receiver, op, YES);
		oldBlockInfo = [receiver REResponder_blockInfoForSelector:selector key:key blockInfos:&blockInfos operation:op];
		oldBlockMethod = [oldBlockInfo[kBlockInfoImpKey] pointerValue];
		if (op == REResponderOperationInstances) {
			currentMethod = [receiver instanceMethodForSelector:selector];
		}
		else {
			currentMethod = [receiver methodForSelector:selector];
		}
		
		// Make blockInfos
		if (!blockInfos) {
			blockInfos = [NSMutableArray array];
			[blockInfos setAssociatedValue:methodSignature forKey:kBlockInfosMethodSignatureAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			if (op == REResponderOperationClass) {
				if (currentMethod
					&& currentMethod != REResponderForwardingMethod()
					&& currentMethod != [[receiver superclass] methodForSelector:selector]
				){
					[blockInfos setAssociatedValue:[NSValue valueWithPointer:currentMethod] forKey:kBlockInfosOriginalMethodAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				}
			}
			else if (op == REResponderOperationInstances) {
				if (currentMethod
					&& currentMethod != REResponderForwardingMethod()
					&& currentMethod != [[receiver superclass] instanceMethodForSelector:selector]
				){
					[blockInfos setAssociatedValue:[NSValue valueWithPointer:currentMethod] forKey:kBlockInfosOriginalMethodAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				}
			}
			[blocks setObject:blockInfos forKey:selectorName];
		}
		
		// Become subclass
		if (op == REResponderOperationObject) {
			if (![NSStringFromClass([receiver class]) hasPrefix:kClassNamePrefix]) {
				Class originalClass;
				Class subclass;
				NSString *className;
				originalClass = [receiver class];
				className = [NSString stringWithFormat:@"%@_%@_%@", kClassNamePrefix, REUUIDString(), NSStringFromClass([receiver class])];
				subclass = objc_allocateClassPair(originalClass, [className UTF8String], 0);
				objc_registerClassPair(subclass);
				[receiver willChangeClass:subclass];
				object_setClass(receiver, subclass);
				[receiver didChangeClass:originalClass];
			}
		}
		
		// Replace method
		IMP imp;
		imp = imp_implementationWithBlock(block);
		class_replaceMethod((op == REResponderOperationInstances ? receiver : object_getClass(receiver)), selector, imp, [objCTypes UTF8String]);
		
		// Replace method of subclasses
		if (op == REResponderOperationClass) {
			for (Class subclass in RESubclassesOfClass(receiver, NO)) {
// ?????
//				// Filter
//				NSString *subclassName;
//				subclassName = NSStringFromClass(subclass);
//				if ([subclassName hasPrefix:kClassNamePrefix]) {
//					continue;
//				}
				
				// Replace method
				IMP subImp;
				subImp = [subclass methodForSelector:selector];
				if (subImp == currentMethod || subImp == REResponderForwardingMethod()) {
					class_replaceMethod(object_getClass(subclass), selector, imp, [objCTypes UTF8String]);
				}
			}
		}
		else if (op == REResponderOperationInstances) {
			for (Class subclass in RESubclassesOfClass(receiver, NO)) {
// ?????
//				// Filter
//				NSString *subclassName;
//				subclassName = NSStringFromClass(subclass);
//				if ([subclassName hasPrefix:kClassNamePrefix]) {
//					continue;
//				}
				
				// Replace
				IMP subImp;
				subImp = [subclass instanceMethodForSelector:selector];
				if (subImp == currentMethod || subImp == REResponderForwardingMethod()) {
					class_replaceMethod(subclass, selector, imp, [objCTypes UTF8String]);
				}
			}
		}
		
		// Remove oldBlockInfo
		if (oldBlockInfo) {
			[blockInfos removeObject:oldBlockInfo];
			imp_removeBlock(oldBlockMethod);
		}
		
		// Add blockInfo
		NSDictionary *blockInfo;
		blockInfo = @{
			kBlockInfoImpKey : [NSValue valueWithPointer:imp],
			kBlockInfoKeyKey : key,
			kBlockInfoOperationKey : @(op),
		};
		[blockInfos addObject:blockInfo];
	}
}

+ (void)setBlockForSelector:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationClass);
}

+ (void)setBlockForInstanceMethodForSelector:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationInstances);
}

- (void)setBlockForSelector:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self == [self class]) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationObject);
}

BOOL REResponderHasBlockForSelector(id receiver, SEL selector, id key, REResponderOperation op)
{
	// Filter
	if (!selector || !key) {
		return NO;
	}
	
	@synchronized (receiver) {
		// Get block
		IMP blockImp;
		
		// Get blockInfo
		NSDictionary *blockInfo;
		blockInfo = [receiver REResponder_blockInfoForSelector:selector key:key blockInfos:nil operation:op];
		blockImp = [blockInfo[kBlockInfoImpKey] pointerValue];
		
		return (blockImp != NULL);
	}
}

+ (BOOL)hasBlockForSelector:(SEL)selector key:(id)key
{
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationClass);
}

+ (BOOL)hasBlockForInstanceMethodForSelector:(SEL)selector key:(id)key
{
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationInstances);
}

- (BOOL)hasBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (self == [self class]) {
		return NO;
	}
	
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationObject);
}

void REResponderRemoveBlockForSelector(id receiver, SEL selector, id key, REResponderOperation op)
{
	// Filter
	if (!selector
		|| !key
		|| (op == REResponderOperationInstances && ![receiver hasBlockForInstanceMethodForSelector:selector key:key])
		|| (op != REResponderOperationInstances && ![receiver hasBlockForSelector:selector key:key])
	){
		return;
	}
	
	// Remove
	@synchronized (receiver) {
		// Get elements
		IMP imp;
		IMP supermethod;
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = [receiver REResponder_blockInfoForSelector:selector key:key blockInfos:&blockInfos operation:op];
		if (!blockInfo || !blockInfos) {
			return;
		}
		imp = [blockInfo[kBlockInfoImpKey] pointerValue];
		supermethod = [receiver REResponder_supermethodWithImp:imp];
		if (!supermethod) {
			supermethod = REResponderForwardingMethod();
		}
		
		// Replace method
		if (blockInfo == [blockInfos lastObject]) {
			// Get objCTypes
			const char *objCTypes;
			objCTypes = [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes];
			
			// Replace method of receiver
			class_replaceMethod((op == REResponderOperationInstances ? receiver : object_getClass(receiver)), selector, supermethod, objCTypes);
			
			// Replace method of subclasses
			if (op == REResponderOperationClass) {
				for (Class subclass in RESubclassesOfClass(receiver, NO)) {
					if ([subclass methodForSelector:selector] == imp) {
						class_replaceMethod(object_getClass(subclass), selector, supermethod, objCTypes);
					}
				}
			}
			else if (op == REResponderOperationInstances) {
				for (Class subclass in RESubclassesOfClass(receiver, NO)) {
					if ([subclass instanceMethodForSelector:selector] == imp) {
						class_replaceMethod(subclass, selector, supermethod, objCTypes);
					}
				}
			}
		}
		
		// Remove implementation which causing releasing block as well
		imp_removeBlock(imp);
		
		// Remove blockInfo
		[blockInfos removeObject:blockInfo];
		
		// Remove blockInfos
		if (![blockInfos count]) {
			NSMutableDictionary *blocks;
			blocks = REResponderBlocks(receiver, op, NO);
			[blocks removeObjectForKey:NSStringFromSelector(selector)];
		}
	}
}

+ (void)removeBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationClass);
}

+ (void)removeBlockForInstanceMethodForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationInstances);
}

- (void)removeBlockForSelector:(SEL)selector key:(id)key
{
	// Filter
	if (self == [self class]) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationObject);
}

//--------------------------------------------------------------//
#pragma mark -- Current Block --
//--------------------------------------------------------------//

IMP REResponderSupermethodOfCurrentBlock(id receiver)
{
	// Get supermethod
	IMP supermethod;
	IMP imp;
	imp = REResponderImplementationWithBacktraceDepth(3);
	supermethod = [receiver REResponder_supermethodWithImp:imp];
	
	return supermethod;
}

+ (IMP)supermethodOfCurrentBlock
{
	return REResponderSupermethodOfCurrentBlock(self);
}

- (IMP)supermethodOfCurrentBlock
{
	return REResponderSupermethodOfCurrentBlock(self);
}

void REResponderRemoveCurrentBlock(id receiver)
{
	// Get imp of current block
	IMP imp;
	imp = REResponderImplementationWithBacktraceDepth(3);
	if (!imp) {
		return;
	}
	
	// Get elements
	NSDictionary *blockInfo;
	SEL selector;
	blockInfo = [receiver REResponder_blockInfoWithImplementation:imp blockInfos:nil selector:&selector];
	if (!blockInfo || !selector) {
		return;
	}
	
	// Call removeBlockForSelector:forKey:
	[receiver removeBlockForSelector:selector key:blockInfo[kBlockInfoKeyKey]];
}

+ (void)removeCurrentBlock
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderRemoveCurrentBlock(self);
}

- (void)removeCurrentBlock
{
	// Filter
	if (self == [self class]) {
		return;
	}
	
	REResponderRemoveCurrentBlock(self);
}

//--------------------------------------------------------------//
#pragma mark -- Conformance --
//--------------------------------------------------------------//

void REResponderSetConformableToProtocol(id receiver, BOOL conformable, Protocol *protocol, id inKey)
{
	// Filter
	if (!protocol || (!conformable && !inKey)) {
		return;
	}
	
	// Get key
	id key;
	key = inKey ? inKey : REUUIDString();
	
	// Update REResponder_protocols
	@synchronized (receiver) {
		// Get elements
		NSString *protocolName;
		NSMutableDictionary *protocols;
		NSMutableDictionary *protocolInfo;
		protocolName = NSStringFromProtocol(protocol);
		protocols = [receiver associatedValueForKey:kProtocolsAssociationKey];
		protocolInfo = protocols[protocolName];
		
		// Add key
		if (conformable) {
			// Associate protocols
			if (!protocols) {
				protocols = [NSMutableDictionary dictionary];
				[receiver setAssociatedValue:protocols forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
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

+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)inKey
{
	// Filter
	if (self != [self class]) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, inKey);
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)inKey
{
	// Filter
	if (self == [self class]) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, inKey);
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
