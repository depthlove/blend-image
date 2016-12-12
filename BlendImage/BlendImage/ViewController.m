//
//  ViewController.m
//  BlendImage
//
//  Created by suntongmian on 16/9/30.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#import "ViewController.h"
#import "BlendImageView.h"
#import "Camera.h"

@interface ViewController () <CameraDelegate>

@end

@implementation ViewController
{
    BlendImageView *blendImageView;
    
    Camera *camera;
    
    UIImage *watermark;
    
    UIButton *toggleCameraButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    blendImageView = [[BlendImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:blendImageView];
    
#if 0
    // 混合 2 张图片，blend two images
    UIImage *imageA = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"flower" ofType:@"png"]];
    UIImage *imageB = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"horse" ofType:@"png"]];

    [blendImageView blendImageA:imageA andImageB:imageB];
    
#else
    // 混合摄像头采集的视频数据，水印，blend camera video，watermark
    CGSize videoSize = CGSizeMake(480, 640);
    int fps = 20;
    
    camera = [[Camera alloc] init];
    [camera setupCameraFPS:fps useFront:false useInterfaceOrientation:YES sessionPreset:AVCaptureSessionPreset640x480 callbackBlock:nil];
    camera.delegate = self;
    
    watermark = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"horse" ofType:@"png"]];
    
    toggleCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    toggleCameraButton.frame = CGRectMake(90, 90, 100, 45);
    [toggleCameraButton setTitle:@"切换" forState:UIControlStateNormal];
    [toggleCameraButton addTarget:self action:@selector(toggleCamereButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggleCameraButton];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)toggleCamereButtonEvent:(id)sender {
    [camera setCameraState: ! [camera cameraState]];
}

#pragma mark -- PLCameraDelegate methods
- (void)cameraOutput:(CMSampleBufferRef)sampleBuffer {
    NSLog(@"%s", __FUNCTION__);
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    [blendImageView blendPixelBuffer:pixelBuffer watermark:watermark];
}

@end
