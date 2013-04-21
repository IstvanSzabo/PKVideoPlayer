//
//  PKVideoPlayer.m
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import "PKVideoPlayerView.h"

#define PLAYER_CONTROL_BAR_HEIGHT 40
#define BUTTON_PADDING 8
#define CURRENT_POSITION_WIDTH 56
#define TIME_LEFT_WIDTH 70
#define ALIGNMENT_FUZZ 2
#define ROUTE_BUTTON_ALIGNMENT_FUZZ 8

@interface PKVideoPlayerView ()
@property (readwrite, strong) MPVolumeView *volumeView;
@end

@implementation PKVideoPlayerView

- (void)dealloc
{
    
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_titleLabel setFont:[UIFont fontWithName:@"Forza-Medium" size:16.0f]];
        [_titleLabel setTextColor:[UIColor whiteColor]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setNumberOfLines:2];
        [_titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [_titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_titleLabel];
        
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 60, 30)];
        [_backButton setTitle:@"返回" forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_backButton setBackgroundColor:[UIColor colorWithRed:1.0f
                                                        green:1.0f
                                                         blue:0.0f
                                                        alpha:0.3f]];
        [_backButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:_backButton];
        
        
        _playerControlBar = [[UIView alloc] init];
        [_playerControlBar setOpaque:NO];
        [_playerControlBar setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
        
        _playPauseButton = [[UIButton alloc] init];
        [_playPauseButton setImage:[UIImage imageForKey:@"play-button"] forState:UIControlStateNormal];
        [_playPauseButton setShowsTouchWhenHighlighted:YES];
        [_playerControlBar addSubview:_playPauseButton];
   
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor colorWithRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
        _progressView.trackTintColor = [UIColor darkGrayColor];
        [_playerControlBar addSubview:_progressView];
        
        _videoScrubber = [[UISlider alloc] init];
        [_videoScrubber setMinimumTrackTintColor:[UIColor redColor]];
        [_videoScrubber setMaximumTrackImage:[UIImage imageForKey:@"transparentBar"] forState:UIControlStateNormal];
        [_videoScrubber setThumbTintColor:[UIColor whiteColor]];
        [_playerControlBar addSubview:_videoScrubber];
        
        _volumeView = [[MPVolumeView alloc] init];
        [_volumeView setShowsRouteButton:YES];
        [_volumeView setShowsVolumeSlider:NO];
        [_playerControlBar addSubview:_volumeView];
        
        // Listen to alpha changes to know when other routes are available
        for (UIButton *button in [_volumeView subviews]) {
            if (![button isKindOfClass:[UIButton class]]) {
                continue;
            }
            
//            [button addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
        }
        
        _currentPositionLabel = [[UILabel alloc] init];
        [_currentPositionLabel setBackgroundColor:[UIColor clearColor]];
        [_currentPositionLabel setTextColor:[UIColor whiteColor]];
        [_currentPositionLabel setFont:[UIFont fontWithName:@"DINRoundCompPro" size:14.0f]];
        [_currentPositionLabel setTextAlignment:NSTextAlignmentCenter];
        [_playerControlBar addSubview:_currentPositionLabel];
        
        _timeLeftLabel = [[UILabel alloc] init];
        [_timeLeftLabel setBackgroundColor:[UIColor clearColor]];
        [_timeLeftLabel setTextColor:[UIColor whiteColor]];
        [_timeLeftLabel setFont:[UIFont fontWithName:@"DINRoundCompPro" size:14.0f]];
        [_timeLeftLabel setTextAlignment:NSTextAlignmentCenter];
        [_playerControlBar addSubview:_timeLeftLabel];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_activityIndicator];
        
        self.controlsEdgeInsets = UIEdgeInsetsZero;

    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = [self bounds];
    
    CGRect insetBounds = CGRectInset(UIEdgeInsetsInsetRect(bounds, self.controlsEdgeInsets), _padding, _padding);
    CGSize titleLabelSize = [[_titleLabel text] sizeWithFont:[_titleLabel font]
                                           constrainedToSize:CGSizeMake(insetBounds.size.width, CGFLOAT_MAX)
                                               lineBreakMode:NSLineBreakByCharWrapping];
    
    [_titleLabel setFrame:CGRectMake(insetBounds.origin.x + self.padding,
                                     insetBounds.origin.y,
                                     insetBounds.size.width,
                                     titleLabelSize.height)];
    
    

    [_playerControlBar setFrame:CGRectMake(bounds.origin.x,
                                           bounds.size.height - PLAYER_CONTROL_BAR_HEIGHT,
                                           bounds.size.width,
                                           PLAYER_CONTROL_BAR_HEIGHT)];
    
    [_activityIndicator setFrame:CGRectMake((bounds.size.width - _activityIndicator.frame.size.width)/2.0,
                                            (bounds.size.height - _activityIndicator.frame.size.width)/2.0,
                                            _activityIndicator.frame.size.width,
                                            _activityIndicator.frame.size.height)];
    
    [_playPauseButton setFrame:CGRectMake(0,
                                          0,
                                          PLAYER_CONTROL_BAR_HEIGHT,
                                          PLAYER_CONTROL_BAR_HEIGHT)];
    
    
    CGRect routeButtonRect = CGRectZero;

    if ([_volumeView respondsToSelector:@selector(routeButtonRectForBounds:)]) {
        routeButtonRect = [_volumeView routeButtonRectForBounds:bounds];
    } else {
        routeButtonRect = CGRectMake(0, 0, 24, 18);
    }
    [_volumeView setFrame:CGRectMake(- routeButtonRect.size.width
                                     - ROUTE_BUTTON_ALIGNMENT_FUZZ,
                                     PLAYER_CONTROL_BAR_HEIGHT / 2 - routeButtonRect.size.height / 2,
                                     routeButtonRect.size.width,
                                     routeButtonRect.size.height)];

    [_currentPositionLabel setFrame:CGRectMake(PLAYER_CONTROL_BAR_HEIGHT,
                                               ALIGNMENT_FUZZ,
                                               CURRENT_POSITION_WIDTH,
                                               PLAYER_CONTROL_BAR_HEIGHT)];
    [_timeLeftLabel setFrame:CGRectMake(bounds.size.width - PLAYER_CONTROL_BAR_HEIGHT - TIME_LEFT_WIDTH
                                        - routeButtonRect.size.width,
                                        ALIGNMENT_FUZZ,
                                        TIME_LEFT_WIDTH,
                                        PLAYER_CONTROL_BAR_HEIGHT)];
    
    CGRect scrubberRect = CGRectMake(PLAYER_CONTROL_BAR_HEIGHT + CURRENT_POSITION_WIDTH,
                                     0,
                                     bounds.size.width - (PLAYER_CONTROL_BAR_HEIGHT * 2) - TIME_LEFT_WIDTH -
                                     CURRENT_POSITION_WIDTH - (TIME_LEFT_WIDTH - CURRENT_POSITION_WIDTH)
                                     - routeButtonRect.size.width,
                                     PLAYER_CONTROL_BAR_HEIGHT);
    
    [_videoScrubber setFrame:scrubberRect];
    [_progressView setFrame:[_videoScrubber trackRectForBounds:scrubberRect]];
}

- (void)setTitle:(NSString *)title
{
    [_titleLabel setText:title];
    [self setNeedsLayout];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)self.layer setPlayer:player];
    [self addSubview:self.playerControlBar];
}

@end
