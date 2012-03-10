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
#import <AVFoundation/AVAsset.h>
#import <AudioToolbox/AudioToolbox.h>
#import "NormalizedTrackTitle.h"
#import "RadiostationListViewController.h"
#import "NSString+md5.h"
#import "RadiostationMetadata.h"


#define TIMED_METADATA @"timedMetadata"
#define RATE @"rate"

#define IMAGE_SIZE 320.0f

#define DEFAULT_RADIO_URL @"http://87.118.78.20:2700/"


@interface RadioViewController() <RadiostationListDelegate, AVAudioSessionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *trackArtist;
@property (weak, nonatomic) IBOutlet UILabel *trackTitle;
@property (weak, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIImageView *trackImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *titleActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *stationTitle;

@property (weak, nonatomic) IBOutlet UIButton *scrobblingStatus;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *scrobblingSpinner;


@property (strong, nonatomic) NSURL *radioUrl;
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
- (void)updateTrackInfo:(NSArray*)metadata;

void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, 
									   const void *inPropertyValue);
@end

@implementation RadioViewController

@synthesize playPauseButton = _playPauseButton;
@synthesize trackImage = _trackImage;
@synthesize activityIndicator = _activityIndicator;
@synthesize titleActivityIndicator = _titleActivityIndicator;
@synthesize albumTitleLabel = _albumTitleLabel;

@synthesize trackArtist = _trackArtist, trackTitle = _trackTitle;
@synthesize scrobblingStatus = _scrobblingStatus, stationTitle = _stationTitle;
@synthesize radio = _radio, isPlaying = _isPlaying, wasInterrupted = _wasInterrupted;
@synthesize scrobblingSpinner = _scrobblingSpinner;
@synthesize radioUrl = _radioUrl;
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

- (void)setRadioUrl:(NSURL *)radioUrl {
	_radioUrl = radioUrl;
	[self.radio pause];
	[self.radio.currentItem removeObserver:self forKeyPath:TIMED_METADATA];
	[self.radio removeObserver:self forKeyPath:RATE];
	self.radio = nil;
	self.previousTrack = nil;
	
	self.trackArtist.text = @"";
	self.trackTitle.text = @"";
	self.albumTitle = @"";
	self.trackImage.image = nil;
	self.stationTitle.text = @"";
}

- (AVPlayer *)radio {
	if(!self.radioUrl) {
		return nil;
	} else {
		if(!_radio) {
			_radio = [[AVPlayer alloc] initWithURL: self.radioUrl];
			[_radio.currentItem addObserver:self forKeyPath:TIMED_METADATA options:NSKeyValueObservingOptionNew context:NULL];
			[_radio addObserver:self forKeyPath:RATE options:NSKeyValueObservingOptionNew context:NULL];
		}
		return _radio;
	}
}

- (void)processCache {
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
	self.radioUrl = [NSURL URLWithString:stationUrl];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if([segue.identifier isEqualToString:@"ShowRadiostations"]) {
		RadiostationListViewController *destinationController = segue.destinationViewController;
		destinationController.delegate = self;	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:TIMED_METADATA]) { // Играет новый трек или это первый запуск
        AVPlayerItem *playerItem = object;
        NSArray *metadata = playerItem.timedMetadata;
		[self updateTrackInfo:metadata];
	} else if([keyPath isEqualToString:RATE]) { // Изменилось состояние играет/не играет
		AVPlayer *player = object;
		if(self.previousTrack.isFilled && player.rate > 0) {
			[self.titleActivityIndicator stopAnimating];
			if([self.trackArtist.text isEqualToString:@""]) {
				self.trackArtist.text = @"Unknown Artist";
				self.trackTitle.text = @"Unknown Track";
			}
		}
	}
}
		
