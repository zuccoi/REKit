/*
 NSObject+REResponder.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface NSObject (REResponder)

// Method Replacement
+ (BOOL)replaceClassMethodForSelector:(SEL)selector withOriginalIMP:(IMP*)originalIMP usingBlock:(id)block;
+ (BOOL)replaceInstanceMethodForSelector:(SEL)selector withOriginalIMP:(IMP*)originalIMP usingBlock:(id)block;

// Conformance
- (void)becomeConformable:(BOOL)flag toProtocol:(Protocol*)protocol;

// Block
- (BOOL)respondsToSelector:(SEL)selector withBlockName:(NSString**)blockName usingBlock:(id)block;
- (id)blockNamed:(NSString*)blockName;
- (id)superBlockOfBlockNamed:(NSString*)blockName; // Needed ?????
- (void)removeBlockNamed:(NSString*)blockName;

@end
