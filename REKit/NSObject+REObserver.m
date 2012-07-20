/*
 NSObject+REObserver.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "NSObject+REObserver.h"
#import "REUtil.h"


// Constants
static NSString* const kObservingInfoKey = @"REObserver_observingInfoKey";

// Keys for observingInfo
static NSString* const kObservingInfoObjectKey = @"kObservingInfoObjectKey";
static NSString* const kObservingInfoKeyPathKey = @"kObservingInfoKeyPathKey";
static NSString* const kObservingInfoOptionsKey = @"kObservingInfoOptionsKey";
static NSString* const kObservingInfoBlockKey = @"kObservingInfoBlockKey";


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
		self, kObservingInfoObjectKey,
		keyPath, kObservingInfoKeyPathKey,
		[NSNumber numberWithInteger:options], kObservingInfoOptionsKey,
		Block_copy(block), kObservingInfoBlockKey,
		nil];
	[observer associateValue:observingInfo forKey:kObservingInfoKey policy:OBJC_ASSOCIATION_RETAIN];
	
	// Add observer to self
	[self addObserver:observer forKeyPath:keyPath options:options context:NULL];
	
	return [observer autorelease];
}

- (void)stopObserving
{
	// Get observingInfo
	NSDictionary *observingInfo;
	observingInfo = [self associatedValueForKey:kObservingInfoKey];
	if (!observingInfo) {
		return;
	}
	
	// Stop observing
	id object;
	NSString *keyPath;
	object = [observingInfo objectForKey:kObservingInfoObjectKey];
	keyPath = [observingInfo objectForKey:kObservingInfoKeyPathKey];
	[object removeObserver:self forKeyPath:keyPath];
}

- (void)OBSX_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	// Get observingInfo
	NSDictionary *observingInfo;
	observingInfo = [self associatedValueForKey:kObservingInfoKey];
	if (!observingInfo) {
		return;
	}
	
	// Check elements
	if ([observingInfo objectForKey:kObservingInfoObjectKey] != object
		|| ![[observingInfo objectForKey:kObservingInfoKeyPathKey] isEqualToString:keyPath]
	){
		return;
	}
	
	// Execute block
	REObserverHandler block;
	block = [observingInfo objectForKey:kObservingInfoBlockKey];
	if (!block) {
		return;
	}
	block(change);
}

- (void)OBSX_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath
{
	@synchronized (self) {
		// Get observingInfo
		NSDictionary *observingInfo;
		observingInfo = [self associatedValueForKey:kObservingInfoKey];
		if (observingInfo
			&& [observingInfo objectForKey:kObservingInfoObjectKey] == self
			&& [[observingInfo objectForKey:kObservingInfoKeyPathKey] isEqualToString:keyPath]
		){
			// Release block
			id block;
			block = [observingInfo objectForKey:kObservingInfoBlockKey];
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
		observingInfo = [observer associatedValueForKey:kObservingInfoKey];
		if (observingInfo
			&& [observingInfo objectForKey:kObservingInfoObjectKey] == self
			&& [[observingInfo objectForKey:kObservingInfoKeyPathKey] isEqualToString:keyPath]
			&& context == nil
		){
			// Release block
			id block;
			block = [observingInfo objectForKey:kObservingInfoBlockKey];
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
