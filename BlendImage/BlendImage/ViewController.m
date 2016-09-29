//
//  ViewController.m
//  BlendImage
//
//  Created by suntongmian on 16/9/30.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#import "ViewController.h"
#import "BlendImageView.h"

@interface ViewController ()

@end

@implementation ViewController
{
    BlendImageView *blendImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    blendImageView = [[BlendImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:blendImageView];
    
    UIImage *imageA = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"word" ofType:@"png"]];
    UIImage *imageB = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"rose" ofType:@"png"]];

    [blendImageView blendImageA:imageA andImageB:imageB];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
