/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface NSObject (REResponder)

// Responds
- (void)respondsToSelector:(SEL)selector usingBlock:(id)block;
- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol;
- (id)blockForSelector:(SEL)selector;
- (void)removeBlockForSelector:(SEL)selector;

@end
