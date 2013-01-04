/*
 iREViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import <QuartzCore/QuartzCore.h>
#import "REKit.h"
#import "iREViewController.h"


@implementation iREViewController
{
	NSMutableSet *_observers;
	CADisplayLink *_displayLink;
	id _keyboardWillShowNotificationObserver;
	CGRect _keyboardFrame;
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
	
	// Create _observers
	_observers = [NSMutableSet set];
	
	// Manage _keyboardWillShowNotificationObserver
	[self _manageKeyboardWillShowNotificationObserver];
	
	return self;
}

//--------------------------------------------------------------//
#pragma mark -- KeyboardWillShowNotificationObserver --
//--------------------------------------------------------------//

- (void)_manageKeyboardWillShowNotificationObserver
{
	SEL sel = NULL;
	NSString *key = @(__PRETTY_FUNCTION__);
	
	#pragma mark └ [self viewWillAppear:]
	[self respondsToSelector:(sel = @selector(viewWillAppear:)) withKey:key usingBlock:^(id receiver, BOOL animated) {
		// super
		REVoidIMP supermethod; // REVoidIMP is defined like this: typedef void (*REVoidIMP)(id, SEL, ...);
		if ((supermethod = (REVoidIMP)[receiver supermethodOfBlockForSelector:sel forKey:key])) {
			supermethod(receiver, sel, animated);
		}
		
		// Start observing
		if (_keyboardWillShowNotificationObserver) {
			return;
		}
		_keyboardWillShowNotificationObserver = [[NSNotificationCenter defaultCenter]
			addObserverForName:UIKeyboardWillShowNotification
			object:nil
			queue:[NSOperationQueue mainQueue]
			usingBlock:^(NSNotification *note) {
				// Do something…
			}
		];
	}];
	
	#pragma mark └ [self viewDidDisappear:]
	[self respondsToSelector:(sel = @selector(viewDidDisappear:)) withKey:key usingBlock:^(id receiver, BOOL animated) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfBlockForSelector:sel forKey:key])) {
			supermethod(receiver, sel, animated);
		}
		
		// Stop observing
		[[NSNotificationCenter defaultCenter] removeObserver:_keyboardWillShowNotificationObserver];
		_keyboardWillShowNotificationObserver = nil;
	}];
}

//--------------------------------------------------------------//
#pragma mark -- View --
//--------------------------------------------------------------//

- (void)viewWillAppear:(BOOL)animated
{
	// Get me
	__weak typeof(self) me = self;
	
	// super
	[super viewWillAppear:animated];
	
	// Start observing
	if (![_observers count]) {
		id observer;
		observer = [self.view addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
			// Get new color and its components
			UIColor *color;
			CGFloat r, g, b;
			color = change[NSKeyValueChangeNewKey];
			[color getRed:&r green:&g blue:&b alpha:nil];
			
			// Update label
			me.label.text = [NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", r, g, b];
		}];
		[_observers addObject:observer];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	// super
	[super viewWillDisappear:animated];
	
	// Stop observing
	[_observers removeAllObjects];
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
