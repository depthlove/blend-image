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
//"attribute vec2 textureCoord1;"

"varying vec2 v_textureCoord0;"
//"varying vec2 v_textureCoord1;"

"void main(void) {"
"   gl_Position = position;"

"   v_textureCoord0 = textureCoord0.st;"
//"   v_textureCoord1 = textureCoord1.st;"
"}";

static const char* shader_fsh =
"precision mediump float;"

"varying vec2 v_textureCoord0;"
//"varying vec2 v_textureCoord1;"

"uniform sampler2D texture0;"
//"uniform sampler2D texture1;"

"void main(void) {"
"   vec4 color0;"
//"   vec4 color1;"

"   color0 = texture2D(texture0, v_textureCoord0);"
//"   color1 = texture2D(texture1, v_textureCoord1);"

//"   gl_FragColor = mix(color0, color1, color1.a);"
"   gl_FragColor = color0;"
"}";


@interface BlendImageView : UIView

- (void)blendImageA:(UIImage *)imageA andImageB:(UIImage *)imageB;

@end
