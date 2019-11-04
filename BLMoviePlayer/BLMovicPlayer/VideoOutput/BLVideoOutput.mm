//
//  BLVideoOutput.m
//  BLVideoDecode
//
//  Created by Simon on 2019/10/17.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "BLVideoOutput.h"
#import <OpenGLES/ES2/gl.h>

#define STRINGIZER1(x) #x
#define STRINGIZER2(x) STRINGIZER1(x)
#define SHADER_STRING(x) @ STRINGIZER2(x)

enum {
    ATTRIBUTE_VERTEX_POSITION,  // 顶点索引
    ATTRIBUTE_VERTEX_TEXCOORD,  // 纹理索引
    ATTRIBUTE_TOTAL_NUM_COUNT
};

enum {
    UNIFORM_FRAGMENT_S_TEXCOORD_Y,
    UNIFORM_FRAGMENT_S_TEXCOORD_U,
    UNIFORM_FRAGMENT_S_TEXCOORD_V,
    UNIFORM_TOTAL_NUM_COUNT
};

GLint uniform[UNIFORM_TOTAL_NUM_COUNT];

NSString *const vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 varying vec2 v_texcoord;
 void main () {
    gl_Position = position;
    v_texcoord = texcoord.xy;
 }
 );

NSString *const fragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 
 uniform sampler2D s_texcoord_y;
 uniform sampler2D s_texcoord_u;
 uniform sampler2D s_texcoord_v;
 void main () {
    highp float y = texture2D(s_texcoord_y, v_texcoord).r;
    highp float u = texture2D(s_texcoord_u, v_texcoord).r - 0.5;
    highp float v = texture2D(s_texcoord_v, v_texcoord).r - 0.5;
    
    highp float r = y +             1.402 * v;
    highp float g = y - 0.344 * u - 0.714 * v;
    highp float b = y + 1.772 * u;
    
    gl_FragColor = vec4(r,g,b,1.0);
 }
 );

@interface BLVideoOutput () {
    GLuint texture[3];
}

@property (nonatomic, strong) CAEAGLLayer *glLayer;
@property (nonatomic, strong) EAGLContext *glContext;

@property (nonatomic, assign) GLuint renderBuffer;
@property (nonatomic, assign) GLuint frameBuffer;
@property (nonatomic, assign) GLuint program;

@property (nonatomic, assign) GLint glWidth;
@property (nonatomic, assign) GLint glHeight;

@property (nonatomic, assign) BOOL perparReady;  // 是否准备好, 用来判断是否可以渲染

@end

@implementation BLVideoOutput

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)init {
    if (self = [super init]) {
        [self initilization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initilization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self initilization];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initilization];
}

- (void)initilization {
    // 环境初始化流程:
    //      1. Layer 设置
    //      2. Context 设置
    //      3. FrameBuffer&RenderBuffer设置
    //      4. Program&Shader 设置
    //      5. 顶点&纹理 初始化设置
    _perparReady = [self setupLayer] && [self setupContext];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupGL];
}

#pragma mark - public method
- (void)displayVideoFrame:(BLVideoPacket *)vFrame {
    
    [EAGLContext setCurrentContext:_glContext];
    
    // 渲染流程:
    //      0. 重新绑定FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    //      1. UseProgram
    glUseProgram(_program);
    //      2. 窗口&窗口背景&深度设置
    glViewport(0, 0, _glWidth, _glHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //      3. 纹理数据填充
    [self uploadTexture:vFrame frameWidth:vFrame->width frameHeight:vFrame->height];
    //      4. 设置顶点&纹理坐标
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    glVertexAttribPointer(ATTRIBUTE_VERTEX_POSITION, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer(ATTRIBUTE_VERTEX_TEXCOORD, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture[0]);
    glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_Y], 0);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture[1]);
    glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_U], 1);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture[2]);
    glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_V], 2);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //      5. 重新绑定RenderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    //      6. 渲染
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)uploadTexture:(BLVideoPacket *)vFrame frameWidth:(NSUInteger)width frameHeight:(NSUInteger)height {
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    const UInt8 *pix[3] = {vFrame->luma, vFrame->chromaB, vFrame->chromaR};
    const NSUInteger widths[3] = {width, width/2, width/2};
    const NSUInteger heights[3] = {height, height/2, height/2};
    
    for (int i = 0; i < 3; i ++) {
        glBindTexture(GL_TEXTURE_2D, texture[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (int)widths[i], (int)heights[i], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pix[i]);
    }
}

#pragma mark - setup method
- (void)setupGL {
    if (!_perparReady) {
        NSLog(@"程序准备失败, 请查看问题！");
        return;
    }
    
    if ((_perparReady = [self loadShaders]) == GL_TRUE) {
        glUseProgram(_program);
        
        // 设置默认的属性
        glVertexAttribPointer(ATTRIBUTE_VERTEX_POSITION, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, 0);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX_POSITION);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, 0);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX_TEXCOORD);
        
        glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_Y], 0);
        glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_U], 1);
        glUniform1i(uniform[UNIFORM_FRAGMENT_S_TEXCOORD_V], 2);
        
        // 设置纹理属性
        glGenTextures(3, texture);
        for (int i = 0; i < 3; i ++) {
            glBindTexture(GL_TEXTURE_2D, texture[i]);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _glWidth, _glHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
        }
    }
}

