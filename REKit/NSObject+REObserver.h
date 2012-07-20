/*
 NSObject+REObserver.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Handler
typedef void (^REObserverHandler)(NSDictionary *change);


@interface NSObject (REObserver)

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block;		// Don't pass returned object to addObserver:forKeyPath:options:context: and addObserver:toObjectsAtIndexes:forKeyPath:options:context:.
- (NSDictionary*)observingInfo;
- (void)stopObserving;

@end
