//
//  PKVideoPlayer.h
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKVideoPlayerView : UIView

@property (readwrite)        CGFloat                     padding;
@property (readonly, strong) UILabel                    *titleLabel;
@property (readonly, strong) UIView                     *playerControlBar;
@property (readonly, strong) UIButton                   *playPauseButton;
@property (readonly, strong) UISlider                   *videoScrubber;
@property (readonly, strong) UILabel                    *currentPositionLabel;
@property (readonly, strong) UILabel                    *timeLeftLabel;
@property (readonly, strong) UIProgressView             *progressView;
@property (readwrite)        UIEdgeInsets                controlsEdgeInsets;
@property (readonly, strong) UIActivityIndicatorView    *activityIndicator;


- (void)setTitle:(NSString *)title;
- (void)setPlayer:(AVPlayer *)player;

@end
