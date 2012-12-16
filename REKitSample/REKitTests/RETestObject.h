/*
 RETestObject.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface RETestObject : NSObject

// Property
@property (retain, nonatomic) NSString *name;

// Object
+ (instancetype)testObject;

// Methods
- (NSString*)log;
- (NSString*)say;

@end
