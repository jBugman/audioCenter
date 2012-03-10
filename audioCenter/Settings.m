//
//  Settings.m
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "Settings.h"

#define LASTFM_USERNAME_KEY @"lastFmUsername"
#define LASTFM_PASSWORD_KEY @"lastFmPassword"
#define LASTFM_AUTOCORRECT_KEY @"lastFmAutocorrect"

@implementation Settings

static Settings *singleton = nil;

- (NSString*)lastFmUsername {
	NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:LASTFM_USERNAME_KEY];
	return value;
}

- (void)setLastFmUsername:(NSString *)lastFmUsername {
	[[NSUserDefaults standardUserDefaults] setValue:lastFmUsername forKey:LASTFM_USERNAME_KEY];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSString*)lastFmPassword {
	NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:LASTFM_PASSWORD_KEY];
	return value;
}

- (void)setLastFmPassword:(NSString *)lastFmPassword {
	[[NSUserDefaults standardUserDefaults] setValue:lastFmPassword forKey:LASTFM_PASSWORD_KEY];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)lastFmIsAutocorrecting {
	return [[NSUserDefaults standardUserDefaults] boolForKey:LASTFM_AUTOCORRECT_KEY];
}

- (void)setLastFmIsAutocorrecting:(BOOL)lastFmIsAutocorrecting {
	[[NSUserDefaults standardUserDefaults] setBool:lastFmIsAutocorrecting forKey:LASTFM_AUTOCORRECT_KEY];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (Settings *)sharedInstance {
	if(!singleton) {
		singleton = [[Settings alloc] init];
		NSString* path = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
		[[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithContentsOfFile: path]];
	}
	return singleton;
}

@end