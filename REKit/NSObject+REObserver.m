/*
 NSObject+REObserver.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "NSObject+REObserver.h"
#import "REUtil.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kObservingInfosAssociationKey = @"REObserver_observingInfos";
static NSString* const kObservedInfosAssociationKey = @"REObserver_observedInfos";
static NSString* const kIsChangingClassByMyselfAssociationKey = @"REObserver_isChangingClassByMyself"; // Tests >>>
static NSString* const kIsChangingClassAssociationKey = @"REObserver_isChangingClass"; // Tests >>>

// Keys for observing/observedInfo
NSString* const REObserverObservedObjectPointerValueKey = @"observedObjectPointerValue";
NSString* const REObserverObservingObjectPointerValueKey = @"observingObjectPointerValue";
NSString* const REObserverKeyPathKey = @"keyPath";
NSString* const REObserverOptionsKey = @"options";
NSString* const REObserverContextPointerValueKey = @"contextPointerValue";
NSString* const REObserverBlockKey = @"block";
NSString* const REObserverContainerKey = @"container";


@interface NSArray (REObserver)
- (void)REObserver_X_addObserver:(NSObject *)observer toObjectsAtIndexes:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)REObserver_X_removeObserver:(NSObject *)observer fromObjectsAtIndexes:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath;
@end


//--------------------------------------------------------------//
#pragma mark - NSObject
//--------------------------------------------------------------//

@implementation NSObject (REObserver)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

- (void)REObserver_X_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	// Filter
	if (!observer || ![keyPath length]) {
		return;
	}
	
	// Get copiedKeyPath
	NSString *copiedKeyPath;
	copiedKeyPath = [[keyPath copy] autorelease];
	
	// Make observingInfo
	NSMutableDictionary *observingInfo;
	observingInfo = [NSMutableDictionary dictionaryWithDictionary:@{
		REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:self],
		REObserverKeyPathKey : copiedKeyPath,
		REObserverOptionsKey : @(options),
	}];
	if (context) {
		observingInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
	}
	
	// Make observedInfo
	NSMutableDictionary *observedInfo;
	observedInfo = [NSMutableDictionary dictionaryWithDictionary:@{
		REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
		REObserverKeyPathKey : keyPath,
		REObserverOptionsKey : @(options),
	}];
	if (context) {
		observedInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
	}
	
	@synchronized (self) {
		// Add observingInfo
		NSMutableArray *observingInfos;
		observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
		if (!observingInfos) {
			observingInfos = [NSMutableArray array];
			[observer setAssociatedValue:observingInfos forKey:kObservingInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		}
		[observingInfos addObject:observingInfo];
		
		// Add observedInfo
		NSMutableArray *observedInfos;
		observedInfos = [self associatedValueForKey:kObservedInfosAssociationKey];
		if (!observedInfos) {
			observedInfos = [NSMutableArray array];
			[self setAssociatedValue:observedInfos forKey:kObservedInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		}
		[observedInfos addObject:observedInfo];
	}
	
	
	// Will change class?
	NSString *originalClassName;
	BOOL willChange; // Tests >>>
	originalClassName = NSStringFromClass(REGetClass(self));
	willChange = ![originalClassName hasPrefix:@"NSKVONotifying_"];
	
	// Call willChangeClass:
	if (willChange) {
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		[self willChangeClass:[NSString stringWithFormat:@"NSKVONotifying_%@", originalClassName]];
	}
	
	// original
	[self REObserver_X_addObserver:observer forKeyPath:keyPath options:options context:context];
	
	// Call didChangeClass:
	if (willChange) {
		[self didChangeClass:originalClassName];
		[self setAssociatedValue:nil forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	}
}

- (void)REObserver_X_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	@synchronized (self) {
		// Get observingInfo
		__block NSDictionary *observingInfo = nil;
		[[self observingInfos] enumerateObjectsUsingBlock:^(NSDictionary *anObservingInfo, NSUInteger idx, BOOL *stop) {
			if ([anObservingInfo[REObserverObservedObjectPointerValueKey] pointerValue] == object
				&& [anObservingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
			){
				observingInfo = anObservingInfo;
				*stop = YES;
			}
		}];
		if (!observingInfo) {
			return;
		}
		
		// Execute block
		REObserverHandler block;
		block = observingInfo[REObserverBlockKey];
		if (!block) {
			return;
		}
		block(change);
	}
}

- (void)REObserver_X_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath
{
	// Filter
	if (!observer || ![keyPath length]) {
		return;
	}
	
	@synchronized (self) {
		// Get observingInfos
		NSMutableArray *observingInfos;
		observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
		
		// Get observedInfos
		NSMutableArray *observedInfos;
		observedInfos = [self associatedValueForKey:kObservedInfosAssociationKey];
		
		// Remove observingInfo
		[observingInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observingInfo, NSUInteger idx, BOOL *stop) {
			if ([observingInfo[REObserverObservedObjectPointerValueKey] pointerValue] == self
				&& [observingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				&& (observingInfo[REObserverContainerKey] || observingInfo[REObserverContextPointerValueKey] == nil)
			){
				// Remove observingInfo
				[observingInfos removeObject:observingInfo];
			}
		}];
		
		// Remove observedInfo
		[observedInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
			if ([observedInfo[REObserverObservingObjectPointerValueKey] pointerValue] == observer
				&& [observedInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				&& (observedInfo[REObserverContainerKey] || observedInfo[REObserverContextPointerValueKey] == nil)
			){
				// Remove observedInfo
				[observedInfos removeObject:observedInfo];
			}
		}];
	}
	
	// Will change class?
	BOOL willChangeClass;
	NSString *originalClassName = nil;
	willChangeClass = ([[self observedInfos] count] == 0); // Tests >>>
	
	// Call willChangeClass:
	if (willChangeClass) {
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		originalClassName = NSStringFromClass(REGetClass(self));
		[self willChangeClass:NSStringFromClass(REGetSuperclass(self))];
	}
	
	// original
	[self REObserver_X_removeObserver:observer forKeyPath:keyPath];
	
	// Call didChangeClass:
	if (willChangeClass) {
		[self didChangeClass:originalClassName];
		[self setAssociatedValue:nil forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	}
}

- (void)REObserver_X_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context
{
	// Filter
	if (!observer || ![keyPath length]) {
		return;
	}
	
	if (context) {
		@synchronized (self) {
			// Get observingInfos
			NSMutableArray *observingInfos;
			observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
			
			// Get observedInfos
			NSMutableArray *observedInfos;
			observedInfos = [self associatedValueForKey:kObservedInfosAssociationKey];
			
			// Remove observingInfo
			[observingInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observingInfo, NSUInteger idx, BOOL *stop) {
				if ([observingInfo[REObserverObservedObjectPointerValueKey] pointerValue] == self
					&& [observingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
					&& (observingInfo[REObserverContainerKey] || [observingInfo[REObserverContextPointerValueKey] pointerValue] == context)
				){
					// Remove observingInfo
					[observedInfos removeObject:observingInfo];
					[observingInfos removeObject:observingInfo];
				}
			}];
			
			// Remove observedInfo
			[observedInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
				if ([observedInfo[REObserverObservingObjectPointerValueKey] pointerValue] == observer
					&& [observedInfo[REObserverKeyPathKey] isEqualToString:keyPath]
					&& (observedInfo[REObserverContainerKey] || [observedInfo[REObserverContextPointerValueKey] pointerValue] == context)
				){
					[observedInfos removeObject:observedInfo];
				}
			}];
			
			// Will change class?
			BOOL willChangeClass; // Tests >>>
			NSString *originalClassName;
			willChangeClass = ([[self observedInfos] count] == 0);
			
			// Call willChangeClass:
			if (willChangeClass) {
				[self setAssociatedValue:@(YES) forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
				originalClassName = NSStringFromClass(REGetClass(self));
				[self willChangeClass:NSStringFromClass(REGetSuperclass(self))];
			}
			
			// original
			[self REObserver_X_removeObserver:observer forKeyPath:keyPath context:context];
			
			// Call didChangeClass:
			if (willChangeClass) {
				[self didChangeClass:originalClassName];
				[self setAssociatedValue:nil forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
		}
	}
	else {
		// original
		[self REObserver_X_removeObserver:observer forKeyPath:keyPath context:context];
	}
}

- (void)REObserver_X_willChangeClass:(NSString*)toClassName
{
	// Remove observers
	if (![[self associatedValueForKey:kIsChangingClassByMyselfAssociationKey] boolValue]
		&& ![[self associatedValueForKey:kIsChangingClassAssociationKey] boolValue]
	){
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		
		NSArray *observedInfos;
		observedInfos = [self observedInfos];
		[observedInfos enumerateObjectsUsingBlock:^(NSMutableDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
			// Get elements
			id observingObject;
			NSString *keyPath;
			void *context;
			observingObject = [observedInfo[REObserverObservingObjectPointerValueKey] pointerValue];
			keyPath = observedInfo[REObserverKeyPathKey];
			context = [observedInfo[REObserverContextPointerValueKey] pointerValue];
			
			// Remove observer
			if (context) {
				[self REObserver_X_removeObserver:observingObject forKeyPath:keyPath context:context];
			}
			else {
				[self REObserver_X_removeObserver:observingObject forKeyPath:keyPath];
			}
		}];
	}
	
	// original
	[self REObserver_X_willChangeClass:toClassName];
}

- (void)REObserver_X_didChangeClass:(NSString*)fromClassName
{
	if (![[self associatedValueForKey:kIsChangingClassByMyselfAssociationKey] boolValue]) {
		// Add observers removed in willChangeClass: method
		[[self observedInfos] enumerateObjectsUsingBlock:^(NSMutableDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
			// Get elements
			id observingObject;
			NSString *keyPath;
			void *context;
			NSKeyValueObservingOptions options;
			observingObject = [observedInfo[REObserverObservingObjectPointerValueKey] pointerValue];
			keyPath = observedInfo[REObserverKeyPathKey];
			options = [observedInfo[REObserverOptionsKey] integerValue];
			context = [observedInfo[REObserverContextPointerValueKey] pointerValue];
			
			// Add observer
			id container;
			container = observedInfo[REObserverContainerKey];
			if ([container containsObject:self]) {
				NSUInteger index;
				index = [container indexOfObject:self];
				[container REObserver_X_addObserver:observingObject toObjectsAtIndexes:[NSIndexSet indexSetWithIndex:index] forKeyPath:keyPath options:options context:context];
			}
			else {
				[self REObserver_X_addObserver:observingObject forKeyPath:keyPath options:options context:context];
			}
		}];
	}
	
	// original
	[self REObserver_X_didChangeClass:fromClassName];
	
	// Down isChangingClass flag
	[self setAssociatedValue:nil forKey:kIsChangingClassAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
}

- (void)REObserver_X_release
{
	@synchronized (self) {
		if ([self retainCount] == 1) {
			// Stop observing
			[self stopObserving];
			
			// Stop being observed
			NSMutableArray *observedInfos;
			observedInfos = [self associatedValueForKey:kObservedInfosAssociationKey];
			while ([observedInfos count]) {
				// Get observedInfo
				NSDictionary *observedInfo;
				observedInfo = [observedInfos lastObject];
				
				// Remove observer
				NSValue *contextPointerValue;
				contextPointerValue = observedInfo[REObserverContextPointerValueKey];
				if (contextPointerValue) {
					[self removeObserver:[observedInfo[REObserverObservingObjectPointerValueKey] pointerValue] forKeyPath:observedInfo[REObserverKeyPathKey] context:[contextPointerValue pointerValue]];
				}
				else {
					[self removeObserver:[observedInfo[REObserverObservingObjectPointerValueKey] pointerValue] forKeyPath:observedInfo[REObserverKeyPathKey]];
				}
			}
		}
		
		// original
		[self REObserver_X_release];
	}
}

+ (void)load
{
	@autoreleasepool {
		// Exchange methods…
		[self exchangeInstanceMethodsWithAdditiveSelectorPrefix:@"REObserver_X_" selectors:
			@selector(addObserver:forKeyPath:options:context:),
			@selector(observeValueForKeyPath:ofObject:change:context:),
			@selector(removeObserver:forKeyPath:),
			@selector(removeObserver:forKeyPath:context:),
			@selector(willChangeClass:),
			@selector(didChangeClass:),
			@selector(release),
			nil
		];
	}
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
	observer = [[NSObject alloc] init];
	
	// Get copied elements
	id copiedBock;
	NSString *copiedKeyPath;
	copiedBock = Block_copy(block);
	copiedKeyPath = [[keyPath copy] autorelease];
	
	@synchronized (self) {
		// Make observingInfo
		NSMutableDictionary *observingInfo;
		observingInfo = [NSMutableDictionary dictionaryWithDictionary:@{
			REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:self],
			REObserverKeyPathKey : copiedKeyPath,
			REObserverOptionsKey : @(options),
			REObserverBlockKey : copiedBock,
		}];
		
		// Add observingInfo
		NSMutableArray *observingInfos;
		observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
		if (!observingInfos) {
			observingInfos = [NSMutableArray array];
			[observer setAssociatedValue:observingInfos forKey:kObservingInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		}
		[observingInfos addObject:observingInfo];
		
		// Make observedInfo
		NSMutableDictionary *observedInfo;
		observedInfo = [NSMutableDictionary dictionaryWithDictionary:@{
			REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
			REObserverKeyPathKey : copiedKeyPath,
			REObserverOptionsKey : @(options),
			REObserverBlockKey : copiedBock,
		}];
		
		// Add observedInfo
		NSMutableArray *observedInfos;
		observedInfos = [self associatedValueForKey:kObservedInfosAssociationKey];
		if (!observedInfos) {
			observedInfos = [NSMutableArray array];
			[self setAssociatedValue:observedInfos forKey:kObservedInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		}
		[observedInfos addObject:observedInfo];
	}
	
	// Release copiedBlock
	Block_release(copiedBock);
	
	// Add observer to self using original implementation
	[self REObserver_X_addObserver:observer forKeyPath:keyPath options:options context:nil];
	
	return [observer autorelease];
}

- (NSArray*)observingInfos
{
	@synchronized (self) {
		return [NSArray arrayWithArray:[self associatedValueForKey:kObservingInfosAssociationKey]];
	}
}

- (NSArray*)observedInfos
{
	@synchronized (self) {
		return [NSArray arrayWithArray:[self associatedValueForKey:kObservedInfosAssociationKey]];
	}
}

- (void)stopObserving
{
	@synchronized (self) {
		// Enumerate observingInfos
		NSMutableArray *observingInfos;
		observingInfos = [self associatedValueForKey:kObservingInfosAssociationKey];
		while ([observingInfos count]) {
			// Get observingInfo
			NSDictionary *observingInfo;
			observingInfo = [observingInfos lastObject];
			
			// Stop observing
			id observedObject;
			NSString *keyPath;
			void *context;
			observedObject = [observingInfo[REObserverObservedObjectPointerValueKey] pointerValue];
			keyPath = observingInfo[REObserverKeyPathKey];
			context = [observingInfo[REObserverContextPointerValueKey] pointerValue];
			if (context) {
				[observedObject removeObserver:self forKeyPath:keyPath context:context];
			}
			else {
				[observedObject removeObserver:self forKeyPath:keyPath];
			}
		}
	}
}

@end


//--------------------------------------------------------------//
#pragma mark - NSArray
//--------------------------------------------------------------//

@implementation NSArray (REObserver)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

- (void)REObserver_X_addObserver:(NSObject *)observer toObjectsAtIndexes:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	// Filter
	if (!observer || ![keyPath length]) {
		return;
	}
	
	// Get copiedKeyPath
	NSString *copiedKeyPath;
	copiedKeyPath = [[keyPath copy] autorelease];
	
	// Enumerate objects
	@synchronized (self) {
		[self enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			// Make observingInfo
			NSMutableDictionary *observingInfo;
			observingInfo = [NSMutableDictionary dictionaryWithDictionary:@{
				REObserverObservedObjectPointerValueKey : [NSValue valueWithPointer:obj],
				REObserverContainerKey : self,
				REObserverKeyPathKey : copiedKeyPath,
				REObserverOptionsKey : @(options),
			}];
			if (context) {
				observingInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
			}
			
			// Add observingInfo
			NSMutableArray *observingInfos;
			observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
			if (!observingInfos) {
				observingInfos = [NSMutableArray array];
				[observer setAssociatedValue:observingInfos forKey:kObservingInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			[observingInfos addObject:observingInfo];
			
			// Make observedInfo
			NSMutableDictionary *observedInfo;
			observedInfo = [NSMutableDictionary dictionaryWithDictionary:@{
				REObserverObservingObjectPointerValueKey : [NSValue valueWithPointer:observer],
				REObserverContainerKey : self,
				REObserverKeyPathKey : copiedKeyPath,
				REObserverOptionsKey : @(options),
			}];
			if (context) {
				observedInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
			}
			
			// Add observedInfo
			NSMutableArray *observedInfos;
			observedInfos = [obj associatedValueForKey:kObservedInfosAssociationKey];
			if (!observedInfos) {
				observedInfos = [NSMutableArray array];
				[obj setAssociatedValue:observedInfos forKey:kObservedInfosAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
			}
			[observedInfos addObject:observedInfo];
		}];	
	}
	
	// Will change class?
	NSString *originalClassName;
	BOOL willChange;
	originalClassName = NSStringFromClass(REGetClass(self));
	willChange = ![originalClassName hasPrefix:@"NSKVONotifying_"]; // Tests >>>
	
	// Call willChangeClass:
	if (willChange) {
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		[self willChangeClass:[NSString stringWithFormat:@"NSKVONotifying_%@", originalClassName]];
	}
	
	// original
	[self REObserver_X_addObserver:observer toObjectsAtIndexes:indexes forKeyPath:keyPath options:options context:context];
	
	// Call didChangeClass:
	if (willChange) {
		[self didChangeClass:originalClassName];
		[self setAssociatedValue:nil forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	}
}

- (void)REObserver_X_removeObserver:(NSObject *)observer fromObjectsAtIndexes:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath
{
	// Filter
	if (!observer || ![indexes count] || ![keyPath length]) {
		return;
	}
	
	@synchronized (self) {
		[self enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			// Get observingInfos
			NSMutableArray *observingInfos;
			observingInfos = [observer associatedValueForKey:kObservingInfosAssociationKey];
			
			// Get observedInfos
			NSMutableArray *observedInfos;
			observedInfos = [obj associatedValueForKey:kObservedInfosAssociationKey];
			
			// Remove observingInfo
			[observingInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observingInfo, NSUInteger idx, BOOL *stop) {
				if ([observingInfo[REObserverObservedObjectPointerValueKey] pointerValue] == obj
					&& [observingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				){
					// Remove observingInfo
					[observingInfos removeObject:observingInfo];
				}
			}];
			
			// Remove observedInfo
			[observedInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
				if ([observedInfo[REObserverObservingObjectPointerValueKey] pointerValue] == observer
					&& [observedInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				){
					// Remove observedInfo
					[observedInfos removeObject:observedInfo];
				}
			}];
		}];
	}
	
	// Will change class?
	BOOL willChangeClass;
	willChangeClass = ([[self observedInfos] count] == 0); // Tests >>>
	
	// Call willChangeClass:
	NSString *originalClassName;
	if (willChangeClass) {
		[self setAssociatedValue:@(YES) forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
		originalClassName = NSStringFromClass(REGetClass(self));
		[self willChangeClass:NSStringFromClass(REGetSuperclass(self))];
	}
	
	// original
	[self REObserver_X_removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:keyPath];
	
	// Call didChangeClass:
	if (willChangeClass) {
		[self didChangeClass:originalClassName];
		[self setAssociatedValue:nil forKey:kIsChangingClassByMyselfAssociationKey policy:OBJC_ASSOCIATION_RETAIN];
	}
}

+ (void)load
{
	@autoreleasepool {
		// Exchange methods…
		[self exchangeInstanceMethodsWithAdditiveSelectorPrefix:@"REObserver_X_" selectors:
			@selector(addObserver:toObjectsAtIndexes:forKeyPath:options:context:),
			@selector(removeObserver:fromObjectsAtIndexes:forKeyPath:),
			nil
		];
	}
}

@end
