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
static NSString* const kClassNamePrefix = @"REResponder";
static NSString* const kProtocolsAssociationKey = @"REResponder_protocols";
static NSString* const kBlocksAssociationKey = @"REResponder_blocks";
static NSString* const kBlockInfosMethodSignatureAssociationKey = @"methodSignature";

// Keys for blockInfo
static NSString* const kBlockInfoBlockKey = @"block";
static NSString* const kBlockInfoBlockNameKey = @"blockName";

// kDummyBlock
static id (^kDummyBlock)(id, SEL, ...) = ^id (id receiver, SEL selector, ...) {
	return nil;
};


@implementation NSObject (REResponder)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

- (BOOL)REResponder_X_conformsToProtocol:(Protocol*)aProtocol
{
	// original
	if ([self REResponder_X_conformsToProtocol:aProtocol]) {
		return YES;
	}
	
	// Check protocols
	return ([[self associatedValueForKey:kProtocolsAssociationKey][NSStringFromProtocol(aProtocol)] count] > 0);
}

- (BOOL)REResponder_X_respondsToSelector:(SEL)aSelector
{
	// Check blockInfos
	NSMutableArray *blockInfos;
	NSString *selectorName;
	selectorName = NSStringFromSelector(aSelector);
	blockInfos = [self associatedValueForKey:kBlocksAssociationKey][selectorName];
	if (blockInfos) {
		if ([blockInfos count]) {
			return YES;
		}
		
		// Check originalMethod
		IMP originalMethod;
		originalMethod = method_getImplementation(class_getInstanceMethod([[self class] superclass], NSSelectorFromString(selectorName)));
		return (originalMethod != nil);
	}
	
	// original
	return [self REResponder_X_respondsToSelector:aSelector];
}

