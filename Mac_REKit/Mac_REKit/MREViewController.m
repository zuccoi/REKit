/*
 MREViewController.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "MREViewController.h"


@interface MREViewController ()
@property (strong, nonatomic) id observer;
@end

#pragma mark -


@implementation MREViewController

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
	
	// Manage self_.observer
	[self _manageObserver];
	
	return self;
}

- (void)_manageObserver
{
	// Get me
	__block typeof(self) self_ = self;
	
	#pragma mark └ [self setView:]
	[self setBlockForSelector:@selector(setView:) key:nil block:^(id receiver, NSView *view) {
		// Stop observing
		[self_.observer stopObserving];
		self_.observer = nil;
		
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(setView:), view);
		}
		
		// Start observing
		if (!view) {
			return;
		}
		self_.observer = [self_.view.layer addObserverForKeyPath:@"backgroundColor" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) usingBlock:^(NSDictionary *change) {
			// Get new color and its components
			CGColorRef color;
			const CGFloat *components;
			color = (__bridge CGColorRef)(change[NSKeyValueChangeNewKey]);
			components = CGColorGetComponents(color);
			
			// Update label
			[self_.label setStringValue:[NSString stringWithFormat:@"r:%.1f g:%.1f b:%.1f", components[0], components[1], components[2]]];
		}];
	}];
}

//--------------------------------------------------------------//
#pragma mark -- View --
//--------------------------------------------------------------//

- (void)setView:(NSView *)view
{
	// super
	[super setView:view];
	
	// Filter
	if (!view) {
		return;
	}
	
	// Configure view
	CGColorRef color;
	[self.view setWantsLayer:YES];
	color = CGColorCreateGenericRGB(0.8f, 0.8f, 0.8f, 1.0f);
	self.view.layer.backgroundColor = color;
	CGColorRelease(color);
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (IBAction)changeBackgroundColorAction:(id)sender
{
	// Get me
	__block typeof(self) self_ = self;
	
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
	[alert setBlockForSelector:selector key:nil block:^(id receiver, NSAlert *alert, NSInteger returnCode, void *context) {
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
		self_.view.layer.backgroundColor = color;
		CGColorRelease(color);
	}];
	[alert setDelegate:(id)alert];
	[alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:@selector(alertViewDidEnd:returnCode:context:) contextInfo:nil];
}

@end
