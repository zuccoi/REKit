/*
 REUtil.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@interface NSObject (REUtil)

// Method Exchange
+ (void)exchangeClassMethodForSelector:(SEL)originalSelector withForSelector:(SEL)newSelector;
+ (void)exchangeInstanceMethodForSelector:(SEL)originalSelector withForSelector:(SEL)newSelector;

// Associated Value
- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy;
- (id)associatedValueForKey:(void*)key;

@end
