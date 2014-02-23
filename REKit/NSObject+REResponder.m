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
static NSString* const kPrivateClassNamePrefix = @"REResponder";
static NSString* const kProtocolsAssociationKey = @"REResponder_protocols";
static NSString* const kClassMethodBlocksAssociationKey = @"REResponder_classMethodBlocks";
static NSString* const kInstanceMethodBlocksAssociationKey = @"REResponder_instanceMethodBlocks";
static NSString* const kBlockInfosMethodSignatureAssociationKey = @"methodSignature";
static NSString* const kBlockInfosOriginalMethodAssociationKey = @"originalMethod";
static NSString* const kIsChangingClassBySelfAssociationKey = @"REResponder_isChangingClassBySelf"; // Tests >>>
static NSString* const kIsChangingClassAssociationKey = @"REResponder_isChangingClass"; // Tests >>>
static NSString* const kReturnAddress_BlockInfoKey = @"REREsponder_ReturnAddress_BlockInfoKey";

// Keys for protocolInfo
static NSString* const kProtocolInfoKeysKey = @"keys";
static NSString* const kProtocolInfoIncorporatedProtocolNamesKey = @"incorporatedProtocolNames";

// Keys for blockInfo
static NSString* const kBlockInfoSelectorKey = @"sel";
static NSString* const kBlockInfoImpKey = @"imp";
static NSString* const kBlockInfoKeyKey = @"key";
static NSString* const kBlockInfoOperationKey = @"op";
static NSString* const kBlockInfoReturnAddressKey = @"radd";

// REResponderOperationMask
typedef NS_OPTIONS(NSUInteger, REResponderOperationMask) {
	REResponderOperationInstanceMethodMask = (1UL << 0),
	REResponderOperationObjectTargetMask = (1UL << 1),
};

// REResponderOperation
typedef NS_ENUM(NSInteger, REResponderOperation) {
	REResponderOperationClassMethodOfClass = 0,
	REResponderOperationInstanceMethodOfClass = REResponderOperationInstanceMethodMask,
	REResponderOperationInstanceMethodOfObject = (REResponderOperationInstanceMethodMask | REResponderOperationObjectTargetMask),
};

// Global Variables
static NSMutableDictionary *_returnAddress_blockInfo = nil;


@implementation NSObject (REResponder)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

BOOL REResponderConformsToProtocol(id receiver, Protocol *protocol)
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
	if (!REIsClass(self)) {
		return NO;
	}
	
	// Conforms?
	BOOL conforms = NO;
	Class class;
	class = self;
	while (!conforms && class) {
		conforms = REResponderConformsToProtocol(class, protocol);
		class = REGetSuperclass(class);
	}
	
	return conforms;
}

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)protocol
{
	// Filter
	if (REIsClass(self)) {
		return NO;
	}
	
	return (REResponderConformsToProtocol(self, protocol) || [REGetClass(self) conformsToProtocol:protocol]);
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
	if (!REIsClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationClassMethodOfClass);
}

+ (BOOL)REResponder_X_instancesRespondToSelector:(SEL)aSelector
{
	// Filter
	if (!REIsClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationInstanceMethodOfClass);
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Filter
	if (REIsClass(self)) {
		return NO;
	}
	
	return REResponderRespondsToSelector(self, aSelector, REResponderOperationInstanceMethodOfObject);
}

- (void)REResponder_X_willChangeClass:(NSString*)toClassName
{
	if (![self REResponder_isChangingClassBySelf]
		&& ![[self associatedValueForKey:kIsChangingClassAssociationKey] boolValue]
	){
		// Raise flag
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		
		// Revert object-target methods
		if (REResponderIsPrivateClass(self)) {
			// Revert instance methods
			NSDictionary *blocks;
			blocks = [NSDictionary dictionaryWithDictionary:REResponderGetBlocks(self, REResponderOperationInstanceMethodOfObject, NO)];
			[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
				// Filter
				if (![blockInfos count]) {
					return;
				}
				
				// Revert to originalImp
				IMP originalImp;
				NSDictionary *firstBlockInfo;
				firstBlockInfo = [blockInfos firstObject];
				originalImp = REResponderGetSupermethod(self, NSSelectorFromString(selectorName), firstBlockInfo[kBlockInfoKeyKey], REResponderOperationInstanceMethodOfObject);
				if (!originalImp) {
					originalImp = REResponderForwardingMethod();
				}
				REResponderReplaceImp(self, NSSelectorFromString(selectorName), originalImp, [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes], REResponderOperationInstanceMethodOfObject);
			}];
		}
	}
	
	// original
	[self REResponder_X_willChangeClass:toClassName];
}

