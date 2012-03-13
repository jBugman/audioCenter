//
//  NormalizedTrackTitle.m
//  audioCenter
//
//  Created by Sergey Parshukov on 25.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "NormalizedTrackTitle.h"

@implementation NormalizedTrackTitle

@synthesize artist = _artist, trackName = _trackName, isFilled = _isFilled;

- (id)init {
    self = [super init];
    if(self) {
        self.artist = @"Unknown Artist";
        self.trackName = @"Unknown Track";
    }
    return self;
}

- (BOOL)isFilled {
	return self.artist.length && self.trackName.length && (![self.artist isEqualToString:@"Unknown Artist"] && ![self.trackName isEqualToString:@"Unknown Track"]);
}

- (BOOL)isEqualToTitle:(NormalizedTrackTitle*)otherTitle {
    if(otherTitle == nil) {
        return NO;
    } else {
        return ([self.artist isEqualToString: otherTitle.artist] && [self.trackName isEqualToString: otherTitle.trackName]);
    }
}

+ (NormalizedTrackTitle*)normalizedTrackTitleWithString:(NSString*)metadataTitle {
    NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    NSArray *titleParts = [metadataTitle componentsSeparatedByString:@" - "];
    if([titleParts count] < 2) {
        return [[NormalizedTrackTitle alloc] init];
    } else {
        NormalizedTrackTitle *result = [[NormalizedTrackTitle alloc] init];
        result.artist = [[titleParts objectAtIndex:0] stringByTrimmingCharactersInSet:trimSet];
        if([titleParts count] > 2) {
            result.trackName = [[[titleParts subarrayWithRange:NSMakeRange(1, [titleParts count] - 1)]
                          componentsJoinedByString:@" — "] stringByTrimmingCharactersInSet:trimSet]; 
        } else {
            result.trackName = [[titleParts objectAtIndex:1] stringByTrimmingCharactersInSet:trimSet];
        }
        return result;
    }
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Artist: '%@' Track: '%@'", self.artist, self.trackName];
}

@end
