/*
 REUtil.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@interface NSObject (REUtil)

// Method Exchange
+ (void)exchangeClassMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector;
+ (void)exchangeInstanceMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector;
+ (void)exchangeClassMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)exchangeInstanceMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION;

// Associated Value
- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy;
- (id)associatedValueForKey:(void*)key;

@end
