/*
 NSObject+REObserver.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "NSObject+REObserver.h"
#import "REUtil.h"


// Keys for observingInfo
NSString* const REObservingInfoObjectKey = @"REObservingInfoObjectKey";
NSString* const REObservingInfoIndexSetKey = @"REObservingInfoIndexSetKey";
NSString* const REObservingInfoKeyPathKey = @"REObservingInfoKeyPathKey";
NSString* const REObservingInfoOptionsKey = @"REObservingInfoOptionsKey";
NSString* const REObservingInfoContextKey = @"REObservingInfoContextKey";
NSString* const REObservingInfoBlockKey = @"REObservingInfoBlockKey";

// Constants
static NSString* const kObservingInfosKey = @"REObserver_observingInfosKey";


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
	// Release observingInfos
	if ([self associatedValueForKey:kObservingInfosKey]) {
		// Stop observing
		[self stopObserving];
		
		// Release observingInfos
		[self associateValue:nil forKey:kObservingInfosKey policy:OBJC_ASSOCIATION_RETAIN];
	}
	
	// original
	[self OBSX_dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Observer --
//--------------------------------------------------------------//

- (NSMutableArray*)OBS_observingInfos
{
	// Get observingInfos
	NSMutableArray *observingInfos;
	@synchronized (self) {
		observingInfos = [self associatedValueForKey:kObservingInfosKey];
		if (!observingInfos) {
			observingInfos = [NSMutableArray array];
			[self associateValue:observingInfos forKey:kObservingInfosKey policy:OBJC_ASSOCIATION_RETAIN];
		}
	}
	
	return observingInfos;
}

- (NSArray*)observingInfos
{
	return [self OBS_observingInfos];
}

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block
{
	// Filter
	if (![keyPath length] || !block) {
		return nil;
	}
	
	// Make observer
	id observer;
	observer = [[NSObject alloc] init];
	
	// Update observingInfos of observer
	NSDictionary *observingInfo;
	observingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, REObservingInfoObjectKey,
		keyPath, REObservingInfoKeyPathKey,
		[NSNumber numberWithInteger:options], REObservingInfoOptionsKey,
		Block_copy(block), REObservingInfoBlockKey,
		nil];
	@synchronized (self) {
		[[observer OBS_observingInfos] addObject:observingInfo];
	}
	
	// Add observer
	[self addObserver:observer forKeyPath:keyPath options:options context:NULL];
	
	return [observer autorelease];
}

- (void)stopObservingWithObservingInfo:(NSDictionary*)observingInfo
{
	id object;
	NSIndexSet *indexSet;
	NSString *keyPath;
	void *context;
	object = [observingInfo objectForKey:REObservingInfoObjectKey];
	indexSet = [observingInfo objectForKey:REObservingInfoIndexSetKey];
	keyPath = [observingInfo objectForKey:REObservingInfoKeyPathKey];
	context = [observingInfo objectForKey:REObservingInfoContextKey];
	if (indexSet) {
		[object removeObserver:self fromObjectsAtIndexes:indexSet forKeyPath:keyPath context:context];
	}
	else {
		[object removeObserver:self forKeyPath:keyPath context:context];
	}
}

- (void)stopObserving
{
	// Stop observing
	for (NSDictionary *observingInfo in [[self OBS_observingInfos] reverseObjectEnumerator]) {
		[self stopObservingWithObservingInfo:observingInfo];
	}
}

- (void)OBSX_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	// Execute block
	REObserverHandler block;
	for (NSDictionary *observingInfo in [self observingInfos]) {
		if ([observingInfo objectForKey:REObservingInfoObjectKey] == object
			&& [[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]
			&& [observingInfo objectForKey:REObservingInfoContextKey] == context
		){
			block = [observingInfo objectForKey:REObservingInfoBlockKey];
			if (block) {
				block(change);
				return;
			}
		}
	}
}

- (void)OBSX_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath
{
	@synchronized (self) {
		// Update observingInfos of observer
		NSMutableArray *observingInfos;
		id block;
		observingInfos = [observer OBS_observingInfos];
		for (NSDictionary *observingInfo in [observingInfos reverseObjectEnumerator]) {
			// Check elements
			if ([observingInfo objectForKey:REObservingInfoObjectKey] != self) {
				continue;
			}
			if ([observingInfo objectForKey:REObservingInfoIndexSetKey] != nil) {
				continue;
			}
			if (![[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]) {
				continue;
			}
			
			// Release block
			block = [observingInfo objectForKey:REObservingInfoBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove observingInfo
			[observingInfos removeObject:observingInfo];
		}
	}
	
	// original
	[self OBSX_removeObserver:observer forKeyPath:keyPath];
}

- (void)OBSX_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context
{
	@synchronized (self) {
		// Update observingInfos of observer
		NSMutableArray *observingInfos;
		id block;
		observingInfos = [observer OBS_observingInfos];
		for (NSDictionary *observingInfo in [observingInfos reverseObjectEnumerator]) {
			// Check elements
			if ([observingInfo objectForKey:REObservingInfoObjectKey] != self) {
				continue;
			}
			if ([observingInfo objectForKey:REObservingInfoIndexSetKey] != nil) {
				continue;
			}
			if (![[observingInfo objectForKey:REObservingInfoKeyPathKey] isEqualToString:keyPath]) {
				continue;
			}
			if ([observingInfo objectForKey:REObservingInfoContextKey] != context) {
				continue;
			}
			
			// Release block
			block = [observingInfo objectForKey:REObservingInfoBlockKey];
			if (block) {
				Block_release(block);
			}
			
			// Remove observingInfo
			[observingInfos removeObject:observingInfo];
		}
	}
	
	// original
	[self OBSX_removeObserver:observer forKeyPath:keyPath context:context];
}

@end
