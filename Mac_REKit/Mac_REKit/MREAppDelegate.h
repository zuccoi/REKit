/*
 MREAppDelegate.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
@class MREViewController;


@interface MREAppDelegate : NSObject <NSApplicationDelegate>

// Property
@property (assign, nonatomic) IBOutlet NSWindow *window;
@property (assign, nonatomic) IBOutlet NSView *view;
@property (strong, nonatomic) MREViewController *viewController;

@end
