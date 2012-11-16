/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface NSObject (REResponder)

// Conformance
- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol; // Work ?????

// Block
- (BOOL)respondsToSelector:(SEL)selector withBlockName:(NSString*)nameOrNil usingBlock:(id)block;
- (id)blockNamed:(NSString*)blockName;
- (IMP)supermethodOfBlockNamed:(NSString*)blockName;
- (void)removeBlockNamed:(NSString*)blockName;

// Class
- (void)willBecomeInstanceOfClass:(Class)aClass;
- (void)didBecomeInstanceOfClass:(Class)aClass;

@end
