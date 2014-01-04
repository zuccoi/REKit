/*
 RETestObject.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "RETestObject.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation NSObject (RETest)

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

+ (instancetype)object
{
	return [[[self alloc] init] autorelease];
}

@end


@implementation RETestObject

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"name"]) {
		return YES;
	}
	
	return [super automaticallyNotifiesObserversForKey:key];
}

//--------------------------------------------------------------//
#pragma mark -- Methods --
//--------------------------------------------------------------//

- (void)overrideMe
{
}

- (NSString*)log
{
	return @"log";
}

- (NSString*)overrideLog
{
	return @"RETestObject";
}

- (NSString*)say
{
	return @"say";
}

- (void)sayHello
{
	NSLog(@"Hello");
}

- (NSUInteger)ageAfterYears:(NSUInteger)years
{
	return self.age + years;
}

+ (NSString*)classLog
{
	return @"classLog";
}

+ (NSInteger)integerWithInteger:(NSInteger)integer
{
	return integer;
}

+ (CGRect)theRect
{
	return CGRectMake(100.0, 200.0, 300.0, 400.0);
}

+ (void)sayHello
{
	NSLog(@"Hello");
}

@end


@implementation RESubTestObject

- (void)overrideMe
{
}

- (NSString*)subLog
{
	return @"subLog";
}

- (NSString*)overrideLog
{
	return @"RESubTestObject";
}

+ (CGRect)theRect
{
	return CGRectMake(100.0, 200.0, 300.0, 400.0);
}

+ (CGRect)subRect
{
	return CGRectMake(10.0, 20.0, 30.0, 40.0);
}

@end
