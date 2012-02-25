//
//  LastFmAPI.m
//  audioCenter
//
//  Created by Sergey Parshukov on 25.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "LastFmAPI.h"
#import "NSString+md5.h"

#define API_ROOT        @"http://ws.audioscrobbler.com/2.0/"
#define HTTPMethodGET   @"GET"
#define HTTPMethodPOST  @"POST"

@interface LastFmAPI()

- (NSString*)methodSignatureWithParameters:(NSDictionary*)parameters;
- (NSString*)getGETRequestURLWithParameters:(NSDictionary*)parameters;
- (NSData*)getPOSTBodyWithParameters:(NSDictionary*)parameters;
- (NSError*)errorWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)dictionaryWithJsonString:(NSString*)json;

- (void)callMethod:(NSString*)method 
    withParameters:(NSDictionary*)params 
       requireAuth:(BOOL)auth 
        HTTPMethod:(NSString*)httpMethod 
   completionBlock:(void (^)(NSDictionary *response, NSError *error))handler;

@end


@implementation LastFmAPI

- (void)getInfoForTrack:(NSString*)track artist:(NSString*)artist
           completionHandler:(void (^)(NSDictionary *trackInfo, NSError *error))handler {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                track, @"track",
                                artist, @"artist", nil];
    [self callMethod:@"track.getInfo"
      withParameters:parameters 
         requireAuth:NO
          HTTPMethod:HTTPMethodGET 
     completionBlock:^(NSDictionary *response, NSError *error) {
         if(!error) {
             handler([response valueForKey:@"track"], nil);
         }
         else if(handler)
             handler(nil, error);
     }];
}

- (void)getInfoForArtist:(NSString*)artist completionHandler:(void (^)(NSDictionary *artistInfo, NSError *error))handler {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                artist, @"artist", nil];
    [self callMethod:@"artist.getInfo"
      withParameters:parameters 
         requireAuth:NO
          HTTPMethod:HTTPMethodGET 
     completionBlock:^(NSDictionary *response, NSError *error) {
         if(!error) {
             handler([response valueForKey:@"artist"], nil);
         }
         else if(handler)
             handler(nil, error);
     }];
}

- (void)getSessionWithUsername:(NSString*)username password:(NSString*)password
             completionHandler:(void (^)(NSDictionary *session, NSError *error))handler {
    
    NSString *authToken = [[NSString stringWithFormat:@"%@%@", [username lowercaseString], [password md5]] md5];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                username, @"username",
                                authToken, @"authToken", nil];
    
    [self callMethod:@"auth.getMobileSession"
      withParameters:parameters 
         requireAuth:YES 
          HTTPMethod:HTTPMethodGET 
     completionBlock:^(NSDictionary *response, NSError *error) {
        if(!error) {
            handler([response valueForKey:@"session"], nil);
        }
        else if(handler)
            handler(nil, error);
    }];
}

- (void)updateNowPlayingTrack:(NSString*)track artist:(NSString*)artist sessionKey:(NSString*)sessionKey
            completionHandler:(void (^)(NSError *error))handler {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                track, @"track",
                                artist, @"artist",
                                sessionKey, @"sk", nil];
    [self callMethod:@"track.updateNowPlaying"
      withParameters:parameters 
         requireAuth:YES
          HTTPMethod:HTTPMethodPOST 
     completionBlock:^(NSDictionary *response, NSError *error) {
         if(error && handler)
             handler(error);
     }];
}

- (void)scrobbleTrack:(NSString*)track artist:(NSString*)artist timestamp:(NSTimeInterval)timestamp sessionKey:(NSString*)sessionKey
    completionHandler:(void (^)(NSError *error))handler {
    
    NSString *ts = [NSString stringWithFormat:@"%d", [[NSNumber numberWithDouble:timestamp] longValue]];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                track, @"track",
                                artist, @"artist",
                                ts, @"timestamp",
                                sessionKey, @"sk", nil];
    [self callMethod:@"track.scrobble"
      withParameters:parameters 
         requireAuth:YES
          HTTPMethod:HTTPMethodPOST 
     completionBlock:^(NSDictionary *response, NSError *error) {
         NSLog(@"scrobble: %@", response);
         if(error && handler)
             handler(error);
     }];
}

