//
//  RadiostationMetadata.h
//  audioCenter
//
//  Created by Sergey Parshukov on 09.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadiostationMetadata : NSObject

+ (void)getStationTitleWithUrl:(NSURL*)url completionHandler:(void (^)(NSString *title))handler;

@end
