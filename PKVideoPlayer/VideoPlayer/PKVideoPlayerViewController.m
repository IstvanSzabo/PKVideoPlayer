//
//  PKVideoPlayerViewController.m
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#define kVideoPlayerVideoChangedNotification @"kVideoPlayerVideoChangedNotification"
#define kVideoPlayerWillHideControlsNotification @"kVideoPlayerWillHideControlsNotification"
#define kVideoPlayerWillShowControlsNotification @"kVideoPlayerWillShowControlsNotification"
#define kTrackEventVideoStart @"kTrackEventVideoStart"
#define kTrackEventVideoLiveStart @"kTrackEventVideoLiveStart"
#define kTrackEventVideoComplete @"kTrackEventVideoComplete"

#import "PKVideoPlayerViewController.h"

@interface PKVideoPlayerViewController (autorotateToInterface)

@end
@interface PKVideoPlayerViewController () <UIGestureRecognizerDelegate>
@property (readwrite, strong) id scrubberTimeObserver;
@property (readwrite, strong) id playClockTimeObserver;

@property (readwrite) BOOL restoreVideoPlayStateAfterScrubbing;
@property (readwrite) BOOL seekToZeroBeforePlay;
@property (readwrite) BOOL rotationIsLocked;
@property (readwrite) BOOL playerIsBuffering;
@property (nonatomic, weak) UIViewController *containingViewController;
@property (nonatomic, weak) UIView *topView;
@property (readwrite) BOOL fullScreenModeToggled;
@property (nonatomic) BOOL isAlwaysFullscreen;
//@property (nonatomic, strong) FullScreenViewController *fullscreenViewController;
@property (nonatomic) CGRect previousBounds;
@property (nonatomic) BOOL hideTopViewWithControls;

@end

@implementation PKVideoPlayerViewController
{
    BOOL playWhenReady;
    BOOL scrubBuffering;
    BOOL showShareOptions;
}
@synthesize
isPlaying = _isPlaying;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)loadView
{
    if (!self.videoPlayerView) {
        self.videoPlayerView = [[PKVideoPlayerView alloc] initWithFrame:CGRectZero];
        [self.videoPlayerView sizeToFit];
        self.videoPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|
                                                UIViewAutoresizingFlexibleHeight;
    }    
    self.view = self.videoPlayerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 播放键
    [_videoPlayerView.playPauseButton addTarget:self action:@selector(playPauseHandler) forControlEvents:UIControlEventTouchUpInside];
    // 进度条
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubberIsScrolling) forControlEvents:UIControlEventValueChanged];
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    // 手势
    UITapGestureRecognizer *playerTouchedGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoTapHandler)];
    playerTouchedGesture.delegate = self;
    [_videoPlayerView addGestureRecognizer:playerTouchedGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
#pragma mark - Public
- (void)playVideoWithTitle:(NSString *)title
                       URL:(NSURL *)url
                   videoID:(NSString *)videoID
                  shareURL:(NSURL *)shareURL
               isStreaming:(BOOL)streaming
          playInFullScreen:(BOOL)playInFullScreen
{
    [self.videoPlayer pause];
    [[_videoPlayerView activityIndicator] startAnimating];
    [self showControls];
    
    [self.videoPlayerView.progressView setProgress:0 animated:NO];
    [_videoPlayerView.currentPositionLabel setText:@""];
    [_videoPlayerView.timeLeftLabel setText:@""];
    _videoPlayerView.videoScrubber.value = 0;
    [_videoPlayerView setTitle:title];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
                                     MPMediaItemPropertyTitle: title,
     }];
    
    [self setURL:url];
    
    [self syncPlayPauseButtons];
    
    if (playInFullScreen) {
        [self launchFullScreen];
    }
}
- (void)setControlsEdgeInsets:(UIEdgeInsets)controlsEdgeInsets
{
    if (!self.videoPlayerView) {
        self.videoPlayerView = [[PKVideoPlayerView alloc] initWithFrame:CGRectZero];
    }
    _controlsEdgeInsets = controlsEdgeInsets;
    self.videoPlayerView.controlsEdgeInsets = _controlsEdgeInsets;
    
    [self.view setNeedsLayout];
}

#pragma mark - Private
- (void)videoTapHandler
{
    if (_videoPlayerView.playerControlBar.alpha) {
        [self hideControlsAnimated:YES];
    } else {
        [self showControls];
    }
}

