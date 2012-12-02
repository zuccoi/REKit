/*
 NSObject+REObserver.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Keys for observingInfo
extern NSString* const REObserverObservedObjectKey; // observed object is observed
extern NSString* const REObserverObservingObjectKey; // observing object is observing
extern NSString* const REObserverKeyPathKey;
extern NSString* const REObserverOptionsKey;
extern NSString* const REObserverContextKey;
extern NSString* const REObserverBlockKey;

// REObserverHandler
typedef void (^REObserverHandler)(NSDictionary *change);


@interface NSObject (REObserver)

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block;
- (NSArray*)observingInfos;
- (NSArray*)observedInfos;
- (void)stopObserving;

@end
