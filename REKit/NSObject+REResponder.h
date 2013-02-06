/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// REVoidIMP
typedef void (*REVoidIMP)(id, SEL, ...); // Needed ?????


@interface NSObject (REResponder)

// Block
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block;
- (id)blockForSelector:(SEL)selector forKey:(id)key;
- (IMP)supermethodOfBlockForSelector:(SEL)selector forKey:(id)key; // Test >>>
- (void)removeBlockForSelector:(SEL)selector forKey:(id)key;

// Current Block
- (id)currentBlock; // Test >>>
- (IMP)supermethodOfCurrentBlock;
- (void)removeCurrentBlock; // Test >>>

// Conformance
- (void)setConformable:(BOOL)comformable toProtocol:(Protocol*)protocol withKey:(id)key;

@end
