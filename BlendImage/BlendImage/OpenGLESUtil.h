//
//  OpenGLESUtil.h
//  BlendImage
//
//  Created by suntongmian on 16/9/30.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#ifndef OpenGLESUtil_h
#define OpenGLESUtil_h

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#ifdef DEBUG
#define DLog(...) printf(__VA_ARGS__);
#else
#define DLog(...) {}
#endif

#define BUFFER_OFFSET(i) ((void*)(i))
#define BUFFER_OFFSET_POSITION BUFFER_OFFSET(0)
#define BUFFER_OFFSET_TEXTURE  BUFFER_OFFSET(8)
#define BUFFER_SIZE_POSITION 2
#define BUFFER_SIZE_TEXTURE  2
#define BUFFER_STRIDE (sizeof(float) * 4)

#ifdef DEBUG
#define GL_ERRORS(line) { GLenum glerr; while((glerr = glGetError())) {\
switch(glerr)\
{\
case GL_NO_ERROR:\
break;\
case GL_INVALID_ENUM:\
DLog("OGL(" __FILE__ "):: %d: Invalid Enum\n", line );\
break;\
case GL_INVALID_VALUE:\
DLog("OGL(" __FILE__ "):: %d: Invalid Value\n", line );\
break;\
case GL_INVALID_OPERATION:\
DLog("OGL(" __FILE__ "):: %d: Invalid Operation\n", line );\
break;\
case GL_OUT_OF_MEMORY:\
DLog("OGL(" __FILE__ "):: %d: Out of Memory\n", line );\
break;\
} } }

#define GL_FRAMEBUFFER_STATUS(line) { GLenum status; status = glCheckFramebufferStatus(GL_FRAMEBUFFER); {\
switch(status)\
{\
case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:\
DLog("OGL(" __FILE__ "):: %d: Incomplete attachment\n", line);\
break;\
case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:\
DLog("OGL(" __FILE__ "):: %d: Incomplete dimensions\n", line);\
break;\
case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:\
DLog("OGL(" __FILE__ "):: %d: Incomplete missing attachment\n", line);\
break;\
case GL_FRAMEBUFFER_UNSUPPORTED:\
DLog("OGL(" __FILE__ "):: %d: Framebuffer combination unsupported\n",line);\
break;\
} } }

#else
#define GL_ERRORS(line)
#define GL_FRAMEBUFFER_STATUS(line)
#endif


static inline GLuint compile_shader(GLuint type, const char * source)
{
    
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    
#ifdef DEBUG
    if (!compiled) {
        GLint length;
        char *log;
        
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        
        log = (char*)malloc((size_t)(length));
        glGetShaderInfoLog(shader, length, &length, &log[0]);
        DLog("%s compilation error: %s\n", (type == GL_VERTEX_SHADER ? "GL_VERTEX_SHADER" : "GL_FRAGMENT_SHADER"), log);
        free(log);
        
        return 0;
    }
#endif
    
    
    return shader;
}

static inline GLuint build_program(const char * vertex, const char * fragment)
{
    GLuint  vshad,
    fshad,
    p;
    
    GLint   len;
#ifdef DEBUG
    char*   log;
#endif
    
    vshad = compile_shader(GL_VERTEX_SHADER, vertex);
    fshad = compile_shader(GL_FRAGMENT_SHADER, fragment);
    
    p = glCreateProgram();
    glAttachShader(p, vshad);
    glAttachShader(p, fshad);
    glLinkProgram(p);
    glGetProgramiv(p,GL_INFO_LOG_LENGTH, &len);
    
    
#ifdef DEBUG
    if(len) {
        log = (char*)malloc ( (size_t)(len) ) ;
        
        glGetProgramInfoLog(p, len, &len, log);
        
        DLog("program log: %s\n", log);
        
        free(log);
    }
#endif
    
    
    glDeleteShader(vshad);
    glDeleteShader(fshad);
    return p;
}

#endif /* OpenGLESUtil_h */
