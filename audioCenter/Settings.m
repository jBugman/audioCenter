//
//  Settings.m
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "Settings.h"

#define DEBUG_USERNAME @"jBugman"
#define DEBUG_PASSWORD @"lastfm"

@implementation Settings

static Settings *singleton = nil;

- (NSString*)lastFmUsername {
	NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:LASTFM_USERNAME_KEY];
	if(!value) {
		value = DEBUG_USERNAME;
		self.lastFmUsername = value;
	}
	return value;
}

- (void)setLastFmUsername:(NSString *)lastFmUsername {
	[[NSUserDefaults standardUserDefaults] setValue:lastFmUsername forKey:LASTFM_USERNAME_KEY];
}


- (NSString*)lastFmPassword {
	NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:LASTFM_PASSWORD_KEY];
	if(!value) {
		value = DEBUG_PASSWORD;
		self.lastFmPassword = value;
	}
	return value;
}

- (void)setLastFmPassword:(NSString *)lastFmPassword {
	[[NSUserDefaults standardUserDefaults] setValue:lastFmPassword forKey:LASTFM_PASSWORD_KEY];
}


+ (Settings *)sharedInstance {
	if(!singleton) {
		singleton = [[Settings alloc] init];
	}
	return singleton;
}

@end
