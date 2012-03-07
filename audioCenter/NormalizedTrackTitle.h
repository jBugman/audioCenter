//
//  NormalizedTrackTitle.h
//  audioCenter
//
//  Created by Sergey Parshukov on 25.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NormalizedTrackTitle : NSObject

@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSString *trackName;

@property (readonly) BOOL isFilled;

- (BOOL)isEqualToTitle:(NormalizedTrackTitle*)otherTitle;

+ (NormalizedTrackTitle*)normalizedTrackTitleWithString:(NSString*)metadataTitle;

@end