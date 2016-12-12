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
    
    GLuint _glProgram;

    GLuint texNames[2];

    GLuint _colorRenderBuffer;
    GLuint _vertexBuffer;
    GLuint _frameBuffer;
    GLuint _textureCoordBuffer0;
    
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

- (void)setupOpenGLES {
    [self setupLayer];
    [self setupContext];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self loadShader];
    [self setupVBOs];
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)loadShader {
    _glProgram = build_program(shader_vsh, shader_fsh);
    glUseProgram(_glProgram);
    
    GLint u_texture0 = glGetUniformLocation(_glProgram, "texture0");
    glUniform1i(u_texture0, 0);
}

- (void)setupVBOs {
    GLint position = glGetAttribLocation(_glProgram, "position");
    GLint textureCoord0 = glGetAttribLocation(_glProgram, "textureCoord0");

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), &vertex, GL_STATIC_DRAW);
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));
    
    glGenBuffers(1, &_textureCoordBuffer0);
    glBindBuffer(GL_ARRAY_BUFFER, _textureCoordBuffer0);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(textureCoord0);
    glVertexAttribPointer(textureCoord0, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));
}

- (void)loadTexture {
    // ---- imageA
    glActiveTexture(GL_TEXTURE0);

    glGenTextures(1, &texNames[0]);
    glBindTexture(GL_TEXTURE_2D,  texNames[0]);
    UIImage *imageA = _imageA;
    GLubyte *imageAData = [self getImageData:_imageA];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA , imageA.size.width, imageA.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageAData);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    free(imageAData); // free memory
    
    // ---- imageB
    glGenTextures(1, &texNames[1]);
    glBindTexture(GL_TEXTURE_2D,  texNames[1]);
    UIImage *imageB = _imageB;
    GLubyte *imageBData = [self getImageData:_imageB];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA , imageB.size.width, imageB.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageBData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    free(imageBData); // free memory
}

- (void)render {
    [EAGLContext setCurrentContext:_glContext];

    // imageA
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texNames[0]);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, _imageA.size.width, _imageA.size.height);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    
    // imageB
    glBindTexture(GL_TEXTURE_2D, texNames[1]);
    
    glViewport(10, 20, _imageB.size.width, _imageB.size.height);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

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

#pragma mark -- Publish methods

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupOpenGLES];
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    return self;
}

- (void)dealloc {
    _glContext = nil;
}

// 渲染传入的图片
- (void)blendImageA:(UIImage *)imageA andImageB:(UIImage *)imageB {
    _imageA = imageA;
    _imageB = imageB;
    
    [self loadTexture];
    [self render];
}

@end
