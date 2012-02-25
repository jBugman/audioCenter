//
//  Created by Sergey Parshukov.
//  Copyright 2011 Digital Zone. All rights reserved.
//
#import "NSString+md5.h"

@implementation NSString (md5)

-(NSString*)md5
{
    const char* concat_str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString* hash = [NSMutableString string];
    for(int i = 0; i < 16; i++)
    {
        [hash appendFormat: @"%02X", result[i]];
    }
    return [hash lowercaseString];
}

@end