//
//  PKViewController.m
//  PKVideoPlayer
//
//  Created by zhongsheng on 13-4-9.
//  Copyright (c) 2013年 icePhone. All rights reserved.
//

#import "PKViewController.h"
#import "PKVideoPlayerViewController.h"

@interface PKViewController ()

@end

@implementation PKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(120, 200, 50, 50)];
    btn.backgroundColor = [UIColor grayColor];
    [btn setTitle:@"play" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)play
{
    PKVideoPlayerViewController *videoVC = [PKVideoPlayerViewController videoPlayerWithContainingViewController:self
                                                                                                optionalTopView:nil
                                                                                        hideTopViewWithControls:NO];
    
    //[self addChildViewController:videoVC];
    //[self.view addSubview:videoVC.view];
    [self presentViewController:videoVC animated:YES completion:^{        
        NSURL *url = [NSURL URLWithString:@"http://v.youku.com/player/getM3U8/vid/XMzA1NDE1MjU2/v.m3u8"];
        [videoVC playVideoWithTitle:@"Title" URL:url videoID:nil shareURL:nil isStreaming:NO playInFullScreen:YES];
    }];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
