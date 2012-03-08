//
//  RadiostationMetadata.m
//  audioCenter
//
//  Created by Sergey Parshukov on 09.03.2012
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "RadiostationMetadata.h"

@implementation RadiostationMetadata

+ (void)getStationTitleWithUrl:(NSURL*)url completionHandler:(void (^)(NSString *title))handler {
	dispatch_queue_t queue = dispatch_queue_create("stationMetadata", NULL);
	dispatch_async(queue, ^{
		NSString *title = nil;
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[request addValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
		[request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.66 Safari/535.11" forHTTPHeaderField:@"User-Agent"];
		
		NSData *buf = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil]; 
		NSString *html = [NSString stringWithUTF8String:[buf bytes]];
		
		if(html) {
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:
										  @"Stream Title: </font></td><td><font class=default><b>(.*?)</b>"
																				   options:NSRegularExpressionCaseInsensitive
																					 error:nil];
			NSTextCheckingResult *match = [regex firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
			
			if(!NSEqualRanges(match.range, NSMakeRange(NSNotFound, 0))) {
				title = [html substringWithRange:[match rangeAtIndex:1]];
			}
			if(title) {
				title = [title stringByReplacingOccurrencesOfString:@" - " withString:@" — "];
			}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			handler(title);
		});
	});
	dispatch_release(queue);
}

@end
