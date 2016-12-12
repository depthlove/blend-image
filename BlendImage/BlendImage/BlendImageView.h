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
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>
#import "OpenGLESUtil.h"
#import <CoreVideo/CoreVideo.h>


static GLfloat vertex[8] = {
    1,1, //1
    -1,1, //0
    -1,-1, //2
    1,-1, //3
};

static GLfloat textureCoords[8] = {
    1,1, // 对应V1
    0,1, // 对应V0
    0,0, // 对应V2
    1,0 // 对应V3
};

static const char* shader_vsh =
"attribute vec4 position;"
"attribute vec2 textureCoord0;"

"varying vec2 v_textureCoord0;"

"void main(void) {"
"   gl_Position = position;"
"   v_textureCoord0 = textureCoord0.st;"
"}";

static const char* shader_fsh =
"precision mediump float;"

"varying vec2 v_textureCoord0;"

"uniform sampler2D texture0;"

"void main(void) {"
"   vec4 color0;"
"   color0 = texture2D(texture0, v_textureCoord0);"

"   gl_FragColor = color0;"
"}";


@interface BlendImageView : UIView

// 混合 2 张图片, blend two images
- (void)blendImageA:(UIImage *)imageA andImageB:(UIImage *)imageB;

// 摄像头数据，水印图片 watermark
- (void)blendPixelBuffer:(CVPixelBufferRef)pixelBuffer watermark:(UIImage *)watermark;

@end
