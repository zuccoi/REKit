/*
 REResponderTests.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REResponderTests.h"
#import "REKit.h"
#import "RSClassA.h"


@implementation REResponderTests

- (void)test_dynamicImplementation
{
	id obj;
	SEL sel;
	__block NSString *message = nil;
	sel = @selector(say:);
	obj = [[[NSObject alloc] init] autorelease];
	[obj respondsToSelector:sel withBlockName:nil usingBlock:^(id me, NSString *string) {
		message = string;
	}];
	[obj performSelector:sel withObject:@"Hello"];
	STAssertEqualObjects(message, @"Hello", @"");
}

@end