- (void)REResponder_X_didChangeClass:(NSString*)fromClassName
{
	if (![self REResponder_isChangingClassBySelf]) {
		// Restore instance methods
		NSDictionary *blocks;
		blocks = [NSDictionary dictionaryWithDictionary:REResponderGetBlocks(self, REResponderOperationInstanceMethodOfObject, NO)];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
			// Filter
			if (![blockInfos count]) {
				return;
			}
			
			// Apply newestImp
			IMP newestImp;
			newestImp = [[blockInfos lastObject][kBlockInfoImpKey] pointerValue];
			REResponderReplaceImp(self, NSSelectorFromString(selectorName), newestImp, [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes], REResponderOperationInstanceMethodOfObject);
		}];
	}
	
	// original
	[self REResponder_X_didChangeClass:fromClassName];
	
	// Down isChangingClass flag
	[self setAssociatedValue:nil forKey:kIsChangingClassAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
}

- (void)REResponder_X_dealloc
{
	@autoreleasepool {
		// Reset
		@synchronized (self) {
#if TARGET_OS_IPHONE
			if (REResponderIsPrivateClass(self)) {
				// Get className
				NSString *className;
				className = NSStringFromClass(REGetClass(self));
#endif
				// Remove blocks
				NSDictionary *blocks;
				blocks = [NSDictionary dictionaryWithDictionary:REResponderGetBlocks(self, REResponderOperationInstanceMethodOfObject, NO)];
				[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSMutableArray *blockInfos, BOOL *stop) {
					if (![selectorName isEqualToString:@"class"]) {
						while ([blockInfos count]) {
							NSDictionary *blockInfo;
							blockInfo = [blockInfos lastObject];
							[self removeBlockForInstanceMethod:NSSelectorFromString(selectorName) key:blockInfo[kBlockInfoKeyKey]];
						}
					}
				}];
				while ([blocks[@"class"] count]) {
					NSDictionary *blockInfo;
					blockInfo = [blocks[@"class"] lastObject];
					[self removeBlockForInstanceMethod:@selector(class) key:blockInfo[kBlockInfoKeyKey]];
				}
				[self setAssociatedValue:nil forKey:kInstanceMethodBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				
				// Dispose class later
#if TARGET_OS_IPHONE
				dispatch_async(dispatch_get_main_queue(), ^{
					Class class;
					Class aClass;
					class = NSClassFromString(className);
					aClass = class;
					while ([NSStringFromClass(aClass) rangeOfString:kPrivateClassNamePrefix].location != NSNotFound) {
						Class superclass;
						superclass = REGetSuperclass(aClass);
						[aClass setAssociatedValue:nil forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
						[aClass setAssociatedValue:nil forKey:kClassMethodBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
						[aClass setAssociatedValue:nil forKey:kInstanceMethodBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
						objc_disposeClassPair(aClass);
						aClass = superclass;
					}
				});
			}
#endif
#if TARGET_OS_MAC
// Not Implemented >>>
#endif
		}
		
		// original
		[self REResponder_X_dealloc];
	}
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
			@selector(willChangeClass:),
			@selector(didChangeClass:),
			@selector(dealloc),
			nil
		];
	}
}

//--------------------------------------------------------------//
#pragma mark -- Util --
//--------------------------------------------------------------//

- (BOOL)REResponder_isChangingClassBySelf
{
	return [[self associatedValueForKey:kIsChangingClassBySelfAssociationKey] boolValue];
}

- (void)REResponder_setChangingClassBySelf:(BOOL)flag
{
	id value;
	value = (flag ? @(YES) : nil);
	[self setAssociatedValue:value forKey:kIsChangingClassBySelfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
}

//--------------------------------------------------------------//
#pragma mark -- Block Management --
//--------------------------------------------------------------//

IMP REResponderForwardingMethod()
{
	return [NSObject methodForSelector:NSSelectorFromString(@"REResponder_UnexistingMethod")];
}

BOOL REResponderIsPrivateClass(id receiver)
{
	return ([NSStringFromClass(REGetClass(receiver)) rangeOfString:kPrivateClassNamePrefix].location != NSNotFound);
}

NSMutableDictionary* REResponderGetBlocks(id receiver, REResponderOperation op, BOOL create)
{
	NSMutableDictionary *blocks;
	NSString *key;
	key = (op & REResponderOperationInstanceMethodMask ? kInstanceMethodBlocksAssociationKey : kClassMethodBlocksAssociationKey);
	blocks = [receiver associatedValueForKey:key];
	if (!blocks && create) {
		blocks = [NSMutableDictionary dictionary];
		[receiver setAssociatedValue:blocks forKey:key policy:OBJC_ASSOCIATION_RETAIN];
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

NSDictionary* REResponderGetBlockInfoWithImp(id receiver, IMP imp, NSMutableArray **outBlockInfos)
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
					if (outBlockInfos) {
						*outBlockInfos = aBlockInfos;
					}
					*stopA = YES;
				}
			}];
		};
		
		// Search blockInfo of object
		if (!REIsClass(receiver)) {
			blockInfoBlock(REResponderGetBlocks(receiver, REResponderOperationInstanceMethodOfObject, NO));
		}
		if (blockInfo) {
			return blockInfo;
		}
		
		// Search blockInfo of class
		Class class;
		class = REGetClass(receiver);
		blockInfoBlock(REResponderGetBlocks(class, REResponderOperationInstanceMethodOfClass, NO));
		if (!blockInfo) {
			blockInfoBlock(REResponderGetBlocks(class, REResponderOperationClassMethodOfClass, NO));
		}
		if (blockInfo) {
			return blockInfo;
		}
		
		return nil;
	}
}

