//
//  NYGLTextureLoader.h
//  Live2DSDK
//
//  Created by niyao on 4/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NYGLTextureLoader : NSObject

- (instancetype)initWithImagePath:(NSString *)imagePath;
- (instancetype)initWithImageBundle:(NSBundle *)bundle imageName:(NSString *)name ext:(NSString *)ext inDirectory:(NSString *)inDirectory;
- (void)renderGLTexture;
@end

NS_ASSUME_NONNULL_END
