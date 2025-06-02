//
//  NYGLTextureLoader.m
//  Live2DSDK
//
//  Created by niyao on 4/5/25.
//

#import "NYGLTextureLoader.h"

#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import "NYCommon.h"

@interface NYGLTextureLoader ()

@property (nonatomic, strong) NSString *imagePath;

@end

@implementation NYGLTextureLoader {
    GLuint _textureID;      // Texture ID
    GLKBaseEffect *_effect; // Shader effect
}



- (instancetype)initWithImageBundle:(NSBundle *)bundle imageName:(NSString *)name ext:(NSString *)ext inDirectory:(NSString *)inDirectory {
    return  [self initWithImagePath:[bundle  pathForResource:name ofType:ext inDirectory:inDirectory]];
}
- (instancetype)initWithImagePath:(NSString *)imagePath
{
    self = [super init];
    if (self) {
        
        // 1️⃣ Initialize OpenGL ES context
//        EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//        if (!context) {
//            NSLog(@"Failed to create OpenGL ES context");
//            return;
//        }
//
//        // Set the context
//        GLKView *view = (GLKView *)self.view;
//        view.context = context;
//        view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
//        [EAGLContext setCurrentContext:context];

        // Enable depth test
        glEnable(GL_DEPTH_TEST);

        // 2️⃣ Load texture manually
        [self loadTextureWithImagePath:imagePath];

        // 3️⃣ Initialize GLKBaseEffect for rendering
        _effect = [[GLKBaseEffect alloc] init];
        _effect.texture2d0.enabled = GL_TRUE;
        _effect.texture2d0.name = _textureID;
    }
    return self;
}


- (void)loadTextureWithImagePath:(NSString *)imagePath {
    if (imagePath == nil) {
        return;
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (!image) {
        NYLog(@"Error: Image not found!");
        return;
    }

    CGImageRef imageRef = image.CGImage;
    size_t width = UIScreen.mainScreen.bounds.size.width * 2; //CGImageGetWidth(imageRef);
    size_t height = UIScreen.mainScreen.bounds.size.height * 2;//CGImageGetHeight(imageRef);

    // Allocate memory for image data
    GLubyte *imageData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));

    // ✅ FIX: Use `CGColorSpaceCreateDeviceRGB()` instead of `CGImageGetColorSpace(imageRef)`
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Create a bitmap context to extract pixel data
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);

    if (!context) {
        NSLog(@"Error: Failed to create CGBitmapContext");
        free(imageData);
        CGColorSpaceRelease(colorSpace);
        return;
    }

    // Draw the image into the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);

    // Release context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Generate and bind OpenGL texture
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);

    // Set texture parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Upload texture data to OpenGL
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    // Free memory
    free(imageData);
}

// **🔹 Render the Texture**
- (void)renderGLTexture {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [_effect prepareToDraw];

    // 🔥 FULL SCREEN VERTICES (from -1 to 1)
    GLfloat fullScreenVertices[] = {
        -1.0f, -1.0f,  0.0f,  // Bottom-left
         1.0f, -1.0f,  0.0f,  // Bottom-right
        -1.0f,  1.0f,  0.0f,  // Top-left
         1.0f,  1.0f,  0.0f   // Top-right
    };

    // Texture coordinates (no change)
    GLfloat textureCoords[] = {
        0.0f, 1.0f,  // Bottom-left
        1.0f, 1.0f,  // Bottom-right
        0.0f, 0.0f,  // Top-left
        1.0f, 0.0f   // Top-right
    };

    // Enable and set vertex attributes
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, fullScreenVertices);

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);

    // Draw quad
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // Disable attributes
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}
@end
