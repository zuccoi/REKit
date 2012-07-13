/*
 NSObject+REObserver.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Handler
typedef void (^REObserverHandler)(NSDictionary *change);

// Keys for observingInfo
extern NSString* const REObservingInfoObjectKey;
extern NSString* const REObservingInfoIndexSetKey;
extern NSString* const REObservingInfoKeyPathKey;
extern NSString* const REObservingInfoOptionsKey;
extern NSString* const REObservingInfoContextKey;
extern NSString* const REObservingInfoBlockKey;


@interface NSObject (REObserver)

- (NSArray*)observingInfos;
- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block;
- (id)addObserverToObjectsAtIndexes:(NSIndexSet*)indexes forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block;
- (void)stopObservingWithObservingInfo:(NSDictionary*)observingInfo;
- (void)stopObserving;

@end
