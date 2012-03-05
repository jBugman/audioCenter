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
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "NormalizedTrackTitle.h"
#import "RadiostationListViewController.h"
#import "NSString+md5.h"


#define TIMED_METADATA @"timedMetadata"
#define DEFAULT_RADIO_URL @"http://87.118.78.20:2700/"


@interface RadioViewController() <RadiostationListDelegate>

@property (weak, nonatomic) IBOutlet UILabel *trackArtist;
@property (weak, nonatomic) IBOutlet UILabel *trackTitle;
@property (weak, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIImageView *trackImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *titleActivityIndicator;

@property (strong, nonatomic) AVPlayer *radio;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL wasInterrupted;
@property (strong, nonatomic) NSString *albumTitle;

@property (strong, nonatomic) LastFmAPI *api;
@property (strong, nonatomic) NSString *sessionKey;

@property (strong, nonatomic) NormalizedTrackTitle *previousTrack;
@property (assign, nonatomic) NSTimeInterval previousTrackStartTime;
@property (assign, nonatomic) NSTimeInterval previousTrackLength;

- (void)loadImageWithUrl:(NSString*)imageUrl;
- (void)processCache;

void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, 
									   const void *inPropertyValue);
@end

@implementation RadioViewController

@synthesize playPauseButton = _playPauseButton;
@synthesize trackImage = _trackImage;
@synthesize activityIndicator = _activityIndicator;
@synthesize titleActivityIndicator = _titleActivityIndicator;
@synthesize albumTitleLabel = _albumTitleLabel;

@synthesize trackArtist = _trackArtist, trackTitle = _trackTitle, username = _username;
@synthesize radio = _radio, isPlaying = _isPlaying, wasInterrupted = _wasInterrupted;
@synthesize api = _api;
@synthesize sessionKey = _sessionKey;
@synthesize previousTrack = _previousTrack;
@synthesize previousTrackStartTime = _previousTrackStartTime, previousTrackLength = _previousTrackLength;
@synthesize albumTitle = _albumTitle;

- (void)setAlbumTitle:(NSString *)albumTitle {
	_albumTitle = albumTitle;
	self.albumTitleLabel.text = self.albumTitle;
	CGRect frame;
	if(albumTitle != nil && ![albumTitle isEqualToString:@""]) {
		frame = self.trackArtist.frame;
		frame.origin.y = 0;
		self.trackArtist.frame = frame;
		frame = self.trackTitle.frame;
		frame.origin.y = 10;
		self.trackTitle.frame = frame;
	} else {
		frame = self.trackArtist.frame;
		frame.origin.y = 5;
		self.trackArtist.frame = frame;
		frame = self.trackTitle.frame;
		frame.origin.y = 17;
		self.trackTitle.frame = frame;
	}
}

-(void)processCache {
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachesPath error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]];
	long totalSize = 0;
	for(NSString* fileName in files) {
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[cachesPath stringByAppendingPathComponent:fileName] error:nil];
		totalSize += [((NSNumber*)[attributes valueForKey:NSFileSize]) longValue];
	}
	totalSize /= 1024;
	NSLog(@"[i] Cache size: %@K", [NSNumber numberWithLong:totalSize]);
}

