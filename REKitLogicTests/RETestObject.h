/*
 RETestObject.h
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface NSObject (RETest)
+ (instancetype)object;
@end


@interface RETestObject : NSObject

// Property
@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) NSUInteger age;
@property (assign, nonatomic) CGRect rect;

// Methods
- (void)overrideMe;
- (NSString*)log;
- (NSString*)overrideLog;
- (NSString*)say;
- (void)sayHello;
- (NSUInteger)ageAfterYears:(NSUInteger)years;
+ (NSString*)classLog;
+ (NSInteger)integerWithInteger:(NSInteger)integer;
+ (CGRect)theRect;
+ (void)sayHello;

@end

@interface RESubTestObject : RETestObject
- (void)overrideMe;
- (NSString*)subLog;
- (NSString*)overrideLog;
+ (CGRect)theRect;
+ (CGRect)subRect;
@end
