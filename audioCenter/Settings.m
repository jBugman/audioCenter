//
//  Settings.m
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "Settings.h"

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


+ (Settings *)sharedInstance {
	if(!singleton) {
		singleton = [[Settings alloc] init];
	}
	return singleton;
}

@end
