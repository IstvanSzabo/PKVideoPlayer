//
//  PKVideoPlayerViewController.h
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKVideoPlayerViewController : UIViewController

// AVPlayer
@property (readwrite, strong) AVPlayer *videoPlayer;
// UI
@property (nonatomic, strong) PKVideoPlayerView *videoPlayerView;
// Propertys
@property (readonly, strong) NSDictionary *currentVideoInfo;
@property (readonly) BOOL fullScreenModeToggled;
@property (nonatomic, readonly) BOOL isPlaying;
// Config
@property (nonatomic) BOOL showStaticEndTime;
@property (nonatomic) BOOL allowPortraitFullscreen;
@property (nonatomic) UIEdgeInsets controlsEdgeInsets;

- (void)syncFullScreenButton:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)showCannotFetchStreamError;
- (void)launchFullScreen;
- (void)minimizeVideo;
- (void)playPauseHandler;

- (void)playVideoWithTitle:(NSString *)title
                       URL:(NSURL *)url
                   videoID:(NSString *)videoID
                  shareURL:(NSURL *)shareURL
               isStreaming:(BOOL)streaming
          playInFullScreen:(BOOL)playInFullScreen;
+ (PKVideoPlayerViewController *)videoPlayerWithContainingViewController:(UIViewController *)containingViewController
                                                         optionalTopView:(UIView *)topView
                                                 hideTopViewWithControls:(BOOL)hideTopViewWithControls;

@end
