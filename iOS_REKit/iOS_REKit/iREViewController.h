/*
 iREViewController.h
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <UIKit/UIKit.h>


@interface iREViewController : UIViewController

// Property
@property (weak, nonatomic) IBOutlet UILabel *label;

// Action
- (IBAction)changeBackgroundColorAction:(id)sender;

@end