- (void)syncFullScreenButton:(UIInterfaceOrientation)toInterfaceOrientation
{}
- (void)showCannotFetchStreamError
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Sad Panda says..."
                              message:@"I can't seem to fetch that stream. Please try again later."
                              delegate:nil
                              cancelButtonTitle:@"Bummer!"
                              otherButtonTitles:nil];
    [alertView show];
}
- (void)launchFullScreen
{}
- (void)minimizeVideo
{}
- (void)playPauseHandler
{
    
    if ([self isPlaying]) {
        [_videoPlayer pause];
    } else {
        [self playVideo];
        [[_videoPlayerView activityIndicator] stopAnimating];
    }
    
    [self syncPlayPauseButtons];
    [self showControls];
}
- (void)updatePlaybackProgress
{
    [self syncPlayPauseButtons];
    [self showControls];
    
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (CMTIME_IS_INDEFINITE(playerDuration) || duration <= 0) {
        [_videoPlayerView.videoScrubber setHidden:YES];
        [_videoPlayerView.progressView setHidden:YES];
        [self syncPlayClock];
        return;
    }
    
    [_videoPlayerView.videoScrubber setHidden:NO];
    [_videoPlayerView.progressView setHidden:NO];
    
    CGFloat width = CGRectGetWidth([_videoPlayerView.videoScrubber bounds]);
    interval = 0.5f * duration / width;
    __weak PKVideoPlayerViewController *vpvc = self;
    _scrubberTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                       queue:NULL
                                                                  usingBlock:^(CMTime time) {
                                                                      [vpvc syncScrubber];
                                                                  }];
    
    // Update the play clock every second
    _playClockTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [vpvc syncPlayClock];
                                                                   }];
    
}
- (void)showControls
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillShowControlsNotification
                                                        object:self
                                                      userInfo:nil];
    [UIView animateWithDuration:0.4 animations:^{
        self.videoPlayerView.playerControlBar.alpha = 1.0;
        self.videoPlayerView.titleLabel.alpha = 1.0;
        //_videoPlayerView.shareButton.alpha = 1.0;
    } completion:nil];
    
    if (self.fullScreenModeToggled) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationFade];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlsAnimated:) object:@YES];
    
    if ([self isPlaying]) {
        [self performSelector:@selector(hideControlsAnimated:) withObject:@YES afterDelay:4.0];
    }
}
- (void)hideControlsAnimated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillHideControlsNotification
                                                        object:self
                                                      userInfo:nil];
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^{
            self.videoPlayerView.playerControlBar.alpha = 0;
            self.videoPlayerView.titleLabel.alpha = 0;
        } completion:nil];
        
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationFade];
        }
        
    } else {
        self.videoPlayerView.playerControlBar.alpha = 0;
        self.videoPlayerView.titleLabel.alpha = 0;
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationNone];
        }
    }
}
- (void)syncPlayClock
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    if (CMTIME_IS_INDEFINITE(playerDuration)) {
        [_videoPlayerView.currentPositionLabel setText:@"LIVE"];
        [_videoPlayerView.timeLeftLabel setText:@""];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(CMTimeGetSeconds([_videoPlayer currentTime]));
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoPlayerView.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
//        if (!self.showStaticEndTime) {
//            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"-%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
//        } else {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
//        }
	}
}