IMP REResponderReplaceImp(id receiver, SEL selector, IMP imp, const char *objCTypes, REResponderOperation op)
{
	// Get class
	Class class;
	Class metaClass;
	class = REGetClass(receiver);
	metaClass = REGetMetaClass(receiver);
	
	// Get oldImp
	IMP originalImp = NULL;
	if (op & REResponderOperationInstanceMethodMask) {
		originalImp = [class instanceMethodForSelector:selector];
	}
	else {
		originalImp = [class methodForSelector:selector];
	}
	
	// Replace method
	if (op & REResponderOperationInstanceMethodMask) {
		// Get originalClassImp
		IMP originalClassImp;
		originalClassImp = [class methodForSelector:selector];
		
		// Replace
		class_replaceMethod(class, selector, imp, objCTypes);
		
		// Revert class method
		class_replaceMethod(metaClass, selector, originalClassImp, objCTypes);
	}
	else {
		// Replace
		class_replaceMethod(metaClass, selector, imp, objCTypes);
	}
	
	return originalImp;
}

void REResponderSetBlockForSelector(id receiver, SEL selector, id key, id block, REResponderOperation op)
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Update blocks
	@synchronized (receiver) {
		// Don't set class-target block to private class
		if (!(op & REResponderOperationObjectTargetMask)) {
			if (REResponderIsPrivateClass(receiver)) { // Should I filter concreate class of class cluster ????? How can I distinct such classes ????? // Should I filter NSKVONotifying_ class ?????
				// Search valid superclass
				Class superclass;
				superclass = REGetSuperclass(receiver);
				while (superclass) {
					if (!REResponderIsPrivateClass(superclass)) {
						REResponderSetBlockForSelector(superclass, selector, key, block, op);
						return;
					}
					superclass = REGetSuperclass(superclass);
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
		if (op & REResponderOperationObjectTargetMask && !REResponderIsPrivateClass(receiver)) {
			Class subclass;
			NSString *className;
			Class originalClass;
			originalClass = [receiver class]; // Use class method to avoid getting NSKVONotifying_ class
			className = [NSString stringWithFormat:@"%@(%@_%@)", NSStringFromClass(originalClass), kPrivateClassNamePrefix, REUUIDString()];
			subclass = objc_allocateClassPair(originalClass, [className UTF8String], 0);
			objc_registerClassPair(subclass);
			[receiver REResponder_setChangingClassBySelf:YES];
			object_setClass(receiver, subclass);
			[receiver REResponder_setChangingClassBySelf:NO];
			
			// Get originalClassName
			NSString *originalClassName;
			originalClassName = NSStringFromClass(originalClass);
			
			// Override class method
			Class (^classBlock)(id receiver);
			classBlock = ^(id receiver) {
				return NSClassFromString(originalClassName);
			};
			REResponderSetBlockForSelector(receiver, @selector(class), nil, classBlock, REResponderOperationInstanceMethodOfObject);
		}
		
		// Get elements
		NSMutableDictionary *blocks;
		NSMutableArray *blockInfos;
		NSDictionary *oldBlockInfo;
		IMP oldImp;
		IMP currentImp;
		Class class, superclass;
		class = REGetClass(receiver);
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
		
		// Replace method
		IMP imp;
		imp = imp_implementationWithBlock(block);
		REResponderReplaceImp(class, selector, imp, [objCTypes UTF8String], op);
		
		// Replace method of subclasses
		if (op & REResponderOperationInstanceMethodMask) {
			for (Class subclass in RESubclassesOfClass(class, NO)) {
				// Replace
				IMP subImp;
				subImp = [subclass instanceMethodForSelector:selector];
				if (subImp == currentImp || subImp == REResponderForwardingMethod()) { // When subclass is NSKVONotifying_, subImp of test_dynamicBlockAddedAfterKVO method is not currentImp (forward). So it is not replaced!!! Check class method of NSKVONotifying_REResponder_ class >>>
					REResponderReplaceImp(subclass, selector, imp, [objCTypes UTF8String], op);
				}
			}
		}
		else {
			for (Class subclass in RESubclassesOfClass(class, NO)) {
				// Replace method
				IMP subImp;
				subImp = [subclass methodForSelector:selector];
				if (subImp == currentImp || subImp == REResponderForwardingMethod()) {
					REResponderReplaceImp(subclass, selector, imp, [objCTypes UTF8String], op);
				}
			}
		}
		
		// Remove oldBlockInfo
		if (oldBlockInfo) {
			[blockInfos removeObject:oldBlockInfo];
			imp_removeBlock(oldImp);
		}
		
		// Add blockInfo
		NSMutableDictionary *blockInfo;
		blockInfo = [NSMutableDictionary dictionaryWithDictionary:@{
			kBlockInfoSelectorKey : NSStringFromSelector(selector),
			kBlockInfoImpKey : [NSValue valueWithPointer:imp],
			kBlockInfoKeyKey : key,
			kBlockInfoOperationKey : @(op),
		}];
		[blockInfos addObject:blockInfo];
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

IMP REResponderGetSupermethod(id receiver, SEL selector, id key, REResponderOperation op)
{
	@synchronized (receiver) {
		// Get supermethod
		IMP supermethod = NULL;
		
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		Class classHavingBlockInfo = NULL;
		blockInfo = REResponderGetBlockInfoForSelector(receiver, selector, key, &blockInfos, op);
		if (blockInfo) {
			classHavingBlockInfo = REGetClass(receiver);
		}
		else {
			// Search blockInfo of superclasses
			Class superclass;
			superclass = REGetSuperclass(receiver);
			while (superclass) {
				REResponderOperation superOp;
				superOp = (op & REResponderOperationInstanceMethodMask ? REResponderOperationInstanceMethodOfClass : REResponderOperationClassMethodOfClass);
				blockInfo = REResponderGetBlockInfoForSelector(superclass, selector, key, &blockInfos, superOp);
				if (blockInfo) {
					classHavingBlockInfo = superclass;
					break;
				}
				superclass = REGetSuperclass(superclass);
			}
		}
		if (!blockInfo) {
			return NULL;
		}
		
		// Get supermethod
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
				IMP imp;
				Class superclass;
				REResponderOperation op;
				imp = [blockInfo[kBlockInfoImpKey] pointerValue];
				op = [blockInfo[kBlockInfoOperationKey] integerValue];
				superclass = REGetSuperclass(classHavingBlockInfo);
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
		
		// Check supermethod
		if (supermethod == REResponderForwardingMethod()) {
			return NULL;
		}
		
		return supermethod;
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
		supermethod = REResponderGetSupermethod(receiver, NSSelectorFromString(blockInfo[kBlockInfoSelectorKey]), blockInfo[kBlockInfoKeyKey], op);
		if (!supermethod) {
			supermethod = REResponderForwardingMethod();
		}
		
		// Replace method
		if (blockInfo == [blockInfos lastObject]) {
			// Get elements
			const char *objCTypes;
			Class class;
			objCTypes = [[blockInfos associatedValueForKey:kBlockInfosMethodSignatureAssociationKey] objCTypes];
			class = REGetClass(receiver);
			
			// Replace method of receiver
			REResponderReplaceImp(class, selector, supermethod, objCTypes, op);
			
			// Replace method of subclasses
			if (op & REResponderOperationInstanceMethodMask) {
				for (Class subclass in RESubclassesOfClass(class, NO)) {
					if ([subclass instanceMethodForSelector:selector] == imp) {
						REResponderReplaceImp(subclass, selector, supermethod, objCTypes, op);
					}
				}
			}
			else {
				for (Class subclass in RESubclassesOfClass(class, NO)) {
					if ([subclass methodForSelector:selector] == imp) {
						REResponderReplaceImp(subclass, selector, supermethod, objCTypes, op);
					}
				}
			}
		}
		
		// Remove implementation which causing releasing block as well
		imp_removeBlock(imp);
		
		// Update cache
		NSMutableDictionary *cache = nil;
		NSNumber *returnAddressNum;
		returnAddressNum = blockInfo[kBlockInfoReturnAddressKey];
		if (returnAddressNum) {
			if (REIsClass(receiver)) {
				cache = _returnAddress_blockInfo;
			}
			else {
				cache = [receiver associatedValueForKey:kReturnAddress_BlockInfoKey];
			}
			[cache removeObjectForKey:returnAddressNum];
		}
		
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
	if (!REIsClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationClassMethodOfClass);
}

+ (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (!REIsClass(self)) {
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

+ (IMP)supermethodOfClassMethod:(SEL)selector key:(id)key
{
	// Filter
	if (!REIsClass(self)) {
		return NULL;
	}
	
	return REResponderGetSupermethod(self, selector, key, REResponderOperationClassMethodOfClass);
}

+ (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (!REIsClass(self)) {
		return NULL;
	}
	
	return REResponderGetSupermethod(self, selector, key, REResponderOperationInstanceMethodOfClass);
}

+ (void)removeBlockForClassMethod:(SEL)selector key:(id)key
{
	// Filter
	if (!REIsClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationClassMethodOfClass);
}

+ (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (!REIsClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfClass);
}

//--------------------------------------------------------------//
#pragma mark -- Block Management for Specific Instance --
//--------------------------------------------------------------//

- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block
{
	// Filter
	if (REIsClass(self)) {
		return;
	}
	
	REResponderSetBlockForSelector(self, selector, key, block, REResponderOperationInstanceMethodOfObject);
}

- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (REIsClass(self)) {
		return NO;
	}
	
	return REResponderHasBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfObject);
}

- (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (REIsClass(self)) {
		return NULL;
	}
	
	return REResponderGetSupermethod(self, selector, key, REResponderOperationInstanceMethodOfObject);
}

- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key
{
	// Filter
	if (REIsClass(self)) {
		return;
	}
	
	REResponderRemoveBlockForSelector(self, selector, key, REResponderOperationInstanceMethodOfObject);
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
	if (!REIsClass(self)) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, key);
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key
{
	// Filter
	if (REIsClass(self)) {
		return;
	}
	
	REResponderSetConformableToProtocol(self, conformable, protocol, key);
}

@end


#pragma mark -


void _RESetBlock(id receiver, SEL selector, BOOL isClassMethod, id key, id block)
{
	// Decide op
	REResponderOperation op;
	if (REIsClass(receiver)) {
		if (isClassMethod) {
			op = REResponderOperationClassMethodOfClass;
		}
		else {
			op = REResponderOperationInstanceMethodOfClass;
		}
	}
	else {
		if (isClassMethod) {
			return;
		}
		else {
			op = REResponderOperationInstanceMethodOfObject;
		}
	}
	
	// Set block
	REResponderSetBlockForSelector(receiver, selector, key, block, op);
}

IMP _REGetSupermethod(id receiver, SEL selector, BOOL isClassMethod, id key)
{
	// Decide op
	REResponderOperation op;
	if (REIsClass(receiver)) {
		if (isClassMethod) {
			op = REResponderOperationClassMethodOfClass;
		}
		else {
			op = REResponderOperationInstanceMethodOfClass;
		}
	}
	else {
		if (isClassMethod) {
			return NULL;
		}
		else {
			op = REResponderOperationInstanceMethodOfObject;
		}
	}
	
	// Return supermethod
	return REResponderGetSupermethod(receiver, selector, key, op);
}

void _RERemoveCurrentBlock(id receiver, SEL selector, BOOL isClassMethod, id key)
{
	// Decide op
	REResponderOperation op;
	if (REIsClass(receiver)) {
		if (isClassMethod) {
			op = REResponderOperationClassMethodOfClass;
		}
		else {
			op = REResponderOperationInstanceMethodOfClass;
		}
	}
	else {
		if (isClassMethod) {
			return;
		}
		else {
			op = REResponderOperationInstanceMethodOfObject;
		}
	}
	
	// Remove
	REResponderRemoveBlockForSelector(receiver, selector, key, op);
}


@implementation NSObject (REResponder_Depricated)

- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated))
{
	RESetBlock(self, selector, NO, key, block);
}

- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	return [self hasBlockForInstanceMethod:selector key:key];
}

- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated))
{
	[self removeBlockForInstanceMethod:selector key:key];
}

- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated))
{
	[self setConformable:conformable toProtocol:protocol key:key];
}

@end
