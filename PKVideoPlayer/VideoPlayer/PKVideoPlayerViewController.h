//
//  PKVideoPlayerViewController.h
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKVideoPlayerViewController : UIViewController

@property (readwrite, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong) PKVideoPlayerView *videoPlayerView;
@property (readonly, strong) NSDictionary *currentVideoInfo;
@property (readonly) BOOL fullScreenModeToggled;

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
