/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface NSObject (REResponder)

// Block
- (void)respondsToSelector:(SEL)selector withBlockName:(NSString*)nameOrNil usingBlock:(id)block;
- (id)blockNamed:(NSString*)blockName;
- (IMP)supermethodOfBlockNamed:(NSString*)blockName;
- (void)removeBlockNamed:(NSString*)blockName;

// Conformance
- (void)setConformable:(BOOL)comformable toProtocol:(Protocol*)protocol withKey:(NSString*)key;

@end