- (void)setRadiostation:(NSString*)stationUrl {
	[self.radio pause];
	[self.radio.currentItem removeObserver:self forKeyPath:TIMED_METADATA];
	self.radio = nil;
	self.trackArtist.text = @"";
	self.trackTitle.text = @"";
	self.albumTitle = @"";
	self.trackImage.image = nil;
	
	NSURL *streamUrl = [NSURL URLWithString:stationUrl];
	self.radio = [[AVPlayer alloc] initWithURL: streamUrl];
    [self.radio.currentItem addObserver:self forKeyPath:TIMED_METADATA options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if([segue.identifier isEqualToString:@"ShowRadiostations"]) {
		RadiostationListViewController *destinationController = segue.destinationViewController;
		destinationController.delegate = self;	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
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
        NormalizedTrackTitle *normalizedTitle = [NormalizedTrackTitle normalizedTrackTitleWithString:metadataTitle];
        self.trackArtist.text = normalizedTitle.artist;
        self.trackTitle.text = normalizedTitle.trackName;
		self.trackImage.image = nil;
		self.albumTitle = nil;
		[self.titleActivityIndicator stopAnimating];
		[self.activityIndicator startAnimating];
        if(normalizedTitle.isFilled) {
            [self.api getInfoForTrack:normalizedTitle.trackName artist:normalizedTitle.artist completionHandler:^(NSDictionary *trackInfo, NSError *error) {
                NSString *albumImageUrl = [[[trackInfo valueForKeyPath:@"album.image"] lastObject] valueForKey:@"#text"];
				self.previousTrackLength = [((NSNumber*)[trackInfo valueForKey:@"duration"]) doubleValue] / 1000;
				self.albumTitle = [trackInfo valueForKeyPath:@"album.title"];
                if(albumImageUrl != nil) {
					[self loadImageWithUrl:albumImageUrl];
                } else {
                    [self.api getInfoForArtist:normalizedTitle.artist completionHandler:^(NSDictionary *artistInfo, NSError *error) {
						if(error) {
							NSLog(@"error: %@", error);
						} else {
							NSString *artistImageUrl = [[[artistInfo valueForKey:@"image"] lastObject] valueForKey:@"#text"];
							if(artistImageUrl != nil) {
								[self loadImageWithUrl:artistImageUrl];
							} else {
								self.trackImage.image = nil;
							}
						}
                    }];
                }
            }];
            if(self.previousTrack != nil && normalizedTitle != self.previousTrack) {
				NSTimeInterval deltaT = [[NSDate date] timeIntervalSince1970] - self.previousTrackStartTime;
				NSLog(@"dT %f %f", deltaT, self.previousTrackLength);
				if((self.previousTrackLength > 0 && deltaT > self.previousTrackLength / 2) || deltaT > 240) { //Cкробблинг с 50% или 4 минут
					[self.api scrobbleTrack:self.previousTrack.trackName artist:self.previousTrack.artist
								  timestamp:[[NSDate date] timeIntervalSince1970]
								 sessionKey:self.sessionKey completionHandler:^(NSError *error) {
						NSLog(@"%@", error);
					}];
				}
            }
            self.previousTrack = normalizedTitle;
			self.previousTrackStartTime = [[NSDate date] timeIntervalSince1970];
            [self.api updateNowPlayingTrack:normalizedTitle.trackName artist:normalizedTitle.artist sessionKey:self.sessionKey completionHandler:^(NSError *error) {
                NSLog(@"%@", error);
            }];
        }
    }
}

- (void)loadImageWithUrl:(NSString*)imageUrl {
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *cacheFile = [cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [imageUrl md5]]];
	if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
		self.trackImage.image = [UIImage imageWithContentsOfFile:cacheFile];
		[self.activityIndicator stopAnimating];
	} else {
		dispatch_queue_t downloadQueue = dispatch_queue_create("imageDownloader", NULL);
		dispatch_async(downloadQueue, ^{
			NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
			UIImage *image = [UIImage imageWithData: imageData];
			[UIImageJPEGRepresentation(image, 85) writeToFile:cacheFile atomically:YES];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.trackImage.image = image;
				[self.activityIndicator stopAnimating];
			});
		});
		dispatch_release(downloadQueue);
	}
}

- (void)pause {
	[self.radio pause];
	[self.playPauseButton setImage:[UIImage imageNamed:@"playIcon.png"] forState:UIControlStateNormal];
	self.isPlaying = NO;
	
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)play {
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, (__bridge void*)self);
	
	[self.radio play];
	[self.playPauseButton setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
	self.isPlaying = YES;
	self.wasInterrupted = NO;
	if(!self.radio.currentItem.timedMetadata) {
		[self.titleActivityIndicator startAnimating];
	}
}

- (IBAction)playPauseTap:(UIButton*)sender {
    if(self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if(event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
		if(self.isPlaying) {
			[self pause];
		} else {
			[self play];
		}
	}
}

void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, 
									   const void *inPropertyValue) {
    if(inPropertyID != kAudioSessionProperty_AudioRouteChange)
		return;
	
	CFDictionaryRef routeChangeDictionary = inPropertyValue;
	CFNumberRef routeChangeReasonRef = CFDictionaryGetValue(routeChangeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
	SInt32 routeChangeReason;
	CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
	
	RadioViewController *this = (__bridge RadioViewController*)inUserData;
	
	if(routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
		if(this.isPlaying) {
			this.wasInterrupted = YES;
		}
		[this pause];
	} else {
		if(this.wasInterrupted) {
			[this play];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.api = [[LastFmAPI alloc] init];
	[self setRadiostation:DEFAULT_RADIO_URL];
	
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
	
	[self.api getSessionWithUsername:@"jBugman" password:@"lastfm"
                   completionHandler:^(NSDictionary *session, NSError *error) {
					   self.sessionKey = [session valueForKey:@"key"];
					   self.username.text = [session valueForKey:@"name"];
				   }];
	
	[self processCache];
}

- (void)viewDidUnload {
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
	
    self.trackTitle = nil;
    self.trackArtist = nil;
    self.username = nil;
    self.playPauseButton = nil;
    self.trackImage = nil;
	self.activityIndicator = nil;
	self.titleActivityIndicator = nil;
	self.albumTitle = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
