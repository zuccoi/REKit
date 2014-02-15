/*
 iREViewController.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "iREViewController.h"


@interface iREViewController ()
@property (strong, nonatomic) id observer;
@end

#pragma mark -


@implementation iREViewController

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

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (IBAction)changeBackgroundColorAction:(id)sender
{
	// Get me
	__weak typeof(self) self_ = self;
	
	// Show alertView
	UIAlertView *alertView;
	NSString *title;
	NSString *message;
	title = @"Change Background Color?";
	message = @"This alert view's delegate method is implemented using REReponder feature. And if you tap \"OK\" button, label will be updated using REObserver feature.";
	alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alertView setBlockForInstanceMethod:@selector(alertView:didDismissWithButtonIndex:) key:nil block:^(id receiver, UIAlertView *alertView, NSInteger buttonIndex) {
		// Cancel
		if (buttonIndex == 0) {
			return;
		}
		
		// Change backgroundColor
		float (^random)() = ^{
			return (arc4random() % 11) / 10.0f;
		};
		self_.view.backgroundColor = [UIColor colorWithRed:random() green:random() blue:random() alpha:1.0f];
	}];
	alertView.delegate = alertView;
	[alertView show];
}

//--------------------------------------------------------------//
#pragma mark -- Observer --
//--------------------------------------------------------------//

- (void)viewWillAppear:(BOOL)animated
{
	// super
	[super viewWillAppear:animated];
	
	NSLog(@"original %s", __PRETTY_FUNCTION__);
}

- (void)_manageObserver
{
	// Prepare for REKit
	NSString *const key = RE_LINE;
	__weak typeof(self) self_ = self;
	
	#pragma mark └ [self viewWillAppear:]
	RESetBlock(self, @selector(viewWillAppear:), NO, nil, ^(RE_TYPE(self), BOOL animated) {
	// ?????
	NSLog(@"%s", __PRETTY_FUNCTION__);
		RESupermethod(nil, self, animated);
	});
	[self setBlockForInstanceMethod:@selector(viewWillAppear:) key:key block:^(id receiver, BOOL animated) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfInstanceMethod:@selector(viewWillAppear:) key:key];
		if (supermethod) {
			(REIMP(void)supermethod)(receiver, @selector(viewWillAppear:), animated);
		}
		
		// Start observing
		if (!self_.observer) {
			self_.observer = [self_.view addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
				// Get new color and its components
				UIColor *color;
				CGFloat r, g, b;
				color = change[NSKeyValueChangeNewKey];
				[color getRed:&r green:&g blue:&b alpha:nil];
				
				// Update label
				self_.label.text = [NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", r, g, b];
			}];
		}
	}];
	
	#pragma mark └ [self viewWillDisappear:]
	[self setBlockForInstanceMethod:@selector(viewWillDisappear:) key:nil block:^(id receiver, BOOL animated) {
		// Stop observing
		[self_.observer stopObserving];
		self_.observer = nil;
		
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfInstanceMethod:@selector(viewWillDisappear:) key:RE_FUNC];
		if (supermethod) {
			(REIMP(void)supermethod)(receiver, @selector(viewWillDisappear:), animated);
		}
	}];
}

@end
