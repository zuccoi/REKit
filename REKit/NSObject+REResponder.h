/*
 NSObject+REResponder.h
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


#define REIMP(ReturnType) (__typeof(ReturnType (*)(id, SEL, ...)))

#define RESupermethod(defaultValue, receiver, ...) \
	^{\
		IMP re_supermethod;\
		SEL re_selector;\
		re_supermethod = [receiver supermethodOfCurrentBlock:&re_selector];\
		if (re_supermethod && re_selector) {\
			return (__typeof(defaultValue))(REIMP(__typeof(defaultValue))re_supermethod)(receiver, re_selector, ##__VA_ARGS__);\
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
- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Methods intended to be called in Block
+ (IMP)supermethodOfCurrentBlock:(out SEL*)selector;
- (IMP)supermethodOfCurrentBlock:(out SEL*)selector;
+ (void)removeCurrentBlock;
- (void)removeCurrentBlock;

// Conformance
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;

@end

#pragma mark -


// Deprecated Methods
@interface NSObject (REResponder_Depricated)
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated));
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (IMP)supermethodOfCurrentBlock __attribute__((deprecated));
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated));
@end
