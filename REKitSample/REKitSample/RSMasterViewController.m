/*
 RSMasterViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "RSMasterViewController.h"


@implementation RSMasterViewController

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
	
	// Create _items
	_items = [[NSMutableArray alloc] init];
	
	// Set title
	self.title = @"Master";
	
	// Add clearButtonItem
	UIBarButtonItem *clearButtonItem;
	clearButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(clearAction:)] autorelease];
	self.navigationItem.leftBarButtonItem = clearButtonItem;
	
	// Add addButonItem to navigationItem
	UIBarButtonItem *addButonItem;
	addButonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)] autorelease];
	self.navigationItem.rightBarButtonItem = addButonItem;
	
	return self;
}

- (void)dealloc
{
	// Release
	[_items release], _items = nil;
	[_observers release], _observers = nil;
	
	// super
	[super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- View --
//--------------------------------------------------------------//

- (void)viewWillAppear:(BOOL)animated
{
	// super
	[super viewWillAppear:animated];
	
	// Start observing
	if (!_observers) {
		// Create _observers
		_observers = [[NSMutableSet alloc] init];
		
		// Add observer to _observers
		id observer;
		observer = [self addObserverForKeyPath:@"items" options:NSKeyValueObservingOptionInitial usingBlock:^(NSDictionary *change) {
			// Update title of masterViewController to check behavior
			self.title = [NSString stringWithFormat:@"%d items", [_items count]];
		}];
		if (observer) {
			[_observers addObject:observer];
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	// super
	[super viewDidDisappear:animated];
	
	// Stop observing
	[_observers makeObjectsPerformSelector:@selector(stopObserving)];
	[_observers release], _observers = nil;
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (void)clearAction:(id)sender
{
	// Make alertView
	UIAlertView *alertView;
	NSString *title = nil;
	NSString *message = nil;
	title = @"CAUTION";
	message = @"You can't undo the operation. Do you want to clear all items?";
	alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Clear", nil];
	
	// Make alertView delegate of the alertView
	[alertView respondsToSelector:@selector(alertView:didDismissWithButtonIndex:) usingBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
		switch (buttonIndex) {
		case 0: {
			// Cancelled
			break;
		}
		case 1: {
			// Make indexPaths to delete
			NSMutableArray *indexPaths;
			indexPaths = [NSMutableArray array];
			for (NSInteger i = 0; i < [_items count]; i++) {
				[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
			}
			
			// Clear items
			[self willChangeValueForKey:@"items"];
			[_items removeAllObjects];
			[self didChangeValueForKey:@"items"];
			[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
		}
		}
	} blockName:nil];
	alertView.delegate = alertView;
	
	// Show alertView
	[alertView show];
	[alertView release];
}

- (void)addAction:(id)sender
{
	static NSUInteger _itemNo = 1;
	
	// Add item to _items
	NSString *item;
	item = [NSString stringWithFormat:@"Item No.%u", _itemNo++];
	[self willChangeValueForKey:@"items"];
	[_items addObject:item];
	[self didChangeValueForKey:@"items"];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([_items count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

//--------------------------------------------------------------//
#pragma mark -- TableView --
//--------------------------------------------------------------//

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _items.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSUInteger _cellNo = 1;
	
	// Assure cell
    UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
		// Make cell
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
		
		// Add button		// Don't use target >>>
		UIButton *button;
		SEL buttonAction;
		id target;
		NSUInteger cellNo;
		cellNo = _cellNo;
		button = [UIButton buttonWithType:UIButtonTypeInfoDark];
		buttonAction = @selector(buttonAction);
		target = [[[NSObject alloc] init] autorelease];
		[target respondsToSelector:buttonAction usingBlock:^{
			// Show cellNo
			UIAlertView *alertView;
			NSString *title;
			title = [NSString stringWithFormat:@"Cell No.%u", cellNo];
			alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			[alertView show];
			[alertView release];
		} blockName:nil];
		[button addTarget:target action:buttonAction forControlEvents:UIControlEventTouchUpInside];
		[button associateValue:target forKey:@"target" policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
		cell.accessoryView = button;
		
		// Increase _cellNo
		_cellNo++;
    }
	
	// Update cell
	cell.textLabel.text = [[_items objectAtIndex:indexPath.row] description];
	
    return cell;
}

@end