- (void)REResponder_X_dealloc
{
	// Release protocols
	[self associateValue:nil forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// Release blocks
	NSArray *blockNames;
	NSMutableDictionary *blocks;
	blocks = [self associatedValueForKey:kBlocksAssociationKey];
	if ([blocks count]) {
		blockNames = [[blocks allValues] valueForKey:kBlockInfoBlockNameKey];
		blockNames = [blockNames valueForKeyPath:@"@unionOfArrays.self"];
		[blockNames enumerateObjectsUsingBlock:^(NSString *blockName, NSUInteger idx, BOOL *stop) {
			[self removeBlockNamed:blockName];
		}];
		[self associateValue:nil forKey:kBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	}
	
	// original
	[self REResponder_X_dealloc];
}

+ (void)load
{
	@autoreleasepool {
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
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSDictionary*)REResponder_blockInfoWithBlockName:(NSString*)blockName blockInfos:(NSMutableArray**)blockInfos selectorName:(NSString**)selectorName
{
	// Get blockInfo
	__block NSDictionary *blockInfo = nil;
	@synchronized (self) {
		[[self associatedValueForKey:kBlocksAssociationKey] enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *aSelectorName, NSMutableArray *aBlockInfos, BOOL *aStop) {
			[aBlockInfos enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSDictionary *bBlockInfo, NSUInteger bIdx, BOOL *bStop) {
				if ([bBlockInfo[kBlockInfoBlockNameKey] isEqualToString:blockName]) {
					blockInfo = bBlockInfo;
					if (blockInfos) {
						*blockInfos = aBlockInfos;
					}
					if (selectorName) {
						*selectorName = aSelectorName;
					}
					*aStop = YES;
					*bStop = YES;
				}
			}];
		}];
	}
	
	// Nullify arguments
	if (!blockInfo) {
		if (blockInfos) {
			*blockInfos = nil;
		}
		if (selectorName) {
			*selectorName = nil;
		}
	}
	
	return blockInfo;
}

//--------------------------------------------------------------//
#pragma mark -- Block --
//--------------------------------------------------------------//

- (void)respondsToSelector:(SEL)selector withBlockName:(NSString*)name usingBlock:(id)block
{
	// Filter
	if (!selector || !block) {
		return;
	}
	
	// Get blockName
	NSString *blockName;
	if ([name length]) {
		blockName = [[name copy] autorelease];
	}
	else {
		blockName = REUUIDString();
	}
	
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
		NSLog(@"Failed to get signature for block named %@", blockName);
		return;
	}
	
	// Update blocks
	[self removeBlockNamed:name];
	@synchronized (self) {
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
				[self associateValue:blocks forKey:kBlocksAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Make blockInfos
			blockInfos = [NSMutableArray array];
			[blockInfos associateValue:methodSignature forKey:kBlockInfosMethodSignatureAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			[blocks setObject:blockInfos forKey:selectorName];
		}
		
		// Become subclass
		if (![NSStringFromClass([self class]) hasPrefix:kClassNamePrefix]) {
			if (![NSStringFromClass([self class]) hasPrefix:kClassNamePrefix]) {
				// Update _number
				static NSDecimalNumber *_number = nil;
				if (!_number) {
					_number = [[NSDecimalNumber one] retain];
				}
				else {
					NSDecimalNumber *number;
					number = [_number decimalNumberByAdding:[NSDecimalNumber one]];
					[_number release];
					_number = [number retain];
				}
				
				// Become subclass
				Class originalClass;
				Class subclass;
				NSString *className;
				originalClass = [self class];
				className = [NSString stringWithFormat:@"%@%@_%@", kClassNamePrefix, [_number stringValue], NSStringFromClass([self class])];
				subclass = objc_allocateClassPair(originalClass, [className UTF8String], 0);
				objc_registerClassPair(subclass);
				[self willChangeClass:subclass];
				object_setClass(self, subclass);
				[self didChangeClass:originalClass];
			}
		}
		
		// Replace method
		class_replaceMethod([self class], selector, imp_implementationWithBlock(block), [objCTypes UTF8String]);
		
		// Add blockInfo to blockInfos
		NSDictionary *blockInfo;
		blockInfo = @{
			kBlockInfoBlockKey : Block_copy(block),
			kBlockInfoBlockNameKey : blockName,
		};
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
		blockInfo = [self REResponder_blockInfoWithBlockName:blockName blockInfos:nil selectorName:nil];
		block = blockInfo[kBlockInfoBlockKey];
	}
	
	return block;
}

- (IMP)supermethodOfBlockNamed:(NSString *)blockName
{
	// Filter
	if (![blockName length]) {
		return NULL;
	}
	
	// Get supermethod
	IMP supermethod = NULL;
	@synchronized (self) {
		// Get blockInfo
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		NSString *selectorName;
		blockInfo = [self REResponder_blockInfoWithBlockName:blockName blockInfos:&blockInfos  selectorName:&selectorName];
		if (blockInfo) {
			// Check index of blockInfo
			NSUInteger index;
			index = [blockInfos indexOfObject:blockInfo];
			if (index == 0) {
				// supermethod is superclass's instance method
				supermethod = method_getImplementation(class_getInstanceMethod([[self class] superclass], NSSelectorFromString(selectorName)));
			}
			else {
				// supermethod is superblock's IMP
				id superblock;
				superblock = [blockInfos objectAtIndex:(index - 1)][kBlockInfoBlockKey];
				supermethod = imp_implementationWithBlock(superblock);
			}
		}
	}
	
	return supermethod;
}

- (void)removeBlockNamed:(NSString*)blockName
{
	@synchronized (self) {
		// Get elements
		NSDictionary *blockInfo;
		NSMutableArray *blockInfos;
		NSString *selectorName;
		blockInfo = [self REResponder_blockInfoWithBlockName:blockName blockInfos:&blockInfos  selectorName:&selectorName];
		if (blockInfo && blockInfos) {
			// Replace method
			if (blockInfo == [blockInfos lastObject]) {
				SEL selector;
				IMP supermethod;
				selector = NSSelectorFromString(selectorName);
				supermethod = [self supermethodOfBlockNamed:blockInfo[kBlockInfoBlockNameKey]];
				if (supermethod) {
					class_replaceMethod([self class], selector, supermethod, REBlockGetObjCTypes(blockInfo[kBlockInfoBlockKey]));
				}
				else {
					class_replaceMethod([self class], selector, imp_implementationWithBlock(kDummyBlock), REBlockGetObjCTypes(kDummyBlock));
				}
			}
			
			// Release block
			id block;
			block = blockInfo[kBlockInfoBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove blockInfo
			[blockInfos removeObject:blockInfo];
		}
	}
}

//--------------------------------------------------------------//
#pragma mark -- Conformance --
//--------------------------------------------------------------//

- (void)setConformable:(BOOL)comformable toProtocol:(Protocol*)protocol withKey:(NSString*)key
{
	// Filter
	if (!protocol || ![key length]) {
		return;
	}
	
	// Update REResponder_protocols
	@synchronized (self) {
		// Get elements
		NSString *protocolName;
		NSMutableDictionary *protocols;
		protocolName = NSStringFromProtocol(protocol);
		protocols = [self associatedValueForKey:kProtocolsAssociationKey];
		
		// Add key
		if (comformable) {
			// Associate protocols
			if (!protocols) {
				protocols = [NSMutableDictionary dictionary];
				[self associateValue:protocols forKey:kProtocolsAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			
			// Get keys
			NSMutableSet *keys;
			keys = protocols[protocolName];
			if (!keys) {
				keys = [NSMutableSet set];
				[protocols setObject:keys forKey:protocolName];
			}
			
			// Add key
			[keys addObject:[key copy]];
		}
		// Remove key
		else {
			// Get keys
			NSMutableSet *keys;
			keys = protocols[protocolName];
			if (![keys count]) {
				return;
			}
			
			// Remove key
			[keys removeObject:key];
			
			// Remove keys
			if (![keys count]) {
				[protocols removeObjectForKey:protocolName];
			}
		}
	}
}

@end
