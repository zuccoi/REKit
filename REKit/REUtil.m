/*
 REUtil.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <objc/message.h>
#import <dlfcn.h>
#import "execinfo.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Notifications
NSString* const REObjectWillChangeClassNotification = @"REObjectWillChangeClassNotification";
NSString* const REObjectDidChangeClassNotification = @"REObjectDidChangeClassNotification";

// Keys for userInfo of notifications above
NSString* const REObjectOldClassNameKey = @"REObjectOldClassNameKey";
NSString* const REObjectNewClassNameKey = @"REObjectNewClassNameKey";


//--------------------------------------------------------------//
#pragma mark Block
//--------------------------------------------------------------//

const char* REBlockGetObjCTypes(id _block)
{
	// Get descriptor of block
	struct BlockDescriptor *descriptor;
	struct Block *block;
	block = (struct Block*)_block;
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


//--------------------------------------------------------------//
#pragma mark - IMP
//--------------------------------------------------------------//

IMP REImplementationWithBacktraceDepth(int depth)
{
	// Get trace
	int num;
	void *trace[depth + 1];
	num = backtrace(trace, (depth + 1));
	if (num < (depth + 1)) {
		return NULL;
	}
	
	// Get imp
	IMP imp;
	Dl_info callerInfo;
	if (!dladdr(trace[depth], &callerInfo)) {
		NSLog(@"ERROR: Failed to get callerInfo with error:%s «%s-%d", dlerror(), __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	imp = callerInfo.dli_saddr;
	if (!imp) {
		NSLog(@"ERROR: Failed to get imp from callerInfo «%s-%d", __PRETTY_FUNCTION__, __LINE__);
		return NULL;
	}
	
	return imp;
}


//--------------------------------------------------------------//
#pragma mark - NSMethodSignature
//--------------------------------------------------------------//

@implementation NSMethodSignature (REUtil)

- (const char*)objCTypes
{
	NSMutableString *objCTypes;
	objCTypes = [NSMutableString string];
	[objCTypes appendString:[NSString stringWithCString:[self methodReturnType] encoding:NSUTF8StringEncoding]];
	for (NSInteger i = 0; i < [self numberOfArguments]; i++) {
		[objCTypes appendString:[NSString stringWithCString:[self getArgumentTypeAtIndex:i] encoding:NSUTF8StringEncoding]];
	}
	
	return [objCTypes UTF8String];
}

- (NSString*)description
{
	NSMutableString *description;
	description = [NSMutableString string];
	[description appendFormat:@"<%@: %p> %s", NSStringFromClass([self class]), self, [self objCTypes]];
	
	return description;
}

@end


//--------------------------------------------------------------//
#pragma mark - NSObject
//--------------------------------------------------------------//

Class object_setClass(id object, Class cls)
{
	// Gete original function
	static Class (*RE_X_object_setClass)(id, Class) = nil;
	if (!RE_X_object_setClass) {
		RE_X_object_setClass = (Class (*)(id, Class))dlsym(RTLD_NEXT, "object_setClass");
		if (!RE_X_object_setClass) {
			NSLog(@"Original object_setClass function was not found");
			return NULL;
		}
	}
	
	// Call willChangeClass:
	objc_msgSend(object, @selector(willChangeClass:), cls);
	
	// original
	Class oldClass;
	oldClass = RE_X_object_setClass(object, cls);
	
	// Call didChangeClass:
	objc_msgSend(object, @selector(didChangeClass:), oldClass);
	
	return oldClass;
}

Class REGetClass(id receiver)
{
	if (!receiver) {
		return NULL;
	}
	else if (receiver != [receiver class]) {
		return object_getClass(receiver);
	}
	else if (class_isMetaClass(receiver)) {
		return NSClassFromString([NSString stringWithFormat:@"%s", class_getName(receiver)]);
	}
	else {
		return receiver;
	}
}

Class REGetMetaClass(id receiver)
{
	if (!receiver) {
		return NULL;
	}
	else if (receiver != [receiver class]) {
		return object_getClass(object_getClass(receiver));
	}
	else if (class_isMetaClass(receiver)) {
		return receiver;
	}
	else {
		return object_getClass(receiver);
	}
}

NSSet* RESubclassesOfClass(Class cls, BOOL includeCls)
{
	// Filter
	if (!cls) {
		return nil;
	}
	
	// Get count of classes
	int count;
	count = objc_getClassList(NULL, 0);
	if (count <= 0) {
		return nil;
	}
	
	// Get classes
	Class *classes;
	classes = malloc(sizeof(Class) * count);
	count = objc_getClassList(classes, count);
	
	// Get subclasses
	NSMutableSet *subclasses;
	subclasses = [NSMutableSet set];
	for (NSInteger i = 0; i < count; i++) {
		// Get aClass
		Class aClass;
		aClass = classes[i];
		if (includeCls && aClass == cls) {
			[subclasses addObject:aClass];
			continue;
		}
		
		// Is kind of cls?
		Class superClass;
		superClass = aClass;
		do {
			superClass = class_getSuperclass(superClass);
		} while (superClass && superClass != cls);
		if (!superClass) {
			continue;
		}
		
		// Collect aClass
		[subclasses addObject:classes[i]];
	}
	
	// Free classes
	free(classes);
	 
	return subclasses;
}

@implementation NSObject (REUtil)

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

+ (void)setAssociatedValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy
{
	objc_setAssociatedObject(self, key, value, policy);
}

- (void)setAssociatedValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy
{
	objc_setAssociatedObject(self, key, value, policy);
}

+ (id)associatedValueForKey:(void*)key
{
	return objc_getAssociatedObject(self, key);
}

- (id)associatedValueForKey:(void*)key
{
	return objc_getAssociatedObject(self, key);
}

@end


//--------------------------------------------------------------//
#pragma mark - NSObject (REKitPrivate)
//--------------------------------------------------------------//

@implementation NSObject (REKitPrivate)

+ (void)exchangeClassMethodWithOriginalSelector:(SEL)originalSelector newSelector:(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getClassMethod(self, originalSelector);
	newMethod = class_getClassMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)exchangeInstanceMethodWithOriginalSelector:(SEL)originalSelector newSelector:(SEL)newSelector
{
	// Exchange
	Method originalMethod;
	Method newMethod;
	originalMethod = class_getInstanceMethod(self, originalSelector);
	newMethod = class_getInstanceMethod(self, newSelector);
	method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)exchangeClassMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)originalSelector, ... NS_REQUIRES_NIL_TERMINATION
{
	// Enumerate selectors
	SEL aSelector;
	va_list args;
	va_start(args, originalSelector);
	aSelector = originalSelector;
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

+ (void)exchangeInstanceMethodsWithAdditiveSelectorPrefix:(NSString*)prefix selectors:(SEL)originalSelector, ... NS_REQUIRES_NIL_TERMINATION
{
	// Enumerate selectors
	SEL aSelector;
	va_list args;
	va_start(args, originalSelector);
	aSelector = originalSelector;
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

@end


//--------------------------------------------------------------//
#pragma mark - NSObject (REUtil_Deprecated)
//--------------------------------------------------------------//

@implementation NSObject (REUtil_Deprecated)

- (void)associateValue:(id)value forKey:(void*)key policy:(objc_AssociationPolicy)policy __attribute__((deprecated))
{
	[self setAssociatedValue:value forKey:key policy:policy];
}

@end


//--------------------------------------------------------------//
#pragma mark - NSString
//--------------------------------------------------------------//

NSString* REUUIDString()
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1080 || __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)
	return [[NSUUID UUID] UUIDString];
#else
	CFUUIDRef uuid;
	NSString* uuidString;
	uuid = CFUUIDCreate(NULL);
	uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
	CFRelease(uuid);
	
	return uuidString;
#endif
}