- (void)callMethod:(NSString*)method 
    withParameters:(NSDictionary*)params 
       requireAuth:(BOOL)requireAuth 
        HTTPMethod:(NSString*)httpMethod 
   completionBlock:(void (^)(NSDictionary *response, NSError *error))handler {
    
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionaryWithDictionary:params];
    [requestParameters setObject:method forKey:@"method"];
	[requestParameters setObject:API_KEY forKey:@"api_key"];
//	[requestParameters addEntriesFromDictionary:params];
	if(httpMethod){
//		if(self.sk){
//            [requestParameters setObject:self.sk forKey:@"sk"];
//        }
		[requestParameters setObject:[self methodSignatureWithParameters:requestParameters] forKey:@"api_sig"];
	}
    [requestParameters setObject:@"json" forKey:@"format"];
    
    BOOL usingGET = [httpMethod isEqualToString: HTTPMethodGET];
    NSURL *requestURL = usingGET ? 
        [NSURL URLWithString:[self getGETRequestURLWithParameters:requestParameters]] :
        [NSURL URLWithString:API_ROOT];
    
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
	request.HTTPMethod = httpMethod;
    if(!usingGET) {
        NSData *postData = [self getPOSTBodyWithParameters:requestParameters];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
    }
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    (self.dispatchQueue != NULL) ? self.dispatchQueue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
        NSDictionary *response = nil;
        if(data) {
            response = [self dictionaryWithJsonString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            if (!error) {
                error = [self errorWithDictionary:response];
            }
        }
		dispatch_async(dispatch_get_main_queue(), ^{
			if(handler)
                handler(response, error);
		});
	});
}

- (NSString*)methodSignatureWithParameters:(NSDictionary*)parameters {
    NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSMutableString *parameterString = [NSMutableString string];
	for(NSString *key in keys) { // Append each of the key-value pairs in alphabetical order
		[parameterString appendString:key];
		[parameterString appendString:[[parameters valueForKey:key] description]];
	}
	[parameterString appendString:API_SECRET];
	return [parameterString md5];
}

- (NSString*)getGETRequestURLWithParameters:(NSDictionary*)parameters {
	NSMutableString *requestURL = [NSMutableString stringWithFormat:@"%@?", API_ROOT];
	NSArray *keys = [parameters allKeys];
	for(NSString *key in keys) {
		[requestURL appendFormat:@"%@=%@&", key, [[[parameters valueForKey:key] description]
                                                  stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	}
    [requestURL deleteCharactersInRange:NSMakeRange([requestURL length] - 1, 1)];
	return requestURL;
}

- (NSData*)getPOSTBodyWithParameters:(NSDictionary*)parameters {
    NSMutableString *requestURL = [NSMutableString string];
	NSArray *keys = [parameters allKeys];
	for(NSString *key in keys) {
		[requestURL appendFormat:@"%@=%@&", key, [[[parameters valueForKey:key] description] 
                                                  stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	}
    [requestURL deleteCharactersInRange:NSMakeRange([requestURL length] - 1, 1)];
    return [requestURL dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSError*)errorWithDictionary:(NSDictionary*)dictionary {
	NSNumber *errorCode = [dictionary valueForKey:@"error"];
    if(!errorCode) {
        return nil;
    }
	NSString *message = [dictionary valueForKey:@"message"];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil];
	return [NSError errorWithDomain:@"LastFMErrorDomain" code:[errorCode integerValue] userInfo:userInfo];
}

- (NSDictionary*)dictionaryWithJsonString:(NSString*)json {
    id data = [NSJSONSerialization JSONObjectWithData: [json dataUsingEncoding: NSUTF8StringEncoding]
                                              options: NSJSONReadingMutableContainers
                                                error: NULL];
    return data;
}

@end
