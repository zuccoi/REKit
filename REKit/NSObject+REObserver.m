/*
 NSObject+REObserver.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "NSObject+REObserver.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kObservingInfoKey = @"REObserverObservingInfo";

// Keys for observingInfo
NSString* const REObservingInfoObjectKey = @"object";
NSString* const REObservingInfoKeyPathKey = @"keyPath";
NSString* const REObservingInfoOptionsKey = @"options";
NSString* const REObservingInfoBlockKey = @"block";


@implementation NSObject (REObserver)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

+ (void)load
{
	// Exchange methods…
	
	// observeValueForKeyPath:ofObject:change:context:
	[self exchangeInstanceMethodForSelector:@selector(observeValueForKeyPath:ofObject:change:context:) withForSelector:@selector(OBSX_observeValueForKeyPath:ofObject:change:context:)];
	
	// removeObserver:forKeyPath:
	[self exchangeInstanceMethodForSelector:@selector(removeObserver:forKeyPath:) withForSelector:@selector(OBSX_removeObserver:forKeyPath:)];
	
	// removeObserver:forKeyPath:context:
	[self exchangeInstanceMethodForSelector:@selector(removeObserver:forKeyPath:context:) withForSelector:@selector(OBSX_removeObserver:forKeyPath:context:)];
	
	// dealloc
	[self exchangeInstanceMethodForSelector:@selector(dealloc) withForSelector:@selector(OBSX_dealloc)];
}

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (void)OBSX_dealloc
{
	// Stop observing
	[self stopObserving];
	
	// original
	[self OBSX_dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Observer --
//--------------------------------------------------------------//

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block
{
	// Filter
	if (![keyPath length] || !block) {
		return nil;
	}
	
	// Make observer
	id observer;
	NSDictionary *observingInfo;
	observer = [[NSObject alloc] init];
	observingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, REObservingInfoObjectKey,
		keyPath, REObservingInfoKeyPathKey,
		[NSNumber numberWithInteger:options], REObservingInfoOptionsKey,
		Block_copy(block), REObservingInfoBlockKey,
		nil];
	[observer associateValue:observingInfo forKey:kObservingInfoKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// Add observer to self
	[self addObserver:observer forKeyPath:keyPath options:options context:NULL];
	
	return [observer autorelease];
}

- (NSDictionary*)observingInfo
{
	// Get observingInfo
	NSDictionary *observingInfo;
	@synchronized (self) {
		observingInfo = [[[self associatedValueForKey:kObservingInfoKey] retain] autorelease];
	}
	
	return observingInfo;
}

- (void)stopObserving
{
	@synchronized (self) {
		// Get observingInfo
		NSDictionary *observingInfo;
		observingInfo = [self observingInfo];
		if (!observingInfo) {
			return;
		}
		
		// Stop observing
		id object;
		NSString *keyPath;
		object = [observingInfo objectForKey:REObservingInfoObjectKey];
		keyPath = [observingInfo objectForKey:REObservingInfoKeyPathKey];
		[object removeObserver:self forKeyPath:keyPath];
	}
}

- (void)OBSX_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	@synchronized (self) {
		// Get observingInfo
		NSDictionary *observingInfo;
		observingInfo = [self observingInfo];
		if (!observingInfo) {
			return;
		}
		
		// Check elements
		if ([observingInfo objectForKey:REObservingInfoObjectKey] != object
			|| ![[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]
		){
			return;
		}
		
		// Execute block
		REObserverHandler block;
		block = [observingInfo objectForKey:REObservingInfoBlockKey];
		if (!block) {
			return;
		}
		block(change);
	}
}

- (void)OBSX_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath
{
	@synchronized (self) {
		// Get observingInfo
		NSDictionary *observingInfo;
		observingInfo = [observer observingInfo];
		if (observingInfo
			&& [observingInfo objectForKey:REObservingInfoObjectKey] == self
			&& [[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]
		){
			// Release block
			id block;
			block = [observingInfo objectForKey:REObservingInfoBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove observingInfo
			[observer associateValue:nil forKey:kObservingInfoKey policy:OBJC_ASSOCIATION_RETAIN];
		}
	}
	
	// original
	[self OBSX_removeObserver:observer forKeyPath:keyPath];
}

- (void)OBSX_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context
{
	@synchronized (self) {
		// Get observingInfo
		NSDictionary *observingInfo;
		observingInfo = [observer observingInfo];
		if (observingInfo
			&& [observingInfo objectForKey:REObservingInfoObjectKey] == self
			&& [[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]
			&& context == nil
		){
			// Release block
			id block;
			block = [observingInfo objectForKey:REObservingInfoBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove observingInfo
			[observer associateValue:nil forKey:kObservingInfoKey policy:OBJC_ASSOCIATION_RETAIN];
		}
	}
	
	// original
	[self OBSX_removeObserver:observer forKeyPath:keyPath context:context];
}

@end
