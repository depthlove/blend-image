//
//  BlendImageView.m
//  BlendImage
//
//  Created by suntongmian on 16/9/30.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#import "BlendImageView.h"

@implementation BlendImageView
{
    CAEAGLLayer *_glLayer;
    EAGLContext *_glContext;
    
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _glProgram;
    GLuint _positionSlot;
    GLuint _textureCoordsSlot;
    GLuint _textureSlot;
    
    GLuint _vertexBuffer;
    GLuint _textureCoordBuffer;
    
    UIImage *_imageA;
    UIImage *_imageB;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _glLayer = (CAEAGLLayer *)self.layer;
    _glLayer.opaque = YES;
}

- (void)setupContext {
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glContext];
}

- (void)setupRenderBuffer {
    // 先要renderbuffer，然后framebuffer，顺序不能互换。
    
    // OpenGlES共有三种：colorBuffer，depthBuffer，stencilBuffer。
    
    // 生成一个renderBuffer，id是colorRenderBuffer
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 设置为当前renderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //为color renderbuffer 分配存储空间
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
}

- (void)setupFrameBuffer {
    // FBO用于管理colorRenderBuffer，离屏渲染
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)loadShader {
    _glProgram = build_program(shader_vsh, shader_fsh);
    glUseProgram(_glProgram);
    
    // 需要三个参数, 跟Shader中的一一对应。
    // Position: 将颜色放置在CAEAGLLayer上的哪个位置
    // TextureCoords: 图像的纹理坐标，即图像纹理的哪一块颜色
    // Texture: 图像的纹理
    _positionSlot = glGetAttribLocation(_glProgram, "Position");
    _textureCoordsSlot = glGetAttribLocation(_glProgram, "TextureCoords");
    _textureSlot = glGetUniformLocation(_glProgram, "Texture");
}

- (void)setupOpenGLES {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self loadShader];
}

- (void)setupVBOs {
    // 1. 加载顶点坐标数据
    
    // 第一步.在GPU 中先申请一个内存标识
    glGenBuffers(1, &_vertexBuffer);
    // 第二步.让这个标识去绑定一个内存区域，但是此时，这个内存没有大小.
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    // 第三步.根据顶点数组的大小，开辟内存空间，并将数据加载到内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), &vertex, GL_STATIC_DRAW);
    // 第四步 .启用这块内存，标记为位置
    glEnableVertexAttribArray(_positionSlot);
    // 第五步.告诉GPU 顶点数据在内存中的格式是怎么样的，应该如何去使用
    //    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 8, NULL);
    
    // 2. 加载纹理坐标数据
    
    // 第一步.在GPU 中先申请一个内存标识
    glGenBuffers(1, &_textureCoordBuffer);
    // 第二步.让这个标识去绑定一个内存区域，但是此时，这个内存没有大小.
    glBindBuffer(GL_ARRAY_BUFFER, _textureCoordBuffer);
    // 第三步.根据顶点数组的大小，开辟内存空间，并将数据加载到内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
    // 第四步 .启用这块内存，标记为位置
    glEnableVertexAttribArray(_textureCoordsSlot);
    // 第五步.告诉GPU 顶点数据在内存中的格式是怎么样的，应该如何去使用
    //    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));
    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, 8, NULL);
}

// 获取图片的像素数据
- (void *)getImageData:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    size_t imageWidth = CGImageGetWidth(imageRef);
    size_t imageHeight = CGImageGetHeight(imageRef);
    GLubyte *imageData = (GLubyte *)malloc(imageWidth * imageHeight * 4);
    memset(imageData, 0, imageWidth * imageHeight * 4);
    CGContextRef imageContextRef = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, imageWidth*4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(imageContextRef, 0, imageHeight);
    CGContextScaleCTM(imageContextRef, 1.0, -1.0);
    CGContextDrawImage(imageContextRef, CGRectMake(0.0, 0.0, (CGFloat)imageWidth, (CGFloat)imageHeight), imageRef);
    CGContextRelease(imageContextRef);
    return  imageData;
}

// 加载图片的像素数据
- (void)loadTexture {
    //第一步.将我们着色器中的纹理采样器和纹理区域0进行关联.
    glUniform1i(_textureSlot, 0); // 0 代表GL_TEXTURE0
    GLuint tex1;
    //第二步.激活纹理区域0
    glActiveTexture(GL_TEXTURE0);
    //第三步. 申请内存标识
    glGenTextures(1, &tex1);
    //第四步. 将内存和激活的纹理区域绑定
    glBindTexture(GL_TEXTURE_2D,  tex1);
    
    UIImage *image = _imageA; // 指向传入的图片
    GLubyte *imageData = [self getImageData:image];
    //第五步.将图片像素数据，加载到纹理区域0 中去
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA , image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    //第六步.设置图片在渲染时的一些配置
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)render {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -- Publish methods

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupOpenGLES];
        [self setupVBOs];
    }
    return self;
}

- (void)dealloc {
    _glContext = nil;
}

// 渲染传入的图片
- (void)blendImageA:(UIImage *)imageA andImageB:(UIImage *)imageB {
    _imageA = imageA;
    
    [self loadTexture];
    [self render];
}

@end
