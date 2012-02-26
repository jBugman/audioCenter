//
//  ViewController.m
//  audioCenter
//
//  Created by Sergey Parshukov on 24.02.2012.
//  Copyright (c) 2012 Sergey Parshukov. All rights reserved.
//

#import "RadioViewController.h"
#import <MediaPlayer/MPMoviePlayerController.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import "NormalizedTrackTitle.h"
#import "RadiostationListViewController.h"


#define TIMED_METADATA @"timedMetadata"


@interface RadioViewController() <RadiostationListDelegate>

@property (weak, nonatomic) IBOutlet UILabel *trackArtist;
@property (weak, nonatomic) IBOutlet UILabel *trackTitle;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIImageView *trackImage;

@property (strong, nonatomic) AVPlayer *radio;
@property (assign, nonatomic) BOOL isPlaying;

@property (strong, nonatomic) LastFmAPI *api;
@property (strong, nonatomic) NSString *sessionKey;

@property (strong, nonatomic) NormalizedTrackTitle *previousTrack;

- (NSString*)getImageUrlWithTrackInfo:(NSDictionary*)trackInfo;
- (NSString*)getImageUrlWithArtistInfo:(NSDictionary*)artistInfo;

@end


@implementation RadioViewController

@synthesize playPauseButton = _playPauseButton;
@synthesize trackImage = _trackImage;

@synthesize trackArtist = _trackArtist, trackTitle = _trackTitle, username = _username;
@synthesize radio = _radio, isPlaying = _isPlaying;
@synthesize api = _api;
@synthesize sessionKey = _sessionKey;
@synthesize previousTrack = _previousTrack;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.api = [[LastFmAPI alloc] init];
	[self setRadiostation:@"http://ultradarkradio.com:3026/"];
	[self pause];
}

- (void)setRadiostation:(NSString*)stationUrl {
	[self.radio pause];
	[self.radio.currentItem removeObserver:self forKeyPath:TIMED_METADATA];
	self.radio = nil;
	self.trackArtist.text = @"";
	self.trackTitle.text = @"";
	self.trackImage.image = nil;
	
	NSURL *streamUrl = [NSURL URLWithString:stationUrl];
	self.radio = [[AVPlayer alloc] initWithURL: streamUrl];
    [self.radio.currentItem addObserver:self forKeyPath:TIMED_METADATA options:NSKeyValueObservingOptionNew context:NULL];
	
	[self play];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if([segue.identifier isEqualToString:@"ShowRadiostations"]) {
		RadiostationListViewController *destinationController = segue.destinationViewController;
		destinationController.delegate = self;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSLog(@"[!] OBSERVE");
    if([keyPath isEqualToString:TIMED_METADATA]) { // Получили обновленную метадату — значит играет новый трек или это первый запуск
        AVPlayerItem *playerItem = object;
        NSArray *metadata = playerItem.timedMetadata;
        NSString *metadataTitle;
        for(id entry in metadata) {
            if([[entry valueForKey:@"key"] isEqualToString:@"title"]) {
                metadataTitle = [entry valueForKey:@"value"];
                break;
            }
        }
        NSLog(@"%@", metadataTitle);
        NormalizedTrackTitle *normalizedTitle = [NormalizedTrackTitle normalizedTrackTitleWithString:metadataTitle];
        self.trackArtist.text = normalizedTitle.artist;
        self.trackTitle.text = normalizedTitle.trackName;
        if(normalizedTitle.isFilled) {
            [self.api getInfoForTrack:normalizedTitle.trackName artist:normalizedTitle.artist completionHandler:^(NSDictionary *trackInfo, NSError *error) {
                NSString *albumImageUrl = [self getImageUrlWithTrackInfo:trackInfo];
                if(albumImageUrl != nil) {
                    NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:albumImageUrl]];
                    self.trackImage.image = [UIImage imageWithData: imageData];
                } else {
                    [self.api getInfoForArtist:normalizedTitle.artist completionHandler:^(NSDictionary *artistInfo, NSError *error) {
						if(error) {
							NSLog(@"error: %@", error);
						} else {
							NSString *artistImageUrl = [self getImageUrlWithArtistInfo:artistInfo];
							if(artistImageUrl != nil) {
								NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:artistImageUrl]];
								self.trackImage.image = [UIImage imageWithData: imageData];
							} else {
								self.trackImage.image = nil;
							}
						}
                    }];
                }
            }];
            if(self.previousTrack != nil && normalizedTitle != self.previousTrack) {
                [self.api scrobbleTrack:self.previousTrack.trackName artist:self.previousTrack.artist
                              timestamp:[[NSDate date] timeIntervalSince1970]
                             sessionKey:self.sessionKey completionHandler:^(NSError *error) {
                    NSLog(@"%@", error);
                }];
            }
            self.previousTrack = normalizedTitle;
            [self.api updateNowPlayingTrack:normalizedTitle.trackName artist:normalizedTitle.artist sessionKey:self.sessionKey completionHandler:^(NSError *error) {
                NSLog(@"%@", error);
            }];
        }
    }
}

- (NSString*)getImageUrlWithTrackInfo:(NSDictionary*)trackInfo {
	NSArray *images = [trackInfo valueForKeyPath:@"album.image"];
	return [[images lastObject] valueForKey:@"#text"];
}

- (NSString*)getImageUrlWithArtistInfo:(NSDictionary*)artistInfo {
    NSArray *images = [artistInfo valueForKey:@"image"];
    return [[images lastObject] valueForKey:@"#text"];
}

- (void)pause {
	[self.radio pause];
	[self.playPauseButton setImage:[UIImage imageNamed:@"playIcon.png"] forState:UIControlStateNormal];
	self.isPlaying = NO;
}

- (void)play {
	[self.radio play];
	[self.playPauseButton setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
	self.isPlaying = YES;
}

- (IBAction)playPauseTap:(UIButton*)sender {
    if(!self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

//- (BOOL)canBecomeFirstResponder {
//    return YES;
//}

//- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
//    if(event.subtype == UIEventSubtypeRemoteControlTogglePlayPause)
//        NSLog(@"external command");
//}

- (void)viewDidUnload {
    self.trackTitle = nil;
    self.trackArtist = nil;
    self.username = nil;
    [self setPlayPauseButton:nil];
    [self setTrackImage:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.api getSessionWithUsername:@"jBugman" password:@"lastfm"
                   completionHandler:^(NSDictionary *session, NSError *error) {
        self.sessionKey = [session valueForKey:@"key"];
        self.username.text = [session valueForKey:@"name"];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//    [self resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
