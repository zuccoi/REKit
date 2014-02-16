/*
 NSObject+REResponder.h
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "REUtil.h"


#define REIMP(ReturnType) (__typeof(ReturnType (*)(id, SEL, ...)))

#define RESetBlock(receiver, selector, isClassMethod, key, block...) \
	({\
		_Pragma("clang diagnostic push") \
		_Pragma("clang diagnostic ignored \"-Wunused-variable\"") \
		_Pragma("clang diagnostic ignored \"-Wshadow\"") \
		__typeof(receiver) __weak re_receiver = receiver;\
		SEL re_selector;\
		BOOL re_isClassMethod;\
		id re_valited_key;\
		re_valited_key = (key ? key : REUUIDString());\
		__typeof(key) __weak re_key = re_valited_key;\
		re_selector = selector;\
		re_isClassMethod = isClassMethod;\
		_RESetBlock(re_receiver, re_selector, re_isClassMethod, re_key, block);\
		_Pragma("clang diagnostic pop")\
	})

#define RESupermethod(defaultValue, receiver, ...) \
	^{\
		IMP re_supermethod = NULL;\
		re_supermethod = _REGetSupermethod(re_receiver, re_selector, re_isClassMethod, re_key);\
		if (re_supermethod && re_selector) {\
			return (__typeof(defaultValue))(REIMP(__typeof(defaultValue))re_supermethod)(receiver, re_selector, ##__VA_ARGS__);\
		}\
		else {\
			return (__typeof(defaultValue))defaultValue;\
		}\
	}()

#define RERemoveCurrentBlock() \
	_RERemoveCurrentBlock(re_receiver, re_selector, re_isClassMethod, re_key)

#define RE_PRETTY_BLOCK \
	[NSString stringWithFormat:@"[%@ %@]%@[%@ %@]", NSStringFromClass([re_receiver class]), NSStringFromSelector(_cmd), (re_isClassMethod ? @"+" : @"-"), NSStringFromClass([re_receiver class]), NSStringFromSelector(re_selector)]


@interface NSObject (REResponder)

// Block Management for Class
+ (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block;
+ (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
+ (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key;
+ (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
+ (IMP)supermethodOfClassMethod:(SEL)selector key:(id)key;
+ (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForClassMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Block Management for Specific Instance
- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
- (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key;
- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Conformance
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;

@end


#pragma mark -

// Private
void _RESetBlock(id receiver, SEL selector, BOOL isClassMethod, id key, id block);
IMP _REGetSupermethod(id receiver, SEL selector, BOOL isClassMethod, id key);
void _RERemoveCurrentBlock(id receiver, SEL selector, BOOL isClassMethod, id key);

// Deprecated Methods
@interface NSObject (REResponder_Depricated)
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated));
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated));
@end
