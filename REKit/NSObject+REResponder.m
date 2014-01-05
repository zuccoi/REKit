/*
 REResponder.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "NSObject+REResponder.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kClassNamePrefix = @"REResponder";
static NSString* const kProtocolsAssociationKey = @"REResponder_protocols";
static NSString* const kClassMethodBlocksAssociationKey = @"REResponder_classMethodBlocks";
static NSString* const kInstanceMethodBlocksAssociationKey = @"REResponder_instanceMethodBlocks";
static NSString* const kBlockInfosMethodSignatureAssociationKey = @"methodSignature";
static NSString* const kBlockInfosOriginalMethodAssociationKey = @"originalMethod";

// Keys for protocolInfo
static NSString* const kProtocolInfoKeysKey = @"keys";
static NSString* const kProtocolInfoIncorporatedProtocolNamesKey = @"incorporatedProtocolNames";

// Keys for blockInfo
static NSString* const kBlockInfoImpKey = @"imp";
static NSString* const kBlockInfoKeyKey = @"key";
static NSString* const kBlockInfoOperationKey = @"op";

// REResponderOperationMask
typedef NS_OPTIONS(NSUInteger, REResponderOperationMask) {
	REResponderOperationInstanceMethodMask = (1UL << 0),
	REResponderOperationObjectTargetMask = (1UL << 1),
};

// REResponderOperation
typedef NS_ENUM(NSInteger, REResponderOperation) {
	REResponderOperationClassMethodOfClass,
	REResponderOperationInstanceMethodOfClass,
	REResponderOperationClassMethodOfObject,
	REResponderOperationInstanceMethodOfObject,
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
	if (self != REGetClass(self)) {
		return NO;
	}
	
	// Conforms?
	BOOL conforms = NO;
	Class class;
	class = self;
	while (!conforms && class) {
		conforms = REREsponderConformsToProtocol(class, protocol);
		class = REGetSuperclass(class);
	}
	
	return conforms;
}

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (self == REGetClass(self)) {
		return NO;
	}
	
	return (REREsponderConformsToProtocol(self, protocol) || [REGetClass(self) conformsToProtocol:protocol]);
}

BOOL REResponderRespondsToSelector(id receiver, SEL aSelector, REResponderOperation op)
{
	@synchronized (receiver) {
		BOOL responds;
		if (op & REResponderOperationInstanceMethodMask) {
			responds = [REGetClass(receiver) REResponder_X_instancesRespondToSelector:aSelector];
			if (responds) {
				// Forwarding method?
				if ([REGetClass(receiver) instanceMethodForSelector:aSelector] == REResponderForwardingMethod()) {
					responds = NO;
				}
			}
		}
		else {
			responds = [REGetClass(receiver) REResponder_X_respondsToSelector:aSelector];
			if (responds) {
				// Forwarding method?
				if ([REGetClass(receiver) methodForSelector:aSelector] == REResponderForwardingMethod()) {
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
	if (self != REGetClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationClassMethodOfClass);
}

+ (BOOL)REResponder_X_instancesRespondToSelector:(SEL)aSelector
{
	// Filter
	if (self != REGetClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationInstanceMethodOfClass);
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Filter
	if (self == REGetClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationInstanceMethodOfObject);
}

- (void)REResponder_X_dealloc
{
	@autoreleasepool {
		@synchronized (self) {
			// Remove protocols
			[self setAssociatedValue:nil forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			
			// Remove blocks
			NSDictionary *blocks;
			if ([NSStringFromClass(REGetClass(self)) hasPrefix:kClassNamePrefix]) {
				blocks = [NSDictionary dictionaryWithDictionary:REResponderGetBlocks(self, REResponderOperationClassMethodOfObject, NO)];
				[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
					while ([blockInfos count]) {
						NSDictionary *blockInfo;
						blockInfo = [blockInfos lastObject];
						[self removeBlockForClassMethod:NSSelectorFromString(selectorName) key:blockInfo[kBlockInfoKeyKey]];
					}
				}];
				[REGetClass(self) setAssociatedValue:nil forKey:kClassMethodBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				blocks = [NSDictionary dictionaryWithDictionary:REResponderGetBlocks(self, REResponderOperationInstanceMethodOfObject, NO)];
				[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
					while ([blockInfos count]) {
						NSDictionary *blockInfo;
						blockInfo = [blockInfos lastObject];
						[self removeBlockForInstanceMethod:NSSelectorFromString(selectorName) key:blockInfo[kBlockInfoKeyKey]];
					}
				}];
				[REGetClass(self) setAssociatedValue:nil forKey:kInstanceMethodBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Dispose classes
			NSString *className;
			className = NSStringFromClass(REGetClass(self));
			if ([className hasPrefix:kClassNamePrefix]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					Class class;
					class = NSClassFromString(className);
					for (Class aClass in RESubclassesOfClass(class, NO)) {
						objc_disposeClassPair(aClass);
					}
					objc_disposeClassPair(class);
				});
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
#pragma mark -- Block Management --
//--------------------------------------------------------------//

IMP REResponderForwardingMethod()
{
	return [NSObject methodForSelector:@selector(REResponder_UnexistingMethod)];
}

NSMutableDictionary* REResponderGetBlocks(id receiver, REResponderOperation op, BOOL create)
{
	NSMutableDictionary *blocks;
	NSString *key;
	key = (op & REResponderOperationInstanceMethodMask ? kInstanceMethodBlocksAssociationKey : kClassMethodBlocksAssociationKey);
	blocks = [REGetClass(receiver) associatedValueForKey:key];
	if (!blocks && create) {
		blocks = [NSMutableDictionary dictionary];
		[REGetClass(receiver) setAssociatedValue:blocks forKey:key policy:OBJC_ASSOCIATION_RETAIN];
	}
	
	return blocks;
}

NSDictionary* REResponderGetBlockInfoForSelector(id receiver, SEL selector, id key, NSMutableArray **outBlockInfos, REResponderOperation op)
{
	@synchronized (receiver) {
		// Get blockInfo
		__block NSDictionary *blockInfo = nil;
		NSMutableArray *blockInfos;
		NSMutableDictionary *blocks;
		blocks = REResponderGetBlocks(receiver, op, NO);
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

NSDictionary* REResponderGetBlockInfoWithImp(id receiver, IMP imp, NSMutableArray **outBlockInfos, SEL *outSelector)
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
		
		// Search blockInfo
		if (receiver != REGetClass(receiver)) {
			blockInfoBlock(REResponderGetBlocks(receiver, REResponderOperationInstanceMethodOfObject, NO));
		}
		if (blockInfo) {
			return blockInfo;
		}
		blockInfoBlock(REResponderGetBlocks(receiver, REResponderOperationClassMethodOfObject, NO));
		if (blockInfo) {
			return blockInfo;
		}
		blockInfoBlock(REResponderGetBlocks(REGetClass(receiver), REResponderOperationInstanceMethodOfClass, NO));
		if (blockInfo) {
			return blockInfo;
		}
//		blockInfoBlock(REResponderGetBlocks(REGetClass(receiver), REResponderOperationClassMethodOfClass, NO)); // Not needed 'cos blocks is associated with class instance
		
		return blockInfo;
	}
}

IMP REResponderGetSupermethodWithImp(id receiver, IMP imp)
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
		blockInfo = REResponderGetBlockInfoWithImp(receiver, imp, &blockInfos, &selector);
		if (blockInfo) {
			classHavingBlockinfo = REGetClass(receiver);
		}
		else {
			// Search blockInfo of superclasses
			Class superclass;
			superclass = REGetSuperclass(receiver);
			while (superclass) {
				blockInfo = REResponderGetBlockInfoWithImp(superclass, imp, &blockInfos, &selector);
				if (blockInfo) {
					classHavingBlockinfo = superclass;
					break;
				}
				superclass = REGetSuperclass(superclass);
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
				superclass = REGetSuperclass(classHavingBlockinfo);
				while (superclass && !supermethod) {
					if (op & REResponderOperationInstanceMethodMask) {
						supermethod = method_getImplementation(class_getInstanceMethod(superclass, selector));
					}
					else {
						supermethod = method_getImplementation(class_getClassMethod(superclass, selector));
					}
					if (supermethod == imp) {
						supermethod = NULL;
					}
					superclass = REGetSuperclass(superclass);
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

void REResponderSetBlockForSelector(id receiver, SEL selector, id key, id block, REResponderOperation op)
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Update blocks
	@synchronized (receiver) {
		// Don't set block to private class
		if (!(op & REResponderOperationObjectTargetMask)) {
			NSString *className;
			className = NSStringFromClass(REGetClass(receiver));
			if ([className hasPrefix:kClassNamePrefix]) { // Should I filter concreate class of class cluster ????? How can I distinct such classes ?????
				// Search valid superclass
				Class superclass;
				superclass = REGetSuperclass(receiver);
				while (superclass) {
					if (![NSStringFromClass(superclass) hasPrefix:kClassNamePrefix]) {
						REResponderSetBlockForSelector(superclass, selector, key, block, op);
						return;
					}
				}
				return;
			}
		}
		
		// Get key
		key = (key ? key : REUUIDString());
		
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
		
		// Become subclass
		Class originalClass = NULL;
		if (op & REResponderOperationObjectTargetMask && [NSStringFromClass(REGetClass(receiver)) rangeOfString:kClassNamePrefix].location == NSNotFound) {
			Class subclass;
			NSString *className;
			originalClass = [receiver class]; // Use class method to avoid getting NSKVONotifying_ class
			className = [NSString stringWithFormat:@"%@_%@_%@", kClassNamePrefix, REUUIDString(), NSStringFromClass(originalClass)];
			subclass = objc_allocateClassPair(originalClass, [className UTF8String], 0);
			objc_registerClassPair(subclass);
			object_setClass(receiver, subclass);
		}
		
		// Get elements
		NSMutableDictionary *blocks;
		NSMutableArray *blockInfos;
		NSDictionary *oldBlockInfo;
		IMP oldImp;
		IMP currentImp;
		Class class, metaClass, superclass;
		class = REGetClass(receiver);
		while (class) {
			if (![NSStringFromClass(class) hasPrefix:@"NSKVONotifying_"]) {
				break;
			}
			class = REGetSuperclass(class);
		}
		metaClass = REGetMetaClass(class);
		superclass = REGetSuperclass(class);
		blocks = REResponderGetBlocks(receiver, op, YES);
		oldBlockInfo = REResponderGetBlockInfoForSelector(receiver, selector, key, &blockInfos, op);
		oldImp = [oldBlockInfo[kBlockInfoImpKey] pointerValue];
		if (op & REResponderOperationInstanceMethodMask) {
			currentImp = [class instanceMethodForSelector:selector];
		}
		else {
			currentImp = [class methodForSelector:selector];
		}
		
		// Make blockInfos
		if (!blockInfos) {
			blockInfos = [NSMutableArray array];
			[blockInfos setAssociatedValue:methodSignature forKey:kBlockInfosMethodSignatureAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			if (op & REResponderOperationInstanceMethodMask) {
				if (currentImp
					&& currentImp != REResponderForwardingMethod()
					&& currentImp != [superclass instanceMethodForSelector:selector]
				){
					[blockInfos setAssociatedValue:[NSValue valueWithPointer:currentImp] forKey:kBlockInfosOriginalMethodAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				}
			}
			else {
				if (currentImp
					&& currentImp != REResponderForwardingMethod()
					&& currentImp != [superclass methodForSelector:selector]
				){
					[blockInfos setAssociatedValue:[NSValue valueWithPointer:currentImp] forKey:kBlockInfosOriginalMethodAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				}
			}
			[blocks setObject:blockInfos forKey:selectorName];
		}
		
		// Get originalClassMethod // Rename >>>
		IMP originalClassMethod;
		originalClassMethod = [class methodForSelector:selector];
		if (originalClassMethod == [superclass methodForSelector:selector]) {
			originalClassMethod = NULL;
		}
		
		// Replace method
		IMP imp;
		imp = imp_implementationWithBlock(block);
		class_replaceMethod((op & REResponderOperationInstanceMethodMask ? class : metaClass), selector, imp, [objCTypes UTF8String]);
		if (op & REResponderOperationInstanceMethodMask && originalClassMethod) {
			class_replaceMethod(metaClass, selector, originalClassMethod, [objCTypes UTF8String]);
		}
		
		// Replace method of subclasses
		if (op & REResponderOperationInstanceMethodMask) {
			for (Class subclass in RESubclassesOfClass(class, NO)) {
				// Replace
				IMP subImp;
				subImp = [subclass instanceMethodForSelector:selector];
				if (subImp == currentImp || subImp == REResponderForwardingMethod()) { // When subclass is NSKVONotifying_, subImp of test_dynamicBlockAfterKVO method is not currentImp (forward). So it is not replaced!!! Check class method of NSKVONotifying_REResponder_ class >>>
					class_replaceMethod(subclass, selector, imp, [objCTypes UTF8String]);
				}
			}
		}
		else {
			for (Class subclass in RESubclassesOfClass(class, NO)) {
				// Replace method
				IMP subImp;
				subImp = [subclass methodForSelector:selector];
				if (subImp == currentImp || subImp == REResponderForwardingMethod()) {
					class_replaceMethod(REGetMetaClass(subclass), selector, imp, [objCTypes UTF8String]);
				}
			}
		}
		
		// Remove oldBlockInfo
		if (oldBlockInfo) {
			[blockInfos removeObject:oldBlockInfo];
			imp_removeBlock(oldImp);
		}
		
		// Add blockInfo
		NSDictionary *blockInfo;
		blockInfo = @{
			kBlockInfoImpKey : [NSValue valueWithPointer:imp],
			kBlockInfoKeyKey : key,
			kBlockInfoOperationKey : @(op),
		};
		[blockInfos addObject:blockInfo];
		
		// Override methods
		if (originalClass) {
			// Get originalClassName
			NSString *originalClassName;
			originalClassName = NSStringFromClass(originalClass);
			
			// Override class
			[receiver setBlockForInstanceMethod:@selector(class) key:nil block:^(id receiver) {
				return NSClassFromString(originalClassName);
			}];
			
			// Override superclass
			[receiver setBlockForInstanceMethod:@selector(superclass) key:nil block:^(id receiver) {
				return [[receiver class] superclass];
			}];
			
			// Override classForCoder
			[receiver setBlockForInstanceMethod:@selector(classForCoder) key:nil block:^(id receiver) {
				IMP superImp;
				Class realSuperclass;
				realSuperclass = REGetSuperclass(receiver);
				superImp = (IMP)class_getInstanceMethod(realSuperclass, @selector(classForCoder));
				if (superImp) {
					return (REIMP(Class)superImp)(receiver, @selector(classForCoder));
				}
				else {
					return RESupermethod(NSClassFromString(originalClassName), receiver, @selector(classForCoder));
				}
			}];
		}
	}
}

BOOL REResponderHasBlockForSelector(id receiver, SEL selector, id key, REResponderOperation op)
{
	// Filter
	if (!selector || !key) {
		return NO;
	}
	
	@synchronized (receiver) {
		// Check imp
		IMP imp;
		NSDictionary *blockInfo;
		blockInfo = REResponderGetBlockInfoForSelector(receiver, selector, key, nil, op);
		imp = [blockInfo[kBlockInfoImpKey] pointerValue];
		
		return (imp != NULL);
	}
}

void REResponderRemoveBlockWithBlockInfo(id receiver, NSDictionary *blockInfo, NSMutableArray *blockInfos, SEL selector, REResponderOperation op)
{
	// Filter
	if (!receiver || !blockInfo || !blockInfos || !selector) {
		return;
	}
	
	// Remove
	@synchronized (receiver) {
		IMP imp;
		IMP supermethod;
		imp = [blockInfo[kBlockInfoImpKey] pointerValue];
		supermethod = REResponderGetSupermethodWithImp(receiver, imp);
		if (!supermethod) {
			supermethod = REResponderForwardingMethod();
		}
		
		// Replace method
		if (blockInfo == [blockInfos lastObject]) {
			// Get elements
			const char *objCTypes;
			Class class, metaClass;
			objCTypes = [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes];
			class = REGetClass(receiver);
			metaClass = REGetMetaClass(receiver);
			
			// Replace method of receiver
			class_replaceMethod((op & REResponderOperationInstanceMethodMask ? class : metaClass), selector, supermethod, objCTypes);
			
			// Replace method of subclasses
			if (op & REResponderOperationInstanceMethodMask) {
				for (Class subclass in RESubclassesOfClass(class, NO)) {
					if ([subclass instanceMethodForSelector:selector] == imp) {
						class_replaceMethod(subclass, selector, supermethod, objCTypes);
					}
				}
			}
			else {
				for (Class subclass in RESubclassesOfClass(class, NO)) {
					if ([subclass methodForSelector:selector] == imp) {
						class_replaceMethod(object_getClass(subclass), selector, supermethod, objCTypes);
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
			blocks = REResponderGetBlocks(receiver, op, NO);
			[blocks removeObjectForKey:NSStringFromSelector(selector)];
		}
	}
}

void REResponderRemoveBlockForSelector(id receiver, SEL selector, id key, REResponderOperation op)
{
	// Filter
	if (!selector || !key) {
		return;
	}
	
	// Remove
	@synchronized (receiver) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		blockInfo = REResponderGetBlockInfoForSelector(receiver, selector, key, &blockInfos, op);
		REResponderRemoveBlockWithBlockInfo(receiver, blockInfo, blockInfos, selector, op);
	}
}

//--------------------------------------------------------------//
#pragma mark -- Block Management for Class --
//--------------------------------------------------------------//

+ (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationClassMethodOfClass);
}

+ (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationInstanceMethodOfClass);
}

+ (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key
{
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationClassMethodOfClass);
}

+ (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key
{
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfClass);
}

+ (void)removeBlockForClassMethod:(SEL)selector key:(id)key
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationClassMethodOfClass);
}

+ (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfClass);
}

//--------------------------------------------------------------//
#pragma mark -- Block Management for Specific Instance --
//--------------------------------------------------------------//

- (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationClassMethodOfObject);
}

- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationInstanceMethodOfObject);
}

- (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key
{
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationClassMethodOfObject);
}

- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (self == REGetClass(self)) {
		return NO;
	}
	
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfObject);
}

- (void)removeBlockForClassMethod:(SEL)selector key:(id)key
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationClassMethodOfObject);
}

- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfObject);
}

//--------------------------------------------------------------//
#pragma mark -- Current Block Management --
//--------------------------------------------------------------//

void REResponderRemoveCurrentBlock(id receiver)
{
	// Get imp of current block
	IMP imp;
	imp = REImplementationWithBacktraceDepth(3);
	if (!imp) {
		return;
	}
	
	// Get elements
	NSDictionary *blockInfo;
	NSMutableArray *blockInfos;
	SEL selector;
	blockInfo = REResponderGetBlockInfoWithImp(receiver, imp, &blockInfos, &selector);
	if (!blockInfo || !selector) {
		return;
	}
	
	// Call REResponderRemoveBlock
	REResponderOperation op;
	op = [blockInfo[kBlockInfoOperationKey] integerValue];
	if (!(op & REResponderOperationObjectTargetMask)) {
		receiver = REGetClass(receiver);
	}
	REResponderRemoveBlockWithBlockInfo(receiver, blockInfo, blockInfos, selector, op);
}

+ (void)removeCurrentBlock
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderRemoveCurrentBlock(self);
}

- (void)removeCurrentBlock
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderRemoveCurrentBlock(self);
}

//--------------------------------------------------------------//
#pragma mark -- Conformance --
//--------------------------------------------------------------//

void REResponderSetConformableToProtocol(id receiver, BOOL conformable, Protocol *protocol, id key)
{
	// Filter
	if (!protocol || (!conformable && !key)) {
		return;
	}
	
	// Get key
	key = key ? key : REUUIDString();
	
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

+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key
{
	// Filter
	if (self != REGetClass(self)) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, key);
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key
{
	// Filter
	if (self == REGetClass(self)) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, key);
}

@end

#pragma mark -


@interface NSObject (REResponderPrivate)
+ (IMP)supermethodOfCurrentBlock;
@end

@implementation NSObject (REResponderPrivate)

IMP REResponderSupermethodOfCurrentBlock(id receiver)
{
	// Get supermethod
	IMP supermethod;
	IMP imp;
	imp = REImplementationWithBacktraceDepth(3);
	supermethod = REResponderGetSupermethodWithImp(receiver, imp);
	
	return supermethod;
}

+ (IMP)supermethodOfCurrentBlock
{
	return REResponderSupermethodOfCurrentBlock(self);
}

@end

#pragma mark -


@implementation NSObject (REResponder_Depricated)

- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated))
{
	[self setBlockForInstanceMethod:selector key:key block:block];
}

- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	return [self hasBlockForInstanceMethod:selector key:key];
}

- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	[self removeBlockForInstanceMethod:selector key:key];
}

- (IMP)supermethodOfCurrentBlock
{
	return REResponderSupermethodOfCurrentBlock(self);
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated))
{
	[self setConformable:conformable toProtocol:protocol key:key];
}

@end
