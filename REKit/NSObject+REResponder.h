/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// REVoidIMP
typedef void (*REVoidIMP)(id, SEL, ...);


@interface NSObject (REResponder)

// Block
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block;
- (id)blockForSelector:(SEL)selector forKey:(id)key;
- (void)removeBlockForSelector:(SEL)selector forKey:(id)key;

// Current Block
- (IMP)supermethodOfCurrentBlock;
- (void)removeCurrentBlock;

// Conformance
- (void)setConformable:(BOOL)comformable toProtocol:(Protocol*)protocol withKey:(id)key;

@end
