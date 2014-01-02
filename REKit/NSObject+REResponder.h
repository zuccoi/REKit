/*
 NSObject+REResponder.h
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>

#define REIMP(ReturnType) (__typeof(ReturnType (*)(id, SEL, ...)))
#define RESupermethod(ReturnType, receiver, selector, ...) \
	^{\
		IMP supermethod = REResponderGetSupermethodWithImp(receiver, REImplementationWithBacktraceDepth(2));\
		if (supermethod) {\
			return (REIMP(ReturnType)supermethod)(receiver, selector, ##__VA_ARGS__);\
		}\
		else {\
			return (ReturnType)nil;\
		}\
	}()
#define RESupermethodStret(defaultValue, receiver, selector, ...) \
	^{\
		IMP supermethod = REResponderGetSupermethodWithImp(receiver, REImplementationWithBacktraceDepth(2));\
		if (supermethod) {\
			return (__typeof(defaultValue))(REIMP(__typeof(defaultValue))supermethod)(receiver, selector, ##__VA_ARGS__);\
		}\
		else {\
			return (__typeof(defaultValue))defaultValue;\
		}\
	}()


@interface NSObject (REResponder)

// Block Management for Class
+ (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block;
+ (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
+ (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key;
+ (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForClassMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Block Management for Specific Instance
- (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block;
- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
- (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key;
- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
- (void)removeBlockForClassMethod:(SEL)selector key:(id)key;
- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Current Block Management (Call from Block)
+ (void)removeCurrentBlock;
- (void)removeCurrentBlock;

// Conformance
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;

@end

#pragma mark -


// Private Function
extern IMP REResponderGetSupermethodWithImp(id receiver, IMP imp);

// Deprecated Methods
@interface NSObject (REResponderDeprecated)
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated));
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (IMP)supermethodOfCurrentBlock __attribute__((deprecated));
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated));
@end
