/*
 REUtil.h
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


#define RE_TYPE(receiver) __typeof(receiver) receiver

// Notifications
extern NSString* const REObjectWillChangeClassNotification;
extern NSString* const REObjectDidChangeClassNotification;

// Keys for userInfo of notifications above
extern NSString* const REObjectOldClassNameKey;
extern NSString* const REObjectNewClassNameKey;


//--------------------------------------------------------------//
#pragma mark   Block
//--------------------------------------------------------------//

// BlockDescriptor
struct BlockDescriptor {
	unsigned long reserved;
	unsigned long size;
	void *rest[1];
};

// Block
struct Block {
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


//--------------------------------------------------------------//
#pragma mark - NSMethodSignature
//--------------------------------------------------------------//

@interface NSMethodSignature (REUtil)
- (const char*)objCTypes;
- (NSString*)description;
@end


//--------------------------------------------------------------//
#pragma mark - NSObject
//--------------------------------------------------------------//

BOOL REIsClass(id receiver);
Class REGetClass(id receiver);
Class REGetSuperclass(id receiver);
Class REGetMetaClass(id receiver);
NSSet* RESubclassesOfClass(Class cls, BOOL includeCls);

@interface NSObject (REUtil)

// Class Exchange
- (void)willChangeClass:(NSString*)fromClassName;
- (void)didChangeClass:(NSString*)toClassName;

// Association
+ (void)setAssociatedValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy;
- (void)setAssociatedValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy;
+ (id)associatedValueForKey:(void*)key;
- (id)associatedValueForKey:(void*)key;

@end


//--------------------------------------------------------------//
#pragma mark - NSObject (REKitPrivate)
//--------------------------------------------------------------//

@interface NSObject (REKitPrivate)

// Method Exchange
+ (void)exchangeClassMethodWithOriginalSelector:(SEL)originalSelector newSelector:(SEL)newSelector;
+ (void)exchangeInstanceMethodWithOriginalSelector:(SEL)originalSelector newSelector:(SEL)newSelector;
+ (void)exchangeClassMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)originalSelector, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)exchangeInstanceMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)originalSelector, ... NS_REQUIRES_NIL_TERMINATION;

@end


//--------------------------------------------------------------//
#pragma mark - NSObject (REUtil_Deprecated)
//--------------------------------------------------------------//

@interface NSObject (REUtil_Deprecated)

- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy __attribute__((deprecated));

@end


//--------------------------------------------------------------//
#pragma mark - NSString
//--------------------------------------------------------------//

#define RE_LINE [NSString stringWithFormat:@"%s-l.%i", __FILE__, __LINE__]
#define RE_FUNC @(__PRETTY_FUNCTION__)
extern NSString* REUUIDString();