- (BOOL)setupLayer {
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    _glLayer = (CAEAGLLayer *)self.layer;
    _glLayer.opaque = NO;
    _glLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking : @(NO),
        kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
    };
    return _glLayer != nil;
}

- (BOOL)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _glContext = [[EAGLContext alloc] initWithAPI:api];
    
    BOOL isReady = YES;;
    if (!_glContext) {
        NSLog(@"当前版本不支持OpenGLES 2.0协议");
        isReady = NO;
    }
    if (![EAGLContext setCurrentContext:_glContext]) {
        NSLog(@"设置当前OpenGLES上下文失败");
        isReady = NO;
    }
    return isReady;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    _renderBuffer = buffer;
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_glWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_glHeight);
}

- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    glBindFramebuffer(GL_FRAMEBUFFER, buffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    _frameBuffer = buffer;
}

- (BOOL)loadShaders {
    _program = glCreateProgram();
    GLuint vertexShader, fragmentShader;
    
    BOOL loadSuccess;
    
    loadSuccess = [self compileShader:&vertexShader type:GL_VERTEX_SHADER sourceString:vertexShaderString];
    loadSuccess = [self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER sourceString:fragmentShaderString];
    
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
    // 绑定顶点索引, 必须在链接之前
    glBindAttribLocation(_program, ATTRIBUTE_VERTEX_POSITION, "position");
    glBindAttribLocation(_program, ATTRIBUTE_VERTEX_TEXCOORD, "texcoord");
    
    glLinkProgram(_program);
    loadSuccess = [self vaildProgram];
    
    // 获取片元索引, 必须再链接之后
    uniform[UNIFORM_FRAGMENT_S_TEXCOORD_Y] = glGetUniformLocation(_program, "s_texcoord_y");
    uniform[UNIFORM_FRAGMENT_S_TEXCOORD_U] = glGetUniformLocation(_program, "s_texcoord_u");
    uniform[UNIFORM_FRAGMENT_S_TEXCOORD_V] = glGetUniformLocation(_program, "s_texcoord_v");

    if (vertexShader) {
        glDetachShader(_program, vertexShader);
        glDeleteShader(vertexShader);
    }
    if (fragmentShader) {
        glDetachShader(_program, fragmentShader);
        glDeleteShader(fragmentShader);
    }
    
    return loadSuccess;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type sourceString:(NSString *)sourceString {
    
    const GLchar *source = [sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#ifdef DEBUG
    // 校验CompileShader准确性
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        char message[256];
        glGetShaderInfoLog(*shader, logLength, &logLength, &message[0]);
        NSLog(@"[Shader Error] %s", message);
    }
    
#endif
    
    GLint compileStatus;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &compileStatus);
    
    return compileStatus == GL_TRUE;
}

#pragma mark - private method

- (BOOL)vaildProgram {
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar message[256];
        glGetProgramInfoLog(_program, logLength, &logLength, &message[0]);
        NSLog(@"[Program Error] %s", message);
    }
#endif
    
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    return linkSuccess == GL_TRUE;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
