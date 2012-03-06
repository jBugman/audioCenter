//
//  RadiostationListViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 27.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "RadiostationListViewController.h"


@interface RadiostationListViewController()

- (IBAction)tapRadiostation:(UIButton*)sender;

- (void)selectRadiostation:(NSString*)url;

@end

@implementation RadiostationListViewController

@synthesize delegate = _delegate;

- (void)selectRadiostation:(NSString*)url {
	[self.delegate setRadiostation:url];
	if([self.delegate respondsToSelector:@selector(play)]) {
		[self.delegate play];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self selectRadiostation:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
}

- (IBAction)tapRadiostation:(UIButton*)sender {
	[self selectRadiostation:sender.titleLabel.text];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
