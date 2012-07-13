/*
 REUtil.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REUtil.h"


@implementation NSObject (REUtil)

//--------------------------------------------------------------//
#pragma mark -- Method Exchange --
//--------------------------------------------------------------//

+ (void)exchangeClassMethodForSelector:(SEL)originalSelector withForSelector:(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getClassMethod(self, originalSelector);
	newMethod = class_getClassMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)exchangeInstanceMethodForSelector:(SEL)originalSelector withForSelector:(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getInstanceMethod(self, originalSelector);
	newMethod = class_getInstanceMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

//--------------------------------------------------------------//
#pragma mark -- Associated Value --
//--------------------------------------------------------------//

- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy
{
	objc_setAssociatedObject(self, key, value, policy);
}

- (id)associatedValueForKey:(void*)key
{
	return objc_getAssociatedObject(self, key);
}

@end
