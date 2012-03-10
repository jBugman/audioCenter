//
//  SettingsViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "SettingsViewController.h"
#import "LastFmAPI.h"

@interface SettingsViewController()

@property (weak, nonatomic) IBOutlet UILabel *versionString;
@property (weak, nonatomic) IBOutlet UILabel *buildString;

@property (weak, nonatomic) IBOutlet UITextField *lastFmUsername;
@property (weak, nonatomic) IBOutlet UITextField *lastFmPassword;
@property (weak, nonatomic) IBOutlet UILabel *authorizationStatus;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *authorizationSpinner;
@end

@implementation SettingsViewController
@synthesize versionString;
@synthesize buildString;
@synthesize lastFmUsername;
@synthesize lastFmPassword;
@synthesize authorizationStatus;
@synthesize authorizationSpinner;

- (void)auth {
	if([Settings sharedInstance].lastFmUsername && [Settings sharedInstance].lastFmPassword) {
		[self.authorizationSpinner startAnimating];
		self.authorizationStatus.text = nil;
		LastFmAPI *lastFm = [[LastFmAPI alloc] init];
		[lastFm getSessionWithUsername:[Settings sharedInstance].lastFmUsername password:[Settings sharedInstance].lastFmPassword
					 completionHandler:^(NSDictionary *session, NSError *error) {
						 if(!error) {
							 self.authorizationStatus.text = @"Yes";
						 } else {
							 if(error.code == -1009) {
								 self.authorizationStatus.text = @"Offline";
							 } else {
								 self.authorizationStatus.text = @"Invalid login info";
							 }
						 }
						 [self.authorizationSpinner stopAnimating];
					 }];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.lastFmUsername.text = [Settings sharedInstance].lastFmUsername;
	self.lastFmPassword.text = [Settings sharedInstance].lastFmPassword;
	[self auth];
	
	self.versionString.text = [@"Version " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	self.buildString.text = [@"Build " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (IBAction)fieldEdited:(UITextField *)sender {
	[sender resignFirstResponder];
	if(sender == self.lastFmUsername && !self.lastFmPassword.text.length) {
		[self.lastFmPassword becomeFirstResponder];
	}
	[Settings sharedInstance].lastFmUsername = self.lastFmUsername.text;
	[Settings sharedInstance].lastFmPassword = self.lastFmPassword.text;
	[self auth];
}

- (void)viewDidUnload
{
	[self setVersionString:nil];
	[self setBuildString:nil];
	[self setLastFmUsername:nil];
	[self setLastFmPassword:nil];
	[self setAuthorizationStatus:nil];
	[self setAuthorizationSpinner:nil];
    [super viewDidUnload];
}

@end