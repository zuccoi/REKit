/*
 RETestObject.h
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface RETestObject : NSObject

// Property
@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger age;
@property (assign, nonatomic) CGRect rect;

// Object
+ (instancetype)testObject;

// Methods
- (NSString*)log;
- (NSString*)say;
- (void)sayHello;
- (NSUInteger)ageAfterYears:(NSUInteger)years;
+ (NSInteger)integerWithInteger:(NSInteger)integer;
+ (CGRect)theRect;
+ (void)sayHello;

@end

@interface RESubTestObject : RETestObject
+ (CGRect)theRect;
+ (CGRect)subRect;
@end
