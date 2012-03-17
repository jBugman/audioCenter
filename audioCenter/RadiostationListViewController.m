//
//  RadiostationListViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 27.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "RadiostationListViewController.h"


@interface RadiostationListViewController()

@property (strong, readonly) NSArray *stationsList;

- (void)selectRadiostation:(NSString*)url;

@end


@implementation RadiostationListViewController

@synthesize delegate = _delegate;
@synthesize stationsList = _stationsList;

- (NSArray *)stationsList {
	if(!_stationsList) {
		_stationsList = [[NSArray alloc] initWithObjects:
						 @"http://ultradarkradio.com:3026/",
						 @"http://87.118.78.20:2700/",
						 @"http://205.188.215.231:8000/",
						 @"http://93.81.248.234:8000/",
						 @"http://mp3.nashe.ru/nashe-192.m3u", nil];
	}
	return _stationsList;
}

- (void)selectRadiostation:(NSString*)urlString {
	NSURL *url = [NSURL URLWithString:urlString];
	[self.delegate setRadiostation:url];
	if([self.delegate respondsToSelector:@selector(play)]) {
		[self.delegate play];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	cell = [self.tableView dequeueReusableCellWithIdentifier:@"plainCell"];
	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"plainCell"];
	}
	cell.textLabel.text = [self.stationsList objectAtIndex:indexPath.row];
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0) {
		return @"Custom stations";
	} else {
		return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		return [self.stationsList count];
	} else {
		return 0;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self selectRadiostation:[self.stationsList objectAtIndex:indexPath.row]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
