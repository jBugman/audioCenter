//
//  RadiostationListViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 27.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "RadiostationListViewController.h"


@interface RadiostationListViewController()

- (IBAction)selectRadiostation:(UIButton*)sender;

@end


@implementation RadiostationListViewController

@synthesize delegate = _delegate;

- (IBAction)selectRadiostation:(UIButton*)sender {
	[self.delegate setRadiostation:sender.titleLabel.text];
	if([self.delegate respondsToSelector:@selector(play)]) {
		[self.delegate play];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
