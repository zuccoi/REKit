/*
 RETestObject.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "RETestObject.h"

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation RETestObject

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

+ (instancetype)testObject
{
	return [[[RETestObject alloc] init] autorelease];
}

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

- (NSString*)log
{
	return @"log";
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
