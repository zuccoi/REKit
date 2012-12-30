/*
 MREViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "MREViewController.h"


@implementation MREViewController
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

- (void)setView:(NSView *)view
{
	// Stop observing
	[_observers removeAllObjects];
	
	// super
	[super setView:view];
	
	// Configure view
	CGColorRef color;
	[self.view setWantsLayer:YES];
	color = CGColorCreateGenericRGB(0.8f, 0.8f, 0.8f, 1.0f);
	self.view.layer.backgroundColor = color;
	CGColorRelease(color);
	
	// Start observing
	id observer;
	__weak NSTextField *label;
	label = self.label;
	observer = [self.view.layer addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
		// Get new color and its components
		CGColorRef color;
		const CGFloat *components;
		color = (__bridge CGColorRef)(change[NSKeyValueChangeNewKey]);
		components = CGColorGetComponents(color);
		
		// Update label
		[label setStringValue:[NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", components[0], components[1], components[2]]];
	}];
	[_observers addObject:observer];
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (IBAction)changeBackgroundColorAction:(id)sender
{
	__weak CALayer *layer;
	layer = self.view.layer;
	
	// Show alert
	NSAlert *alert;
	SEL selector;
	selector = @selector(alertViewDidEnd:returnCode:context:);
	alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setMessageText:@"Change Background Color?"];
	[alert setInformativeText:@"This alert's delegate method is implemented using REReponder feature. And if you tap \"OK\" button, label will be updated using REObserver feature."];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert respondsToSelector:selector withKey:nil usingBlock:^(id receiver, NSAlert *alert, NSInteger returnCode, void *context) {
		// Cancel
		if (returnCode == NSAlertSecondButtonReturn) {
			return;
		}
		
		// Change backgroundColor
		CGColorRef color;
		float (^random)() = ^{
			return (arc4random() % 11) / 10.0f;
		};
		color = CGColorCreateGenericRGB(random(), random(), random(), 1.0f);
		layer.backgroundColor = color;
		CGColorRelease(color);
	}];
	[alert setDelegate:(id)alert];
	[alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:@selector(alertViewDidEnd:returnCode:context:) contextInfo:nil];
}

@end
