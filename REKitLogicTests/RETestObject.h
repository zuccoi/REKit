/*
 RETestObject.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface RETestObject : NSObject

// Property
@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger age;

// Object
+ (instancetype)testObject;

// Methods
- (NSString*)log;
- (NSString*)say;
- (NSUInteger)ageAfterYears:(NSUInteger)years;

@end
