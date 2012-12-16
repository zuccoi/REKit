/*
 RETestObject.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "RETestObject.h"


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
#pragma mark -- Log --
//--------------------------------------------------------------//

- (NSString*)log
{
	return @"log";
}

- (NSString*)say
{
	return @"say";
}

@end
