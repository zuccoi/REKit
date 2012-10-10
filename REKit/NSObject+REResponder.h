/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Constants
extern NSString* const REResponderOriginalImplementationBlockName;


@interface NSObject (REResponder)

// Setup
- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol;

// Block
- (void)respondsToSelector:(SEL)selector usingBlock:(id)block blockName:(NSString**)blockName;
- (id)blockNamed:(NSString*)blockName;
- (id)superBlockOfBlockNamed:(NSString*)blockName;
- (void)removeBlockNamed:(NSString*)blockName;

@end
