//
//  BlendImageView.h
//  BlendImage
//
//  Created by suntongmian on 16/9/30.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>
#import "OpenGLESUtil.h"

@interface BlendImageView : UIView

- (void)blendImageA:(UIImage *)imageA andImageB:(UIImage *)imageB;

@end
