/*
 NSObject+REObserver.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Keys for observingInfo
extern NSString* const REObservingInfoObjectKey;
extern NSString* const REObservingInfoKeyPathKey;
extern NSString* const REObservingInfoOptionsKey;
extern NSString* const REObservingInfoBlockKey;

// REObserverHandler
typedef void (^REObserverHandler)(NSDictionary *change);


@interface NSObject (REObserver)

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block;		// Don't pass returned object to addObserver:forKeyPath:options:context: and addObserver:toObjectsAtIndexes:forKeyPath:options:context:.
- (NSDictionary*)observingInfo;
- (void)stopObserving;

@end
