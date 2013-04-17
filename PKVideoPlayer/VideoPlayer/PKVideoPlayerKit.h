//
//  PKVideoPlayerKit.h
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PKVideoPlayerView.h"
#import "PKVideoPlayerViewController.h"

extern NSString * const kVideoPlayerVideoChangedNotification;
extern NSString * const kVideoPlayerWillHideControlsNotification;
extern NSString * const kVideoPlayerWillShowControlsNotification;
extern NSString * const kTrackEventVideoStart;
extern NSString * const kTrackEventVideoLiveStart;
extern NSString * const kTrackEventVideoComplete;


@protocol PKVideoPlayerKit <NSObject>
@property (readonly, strong)    NSDictionary   *currentVideoInfo;
@property (readonly)            BOOL            fullScreenModeToggled;
@property (nonatomic)           BOOL            showStaticEndTime;
@property (nonatomic)           BOOL            allowPortraitFullscreen;
@property (nonatomic, readonly) BOOL            isPlaying;

- (void)playVideoWithTitle:(NSString *)title
                       URL:(NSURL *)url
                   videoID:(NSString *)videoID
                  shareURL:(NSURL *)shareURL
               isStreaming:(BOOL)streaming
          playInFullScreen:(BOOL)playInFullScreen;
- (void)showCannotFetchStreamError;
- (void)launchFullScreen;
- (void)minimizeVideo;
- (void)playPauseHandler;

@end
