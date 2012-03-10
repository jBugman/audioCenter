//
//  Settings.h
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LASTFM_USERNAME_KEY @"lastFmUsername"
#define LASTFM_PASSWORD_KEY @"lastFmPassword"

@interface Settings : NSObject

@property (strong, nonatomic) NSString *lastFmUsername;
@property (strong, nonatomic) NSString *lastFmPassword;

+ (Settings*)sharedInstance;

@end
