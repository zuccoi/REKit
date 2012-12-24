/*
 iRETableViewController.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "iRETableViewController.h"


@implementation iRETableViewController

//--------------------------------------------------------------//
#pragma mark -- TableViewDataSource & Delegate --
//--------------------------------------------------------------//

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	// Configure the cell...
	
	return cell;
}

@end