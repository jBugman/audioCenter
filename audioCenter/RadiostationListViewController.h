//
//  RadiostationListViewController.h
//  audioCenter
//
//  Created by Sergey Parshukov on 26.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RadiostationListDelegate <NSObject>

- (void)setRadiostation:(NSString*)stationUrl;

@optional
- (void) play;

@end

@interface RadiostationListViewController : UIViewController

@property (weak, nonatomic) id<RadiostationListDelegate> delegate;

@end