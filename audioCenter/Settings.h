//
//  Settings.h
//  audioCenter
//
//  Created by Sergey Parshukov on 10.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Settings : NSObject

@property (strong, nonatomic) NSString *lastFmUsername;
@property (strong, nonatomic) NSString *lastFmPassword;
@property (assign, nonatomic) BOOL lastFmAutocorrect;
@property (assign, nonatomic) BOOL lastFmScrobbling;

+ (Settings*)sharedInstance;

@end
