/*
 REUtil.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REUtil.h"


// Notifications
NSString* const REObjectWillChangeClassNotification = @"REObjectWillChangeClassNotification";
NSString* const REObjectDidChangeClassNotification = @"REObjectDidChangeClassNotification";

// Keys for userInfo of notifications above
NSString* const REObjectOldClassNameKey = @"REObjectOldClassNameKey";
NSString* const REObjectNewClassNameKey = @"REObjectNewClassNameKey";


const char* REBlockGetObjCTypes(id _block)
{
	// Get descriptor of block
	struct BlockDescriptor *descriptor;
	struct Block *block;
	block = (void*)_block;
	descriptor = block->descriptor;
	
	// Get index of rest
	int index = 0;
	if (block->flags & BLOCK_HAS_COPY_DISPOSE) {
		index += 2;
	}
	
	return descriptor->rest[index];
}

void* REBlockGetImplementation(id block)
{
	return ((struct Block*)block)->invoke;
}

#pragma mark -


NSString* REUUIDString()
{
	CFUUIDRef uuid;
	NSString* uuidString;
	uuid = CFUUIDCreate(NULL);
	uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
	CFRelease(uuid);
	
	return uuidString;
}

#pragma mark -


@implementation NSMethodSignature (REUtil)

- (NSString*)objCTypes
{
	NSMutableString *objCTypes;
	objCTypes = [NSMutableString string];
	[objCTypes appendString:[NSString stringWithCString:[self methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 0; i < [self numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[self getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	
	return objCTypes;
}

- (NSString*)description
{
	NSMutableString *description;
	description = [NSMutableString string];
	[description appendFormat:@"<%@: %p> %@", NSStringFromClass([self class]), self, [self objCTypes]];
	
	return description;
}

@end

#pragma mark -


@implementation NSObject (REUtil)

//--------------------------------------------------------------//
#pragma mark -- Class Exchange --
//--------------------------------------------------------------//

- (void)willChangeClass:(Class)toClass
{
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:REObjectWillChangeClassNotification object:self userInfo:@{
		REObjectOldClassNameKey : NSStringFromClass([self class]),
		REObjectNewClassNameKey : NSStringFromClass(toClass)
	}];
}

- (void)didChangeClass:(Class)fromClass
{
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:REObjectDidChangeClassNotification object:self userInfo:@{
		REObjectOldClassNameKey : NSStringFromClass(fromClass),
		REObjectNewClassNameKey : NSStringFromClass([self class])
	}];
}

//--------------------------------------------------------------//
#pragma mark -- Method Exchange --
//--------------------------------------------------------------//

+ (void)exchangeClassMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getClassMethod(self, originalSelector);
	newMethod = class_getClassMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)exchangeClassMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION
{
	// Enumerate selectors
	SEL aSelector;
	va_list args;
	va_start(args, selector);
	aSelector = selector;
	while (aSelector) {
		// Exchange
		Method originalMethod;
		Method newMethod;
		originalMethod = class_getClassMethod(self, aSelector);
		newMethod = class_getClassMethod(self, NSSelectorFromString([prefix stringByAppendingString:NSStringFromSelector(aSelector)]));
		method_exchangeImplementations(originalMethod, newMethod);
		
		// Get next selector
		aSelector = va_arg(args, SEL);
	}
	va_end(args);
}

+ (void)exchangeInstanceMethodsWithSelectors:(SEL)originalSelector :(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getInstanceMethod(self, originalSelector);
	newMethod = class_getInstanceMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)exchangeInstanceMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)selector, ... NS_REQUIRES_NIL_TERMINATION
{
	// Enumerate selectors
	SEL aSelector;
	va_list args;
	va_start(args, selector);
	aSelector = selector;
	while (aSelector) {
		// Exchange
		Method originalMethod;
		Method newMethod;
		originalMethod = class_getInstanceMethod(self, aSelector);
		newMethod = class_getInstanceMethod(self, NSSelectorFromString([prefix stringByAppendingString:NSStringFromSelector(aSelector)]));
		method_exchangeImplementations(originalMethod, newMethod);
		
		// Get next selector
		aSelector = va_arg(args, SEL);
	}
	va_end(args);
}

//--------------------------------------------------------------//
#pragma mark -- Association --
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
