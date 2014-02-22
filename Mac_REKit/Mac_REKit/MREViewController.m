/*
 MREViewController.m
 
 Copyright ©2014 Kazki Miura. All rights reserved.
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
	RESetBlock(self, @selector(setView:), NO, nil, ^(id receiver, NSView *view) {
		// Stop observing
		[self_.observer stopObserving];
		self_.observer = nil;
		
		// supermethod
		RESupermethod(nil, self_, view);
		
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
	});
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
	// Change backgroundColor
	CGColorRef color;
	float (^random)() = ^{
		return (arc4random() % 11) / 10.0f;
	};
	color = CGColorCreateGenericRGB(random(), random(), random(), 1.0f);
	self.view.layer.backgroundColor = color;
	CGColorRelease(color);
}

@end