- (void)updateTrackInfo:(NSArray *)metadata {	
	NSString *metadataTitle;
	for(id entry in metadata) {
		if([[entry valueForKey:@"key"] isEqualToString:@"title"]) {
			metadataTitle = [entry valueForKey:@"value"];
			break;
		}
	}
	NormalizedTrackTitle *normalizedTitle = [NormalizedTrackTitle normalizedTrackTitleWithString:metadataTitle];
	if(!normalizedTitle.isFilled) {
		[self.titleActivityIndicator stopAnimating];
		return;
	}
	self.trackArtist.text = normalizedTitle.artist;
	self.trackTitle.text = normalizedTitle.trackName;
	self.trackImage.image = nil;
	self.albumTitle = nil;
	[self.titleActivityIndicator stopAnimating];
	[self.activityIndicator startAnimating];

	[self.api getInfoForTrack:normalizedTitle.trackName artist:normalizedTitle.artist completionHandler:^(NSDictionary *trackInfo, NSError *error) {
		NSString *albumImageUrl = [[[trackInfo valueForKeyPath:@"album.image"] lastObject] valueForKey:@"#text"];
		self.previousTrackLength = [((NSNumber*)[trackInfo valueForKey:@"duration"]) doubleValue] / 1000;
		self.albumTitle = [trackInfo valueForKeyPath:@"album.title"];
		if(albumImageUrl != nil) {
//			self.trackImage.contentMode = UIViewContentModeScaleAspectFit;
			[self loadImageWithUrl:albumImageUrl];
		} else {
			[self.api getInfoForArtist:normalizedTitle.artist completionHandler:^(NSDictionary *artistInfo, NSError *error) {
				if(error) {
					NSLog(@"getInfoForArtist: %@", error);
					if(error && error.code == -1009) {
						self.scrobblingStatus.alpha = 0.2f;
					}
				} else {
					NSString *artistImageUrl = [[[artistInfo valueForKey:@"image"] lastObject] valueForKey:@"#text"];
					if(artistImageUrl != nil) {
//						self.trackImage.contentMode = UIViewContentModeScaleAspectFit;
						[self loadImageWithUrl:artistImageUrl];
					} else {
//						self.trackImage.contentMode = UIViewContentModeCenter;
						self.trackImage.image = nil; // TODO setting 'default' image
						[self.activityIndicator stopAnimating];
					}
				}
			}];
		}
	}];
	if(self.previousTrack != nil && normalizedTitle != self.previousTrack) {
		NSTimeInterval deltaT = [[NSDate date] timeIntervalSince1970] - self.previousTrackStartTime;
		if((self.previousTrackLength > 0 && deltaT > self.previousTrackLength / 2) || deltaT > 240) { //Cкробблинг с 50% или 4 минут
			if(self.sessionKey) {
				[self.api scrobbleTrack:self.previousTrack.trackName artist:self.previousTrack.artist
							  timestamp:[[NSDate date] timeIntervalSince1970]
							 sessionKey:self.sessionKey completionHandler:^(NSError *error) {
					NSLog(@"scrobbleTrack: %@", error);
					if(error && error.code == -1009) {
						self.scrobblingStatus.alpha = 0.2f;
					}
				}];
			}
		}
	}
	self.previousTrack = normalizedTitle;
	self.previousTrackStartTime = [[NSDate date] timeIntervalSince1970];
	if(self.sessionKey) {
		[self.api updateNowPlayingTrack:normalizedTitle.trackName artist:normalizedTitle.artist sessionKey:self.sessionKey completionHandler:^(NSError *error) {
			NSLog(@"updateNowPlayingTrack: %@", error);
			if(error && error.code == -1009) {
				self.scrobblingStatus.alpha = 0.2f;
			}
		}];
	}
}

- (UIImage*)resizeImage:(UIImage*)image {
	if(image.size.width > IMAGE_SIZE || image.size.height > IMAGE_SIZE) {
		double ratio = image.size.width / image.size.height;
		CGSize size = (ratio > 1.0f) ?
			CGSizeMake(IMAGE_SIZE, IMAGE_SIZE / ratio) :
			CGSizeMake(IMAGE_SIZE * ratio, IMAGE_SIZE);
		UIGraphicsBeginImageContext(size);
		[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	return image;
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
			image = [self resizeImage:image];
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
	[[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, (__bridge void*)self);

	if(!self.radio.currentItem.timedMetadata) {
		[self.titleActivityIndicator startAnimating];
	}
	
	[RadiostationMetadata getStationTitleWithUrl:self.radioUrl completionHandler:^(NSString *title) {
		self.stationTitle.text = title;
	}];
	
	[self.radio play];
	[self.playPauseButton setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
	self.isPlaying = YES;
	self.wasInterrupted = NO;
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

- (void)beginInterruption {
	[self pause];
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

- (void) auth {
	self.sessionKey = nil;
	self.scrobblingStatus.alpha = 0.2f;
	if([Settings sharedInstance].lastFmUsername.length && [Settings sharedInstance].lastFmPassword.length) {
		[self.scrobblingSpinner startAnimating];
		self.scrobblingStatus.hidden = YES;
		[self.api getSessionWithUsername:[Settings sharedInstance].lastFmUsername password:[Settings sharedInstance].lastFmPassword
					   completionHandler:^(NSDictionary *session, NSError *error) {
						   if(!error) {
							   self.sessionKey = [session valueForKey:@"key"];
							   self.scrobblingStatus.alpha = 1.0f;
						   } else {
							   self.scrobblingStatus.alpha = 0.2f;
						   }
						   self.scrobblingStatus.hidden = NO;
						   [self.scrobblingSpinner stopAnimating];
					   }];
	}
}

- (IBAction)updateAuth {
	[self auth];
}

- (void)viewDidAppear:(BOOL)animated {
	if(!self.sessionKey) {
		[self auth];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.api = [[LastFmAPI alloc] init];
	[self setRadiostation:DEFAULT_RADIO_URL];
	
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
	
	[self auth];
	
	[self processCache];
}

- (void)viewDidUnload {
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
	
    self.trackTitle = nil;
    self.trackArtist = nil;
    self.scrobblingStatus = nil;
	self.stationTitle = nil;
    self.playPauseButton = nil;
    self.trackImage = nil;
	self.activityIndicator = nil;
	self.titleActivityIndicator = nil;
	self.albumTitle = nil;
	[self setScrobblingSpinner:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
