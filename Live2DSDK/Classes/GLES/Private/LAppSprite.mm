/**
 * Copyright(c) Live2D Inc. All rights reserved.
 *
 * Use of this source code is governed by the Live2D Open Software license
 * that can be found at https://www.live2d.com/eula/live2d-open-software-license-agreement_en.html.
 */

#import <Foundation/Foundation.h>
#import "LAppSprite.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "NYCommon.h"
#import "NYLDModelManager.h"
#define BUFFER_OFFSET(bytes) ((GLubyte *)NULL + (bytes))


@interface LAppSprite() {
    GLuint vertexBufferObject;  /**< position, color.... */
    GLuint elementBufferObject; /**< index */
}

@property (nonatomic, readwrite) GLuint textureId; // テクスチャID
@property (nonatomic) SpriteRect rect; // 矩形
@property (nonatomic) GLuint vertexBufferId;
@property (nonatomic) GLuint fragmentBufferId;
@property (nonatomic, assign) int mCount;

@end

@implementation LAppSprite
@synthesize baseEffect;

- (id)initWithImageName:(NSString *)imageName {
    self = [super self];

    if(self != nil) {
        _spriteColorR = _spriteColorG = _spriteColorB = _spriteColorA = 1.0f;
        NSString *filePath = [NYLDModelManager.shared.modelBundle pathForResource:imageName ofType:@"png" inDirectory:@"Background"];
        
        //GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
       
        // 创建 CIImage
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        CIImage *outputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSDictionary *imageOptions = @{
                kCIImageColorSpace: (__bridge id)colorSpace,
                kCIImageApplyOrientationProperty: @YES
            };
        // 创建 CIContext
        CIContext *context = [[CIContext alloc] initWithOptions:imageOptions];

        // 渲染为 CGImage，使用 kCIFormatARGB8 格式
        
        CGImageRef pixelData = [context createCGImage:outputImage
                                             fromRect:outputImage.extent
                                               format:kCIFormatARGB8
                                           colorSpace:colorSpace];

        // 释放资源
        CGColorSpaceRelease(colorSpace);
        NSError *error = nil;
        
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:pixelData options:options error:&error];
        //着色器
        
        if (error) {
            NYLog(@"GLKTextureInfo Error filePath: %@", filePath);
            NYLog(@"GLKTextureInfo Error: %@", error);
        }
        
        self.baseEffect = [[GLKBaseEffect alloc] init];
        self.baseEffect.useConstantColor = GL_TRUE;
        self.baseEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
        self.baseEffect.texture2d0.enabled = GL_TRUE;
        self.baseEffect.texture2d0.name = textureInfo.name;
    }


    return self;
}

- (void)updateBackgroundImagePath:(NSString *)filePath {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @(1),
                             GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath
                                                                      options:options error:nil];
    self.baseEffect.texture2d0.name = textureInfo.name;
}

- (void)renderBackgroundImageTexture {
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    GLfloat squareVertexData[] =
    {
        1, -1, 0.0f,    1.0f, 0.0f, //右下
        -1, 1, 0.0f,    0.0f, 1.0f, //左上
        -1, -1, 0.0f,   0.0f, 0.0f, //左下
        1, 1, -0.0f,    1.0f, 1.0f, //右上
    };
    
    //顶点索引
    GLuint indices[] =
    {
        0, 1, 2,
        1, 3, 0
    };
    self.mCount = sizeof(indices) / sizeof(GLuint);
    
    [self deleteBuffers];
    
    //顶点数据缓存
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    
    glGenBuffers(1, &elementBufferObject);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    
    //启动着色器
    [self.baseEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);

}

- (void)deleteBuffers {
    if (vertexBufferObject != 0) {
        glDeleteBuffers(1, &vertexBufferObject);
        NYLog(@"Prepare to delete buffer: %d", vertexBufferObject);
    }
    if (elementBufferObject != 0) {
        glDeleteBuffers(1, &elementBufferObject);
        NYLog(@"Prepare to delete buffer: %d", elementBufferObject);
    }
}


- (bool)isHit:(float)pointX PointY:(float)pointY
{
    return (pointX >= _rect.left && pointX <= _rect.right &&
            pointY >= _rect.down && pointY <= _rect.up);
}

- (void)SetColor:(float)r g:(float)g b:(float)b a:(float)a
{
    self.baseEffect.constantColor = GLKVector4Make(r, g, b, a);

    _spriteColorR = r;
    _spriteColorG = g;
    _spriteColorB = b;
    _spriteColorA = a;
}

@end

