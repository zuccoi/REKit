/*
 iREViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "iREViewController.h"


@implementation iREViewController
{
	NSMutableSet *_observers;
}

//--------------------------------------------------------------//
#pragma mark -- Object --
//--------------------------------------------------------------//

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	// super
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) {
		return nil;
	}
	
	// Create _observers
	_observers = [NSMutableSet set];
    
	return self;
}

//--------------------------------------------------------------//
#pragma mark -- View --
//--------------------------------------------------------------//

- (void)viewWillAppear:(BOOL)animated
{
	// super
	[super viewWillAppear:animated];
	
	// Start observing
	id observer;
	observer = [self.view addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
		// Get new color and its components
		UIColor *color;
		CGFloat r, g, b;
		color = change[NSKeyValueChangeNewKey];
		[color getRed:&r green:&g blue:&b alpha:nil];
		
		// Update label
		self.label.text = [NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", r, g, b];
	}];
	[_observers addObject:observer];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// super
	[super viewWillDisappear:animated];
	
	// Stop observing
	[_observers makeObjectsPerformSelector:@selector(stopObserving)];
	[_observers removeAllObjects];
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (IBAction)changeBackgroundColorAction:(id)sender
{
	// Show alertView
	UIAlertView *alertView;
	NSString *title;
	NSString *message;
	title = @"Change Background Color?";
	message = @"This alert view's delegate method is implemented using REReponder feature. And if you tap \"OK\" button, label will be updated using REObserver feature.";
	alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alertView respondsToSelector:@selector(alertView:didDismissWithButtonIndex:) withBlockName:nil usingBlock:^(id receiver, UIAlertView *alertView, NSInteger buttonIndex) {
		// Cancel
		if (buttonIndex == 0) {
			return;
		}
		
		// Change backgroundColor
		self.view.backgroundColor = [UIColor colorWithRed:(float)(arc4random() % 11) / 10.0f green:(float)(arc4random() % 11) / 10.0f blue:(float)(arc4random() % 11) / 10.0f alpha:1.0f];
	}];
	alertView.delegate = alertView;
	[alertView show];
}

@end
