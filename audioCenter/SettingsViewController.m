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
@property (weak, nonatomic) IBOutlet UILabel *cacheSize;

@property (weak, nonatomic) IBOutlet UITextField *lastFmUsername;
@property (weak, nonatomic) IBOutlet UITextField *lastFmPassword;
@property (weak, nonatomic) IBOutlet UISwitch *autocorrectionSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *scrobblingSwitch;
@property (weak, nonatomic) IBOutlet UILabel *authorizationStatus;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *authorizationSpinner;

- (void)auth;
- (void)processCache;

@end

@implementation SettingsViewController
@synthesize versionString;
@synthesize buildString;
@synthesize cacheSize;
@synthesize lastFmUsername;
@synthesize lastFmPassword;
@synthesize autocorrectionSwitch;
@synthesize scrobblingSwitch;
@synthesize authorizationStatus;
@synthesize authorizationSpinner;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.lastFmUsername.text = [Settings sharedInstance].lastFmUsername;
	self.lastFmPassword.text = [Settings sharedInstance].lastFmPassword;
	self.autocorrectionSwitch.on = [Settings sharedInstance].lastFmAutocorrect;
	self.scrobblingSwitch.on = [Settings sharedInstance].lastFmScrobbling;
	[self processCache];
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

- (IBAction)autocorrectionSwitched:(UISwitch *)sender {
	[Settings sharedInstance].lastFmAutocorrect = sender.on;
}

- (IBAction)scrobblingSwitched:(UISwitch *)sender {
	[Settings sharedInstance].lastFmScrobbling = sender.on;
}

- (void)auth {
	if([Settings sharedInstance].lastFmUsername.length && [Settings sharedInstance].lastFmPassword.length) {
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
	} else {
		self.authorizationStatus.text = @"No";
	}
}

- (void)processCache {
	dispatch_queue_t queue = dispatch_queue_create("settings", NULL);
	dispatch_async(queue, ^{
		NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
		NSArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachesPath error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]];
		long totalSize = 0;
		for(NSString* fileName in files) {
			NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[cachesPath stringByAppendingPathComponent:fileName] error:nil];
			totalSize += [((NSNumber*)[attributes valueForKey:NSFileSize]) longValue];
		}
		totalSize /= 1024;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheSize.text = (totalSize) ? [NSString stringWithFormat:@"%@K", [NSNumber numberWithLong:totalSize]] : @"0";
		});
	});
	dispatch_release(queue);
}

- (void)viewDidUnload
{
	[self setVersionString:nil];
	[self setBuildString:nil];
	[self setLastFmUsername:nil];
	[self setLastFmPassword:nil];
	[self setAuthorizationStatus:nil];
	[self setAuthorizationSpinner:nil];
	[self setAutocorrectionSwitch:nil];
	[self setScrobblingSwitch:nil];
	[self setCacheSize:nil];
    [super viewDidUnload];
}

@end