- (CMTime)playerItemDuration
{
    if (_videoPlayer.status == AVPlayerItemStatusReadyToPlay) {
        return([_videoPlayer.currentItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        _videoPlayerView.videoScrubber.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [_videoPlayerView.videoScrubber minimumValue];
        float maxValue = [_videoPlayerView.videoScrubber maximumValue];
        double time = CMTimeGetSeconds([_videoPlayer currentTime]);
        
        [_videoPlayerView.videoScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (void)playVideo
{
    self.playerIsBuffering = NO;
    scrubBuffering = NO;
    playWhenReady = NO;
    // Configuration is done, ready to start.
    [self.videoPlayer play];
    [self updatePlaybackProgress];
}

- (NSString *)stringFormattedTimeFromSeconds:(double *)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:*seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    if (*seconds >= 3600) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    
    return [formatter stringFromDate:date];
}
+ (PKVideoPlayerViewController *)videoPlayerWithContainingViewController:(UIViewController *)containingViewController
                                                         optionalTopView:(UIView *)topView
                                                 hideTopViewWithControls:(BOOL)hideTopViewWithControls
{
    PKVideoPlayerViewController *videoPlayer = [[PKVideoPlayerViewController alloc] init];
    return videoPlayer;
}

- (void)setURL:(NSURL *)url
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackBufferEmpty"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackLikelyToKeepUp"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"loadedTimeRanges"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    if (!self.videoPlayer) {
        _videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        [_videoPlayer setAllowsAirPlayVideo:YES];
        [_videoPlayer setUsesAirPlayVideoWhileAirPlayScreenIsActive:YES];
        
        if ([_videoPlayer respondsToSelector:@selector(setAllowsExternalPlayback:)]) { // iOS 6 API
            [_videoPlayer setAllowsExternalPlayback:YES];
        }
        
        [_videoPlayerView setPlayer:_videoPlayer];
    } else {
        [self removeObserversFromVideoPlayerItem];
        [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    
    // iOS 5
    [_videoPlayer addObserver:self forKeyPath:@"airPlayVideoActive"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    // iOS 6
    [_videoPlayer addObserver:self
                   forKeyPath:@"externalPlaybackActive"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.videoPlayer.currentItem];
    
}

- (void)syncPlayPauseButtons
{
    if ([self isPlaying]) {
        [_videoPlayerView.playPauseButton setImage:[UIImage imageForKey:@"pause-button"] forState:UIControlStateNormal];
    } else {
        [_videoPlayerView.playPauseButton setImage:[UIImage imageForKey:@"play-button"] forState:UIControlStateNormal];
    }
}

- (void)removeObserversFromVideoPlayerItem
{
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_videoPlayer removeObserver:self forKeyPath:@"externalPlaybackActive"];
    [_videoPlayer removeObserver:self forKeyPath:@"airPlayVideoActive"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _videoPlayer
        && ([keyPath isEqualToString:@"externalPlaybackActive"] || [keyPath isEqualToString:@"airPlayVideoActive"])) {
//        BOOL externalPlaybackActive = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//        [[_videoPlayerView airplayIsActiveView] setHidden:!externalPlaybackActive];
        return;
    }
    
    if (object != [_videoPlayer currentItem]) {
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:
                playWhenReady = YES;
                break;
            case AVPlayerStatusFailed:
                // TODO:
                [self removeObserversFromVideoPlayerItem];
                //[self removePlayerTimeObservers];
                self.videoPlayer = nil;
                NSLog(@"failed");
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"] && _videoPlayer.currentItem.playbackBufferEmpty) {
        self.playerIsBuffering = YES;
        [[_videoPlayerView activityIndicator] startAnimating];
        [self syncPlayPauseButtons];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _videoPlayer.currentItem.playbackLikelyToKeepUp) {
        NSLog(@"playbackLikelyToKeepUp");
        if (![self isPlaying] && (playWhenReady || self.playerIsBuffering || scrubBuffering)) {
            [self playVideo];
        }
        [[_videoPlayerView activityIndicator] stopAnimating];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float durationTime = CMTimeGetSeconds([[self.videoPlayer currentItem] duration]);        
        float bufferTime = [self availableDuration];
        NSLog(@"durationTime:%.3f",bufferTime/durationTime);
        [self.videoPlayerView.progressView setProgress:bufferTime/durationTime animated:YES];
    }
    
    return;
}

- (CGFloat)availableDuration
{
    NSArray *loadedTimeRanges = [[self.videoPlayer currentItem] loadedTimeRanges];
    CGFloat ret = 0.0f;
    if ([loadedTimeRanges count] > 0)
    {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        ret = (startSeconds + durationSeconds);
    }    
    return ret;
}

- (BOOL)isPlaying
{
    return [_videoPlayer rate] != 0.0;
}

-(void)removePlayerTimeObservers
{
    if (_scrubberTimeObserver) {
        [_videoPlayer removeTimeObserver:_scrubberTimeObserver];
        _scrubberTimeObserver = nil;
    }
    
    if (_playClockTimeObserver) {
        [_videoPlayer removeTimeObserver:_playClockTimeObserver];
        _playClockTimeObserver = nil;
    }
}
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self syncPlayPauseButtons];
    _seekToZeroBeforePlay = YES;
    
    [self minimizeVideo];
}

-(void)scrubbingDidBegin
{
    if ([self isPlaying]) {
        [_videoPlayer pause];
        [self syncPlayPauseButtons];
        self.restoreVideoPlayStateAfterScrubbing = YES;
        [self showControls];
    }
}

-(void)scrubberIsScrolling
{
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(duration * _videoPlayerView.videoScrubber.value);
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoPlayerView.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
        
        if (!self.showStaticEndTime) {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"-%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
        } else {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
        }
        [_videoPlayer seekToTime:CMTimeMakeWithSeconds((float) currentTime, NSEC_PER_SEC)];
    }
}

-(void)scrubbingDidEnd
{
    if (self.restoreVideoPlayStateAfterScrubbing) {
        self.restoreVideoPlayStateAfterScrubbing = NO;
        scrubBuffering = YES;
    }
    [[_videoPlayerView activityIndicator] startAnimating];
    
    [self showControls];
}

@end


@implementation PKVideoPlayerViewController (autorotateToInterface)

#pragma mark - UIInterfaceOrientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation{
//    return UIDeviceOrientationIsValidInterfaceOrientation(orientation);
    return UIInterfaceOrientationIsLandscape(orientation);
}
// iOS 6.0+ 横竖屏
- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskAll;
    return UIInterfaceOrientationMaskLandscape;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        //        [[[self moviePlayerController] view] setFrame:self.view.bounds];
        //        [self resizeOverlay];
    }];
}

@end
