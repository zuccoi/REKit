/*
 REUtil.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


// Notifications
extern NSString* const REObjectWillChangeClassNotification;
extern NSString* const REObjectDidChangeClassNotification;

// Keys for userInfo of notifications above
extern NSString* const REObjectOldClassNameKey;
extern NSString* const REObjectNewClassNameKey;


//--------------------------------------------------------------//
#pragma mark -- Block --
//--------------------------------------------------------------//

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

extern const char* REBlockGetObjCTypes(id block);
extern void* REBlockGetImplementation(id block);

#pragma mark -


extern NSString* REUUIDString();

#pragma mark -


@interface NSInvocation (REUtil)
- (void)invokeUsingIMP:(IMP)imp;
@end

#pragma mark -


@interface NSMethodSignature (REUtil)
- (NSString*)objCTypes;
- (NSString*)description;
@end

#pragma mark -


@interface NSObject (REUtil)

// Class Exchange
- (void)willChangeClass:(Class)toClass;
- (void)didChangeClass:(Class)fromClass;

// Association
- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy;
- (id)associatedValueForKey:(void*)key;

@end

#pragma mark -


@interface NSObject (REKitPrivate)

// Method Exchange
+ (void)exchangeClassMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector;
+ (void)exchangeInstanceMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector;
+ (void)exchangeClassMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)exchangeInstanceMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION;

@end
