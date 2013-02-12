/*
 iREViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "iREViewController.h"


@implementation iREViewController
{
	__block id _observer;
}

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (id)initWithCoder:(NSCoder *)aDecoder
{
	// super
	self = [super initWithCoder:aDecoder];
	if (!self) {
		return nil;
	}
	
	// Manage _observer
	[self _manageObserver];
	
	return self;
}

- (void)_manageObserver
{
	// Get me
	__weak typeof(self) me = self;
	
	#pragma mark └ [self viewWillAppear:]
	[self respondsToSelector:@selector(viewWillAppear:) withKey:nil usingBlock:^(id receiver, BOOL animated) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(viewWillAppear:), animated);
		}
		
		// Start observing
		if (!_observer) {
			_observer = [self.view addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
				// Get new color and its components
				UIColor *color;
				CGFloat r, g, b;
				color = change[NSKeyValueChangeNewKey];
				[color getRed:&r green:&g blue:&b alpha:nil];
				
				// Update label
				me.label.text = [NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", r, g, b];
			}];
		}
	}];
	
	#pragma mark └ [self viewWillDisappear:]
	[self respondsToSelector:@selector(viewWillDisappear:) withKey:nil usingBlock:^(id receiver, BOOL animated) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(viewWillDisappear:), animated);
		}
		
		// Stop observing
		_observer = nil;
	}];
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (IBAction)changeBackgroundColorAction:(id)sender
{
	// Get me
	__weak typeof(self) me = self;
	
	// Show alertView
	UIAlertView *alertView;
	NSString *title;
	NSString *message;
	title = @"Change Background Color?";
	message = @"This alert view's delegate method is implemented using REReponder feature. And if you tap \"OK\" button, label will be updated using REObserver feature.";
	alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alertView respondsToSelector:@selector(alertView:didDismissWithButtonIndex:) withKey:nil usingBlock:^(id receiver, UIAlertView *alertView, NSInteger buttonIndex) {
		// Cancel
		if (buttonIndex == 0) {
			return;
		}
		
		// Change backgroundColor
		float (^random)() = ^{
			return (arc4random() % 11) / 10.0f;
		};
		me.view.backgroundColor = [UIColor colorWithRed:random() green:random() blue:random() alpha:1.0f];
	}];
	alertView.delegate = alertView;
	[alertView show];
}

@end
