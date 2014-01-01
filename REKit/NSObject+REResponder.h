/*
 NSObject+REResponder.h
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>

#define REIMP(ReturnType) (__typeof(ReturnType (*)(id, SEL, ...)))
#define RESupermethod(ReturnType, receiver, selector, ...) \
	^{\
		IMP supermethod = REResponderSupermethodWithImp(receiver, REImplementationWithBacktraceDepth(2));\
		if (supermethod) {\
			return (REIMP(ReturnType)supermethod)(receiver, selector, ##__VA_ARGS__);\
		}\
		else {\
			return (ReturnType)nil;\
		}\
	}()
#define RESupermethodStret(defaultValue, receiver, selector, ...) \
	^{\
		IMP supermethod = REResponderSupermethodWithImp(receiver, REImplementationWithBacktraceDepth(2));\
		if (supermethod) {\
			return (__typeof(defaultValue))(REIMP(__typeof(defaultValue))supermethod)(receiver, selector, ##__VA_ARGS__);\
		}\
		else {\
			return (__typeof(defaultValue))defaultValue;\
		}\
	}()


@interface NSObject (REResponder)

// Block
+ (void)setBlockForSelector:(SEL)selector key:(id)key block:(id)block;
+ (void)setBlockForInstanceMethodForSelector:(SEL)selector key:(id)key block:(id)block;
- (void)setBlockForSelector:(SEL)selector key:(id)key block:(id)block;
+ (BOOL)hasBlockForSelector:(SEL)selector key:(id)key;
+ (BOOL)hasBlockForInstanceMethodForSelector:(SEL)selector key:(id)key;
- (BOOL)hasBlockForSelector:(SEL)selector key:(id)key;
+ (void)removeBlockForSelector:(SEL)selector key:(id)key;
+ (void)removeBlockForInstanceMethodForSelector:(SEL)selector key:(id)key;
- (void)removeBlockForSelector:(SEL)selector key:(id)key;

// Current Block
+ (IMP)supermethodOfCurrentBlock;
- (IMP)supermethodOfCurrentBlock;
+ (void)removeCurrentBlock;
- (void)removeCurrentBlock;

// Conformance
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;

@end

#pragma mark -


@interface NSObject (REResponder_Deprecated)

- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated));
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated));

@end

#pragma mark -


// Private Function
extern IMP REResponderSupermethodWithImp(id receiver, IMP imp);
