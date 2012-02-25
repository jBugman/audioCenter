//
//  LastFmAPI.h
//  audioCenter
//
//  Created by Sergey Parshukov on 25.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define API_KEY     @"be88788cee404ccecdcd647beea93a01"
#define API_SECRET  @"f2fc974d4d738461b9832e4d1a62ac46"

@interface LastFmAPI : NSObject

- (void)getSessionWithUsername:(NSString*)username password:(NSString*)password
             completionHandler:(void (^)(NSDictionary *session, NSError *error))handler;

- (void)getInfoForTrack:(NSString*)track artist:(NSString*)artist
           completionHandler:(void (^)(NSDictionary *trackInfo, NSError *error))handler;

- (void)getInfoForArtist:(NSString*)artist completionHandler:(void (^)(NSDictionary *artistInfo, NSError *error))handler;

- (void)updateNowPlayingTrack:(NSString*)track artist:(NSString*)artist sessionKey:(NSString*)sessionKey
           completionHandler:(void (^)(NSError *error))handler;

- (void)scrobbleTrack:(NSString*)track artist:(NSString*)artist timestamp:(NSTimeInterval)timestamp sessionKey:(NSString*)sessionKey
            completionHandler:(void (^)(NSError *error))handler;

@end
