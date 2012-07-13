/*
 RSAppDelegate.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <UIKit/UIKit.h>
@class RSMasterViewController;


@interface RSAppDelegate : UIResponder <UIApplicationDelegate>

// Property
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) RSMasterViewController *masterViewController;

@end
