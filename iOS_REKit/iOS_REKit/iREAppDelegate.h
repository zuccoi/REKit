/*
 iREAppDelegate.h
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <UIKit/UIKit.h>
@class iREViewController;


@interface iREAppDelegate : UIResponder <UIApplicationDelegate>

// Property
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) iREViewController *viewController;

@end
