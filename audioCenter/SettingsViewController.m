//
//  SettingsViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController()

@property (weak, nonatomic) IBOutlet UILabel *versionString;
@property (weak, nonatomic) IBOutlet UILabel *buildString;

@property (weak, nonatomic) IBOutlet UILabel *lastFmUsername;
@property (weak, nonatomic) IBOutlet UILabel *lastFmPassword;
@end

@implementation SettingsViewController
@synthesize versionString;
@synthesize buildString;
@synthesize lastFmUsername;
@synthesize lastFmPassword;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.lastFmUsername.text = [Settings sharedInstance].lastFmUsername;
	self.lastFmPassword.text = @"******";
								
	self.versionString.text = [@"Version " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	self.buildString.text = [@"Build " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (void)viewDidUnload
{
	[self setVersionString:nil];
	[self setBuildString:nil];
	[self setLastFmUsername:nil];
	[self setLastFmPassword:nil];
    [super viewDidUnload];
}

@end
