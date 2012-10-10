/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Constants
extern NSString* const REResponderOriginalImplementationBlockName;


@interface NSObject (REResponder)

// Conformance
- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol;

// Block
- (BOOL)respondsToSelector:(SEL)selector withBlockName:(NSString**)blockName usingBlock:(id)block;
- (id)blockNamed:(NSString*)blockName;
- (id)superBlockOfBlockNamed:(NSString*)blockName;
- (void)removeBlockNamed:(NSString*)blockName;

@end
