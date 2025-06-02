//
//  RenderManager.h
//  Live2DSDK
//
//  Created by NY on 2025/3/7.
//

#import <Foundation/Foundation.h>

@class LAppTextureManager;
NS_ASSUME_NONNULL_BEGIN

@interface RenderManager : NSObject

@property (strong, nonatomic) UIViewController *viewController;
@property (nonatomic, readonly, getter=getTextureManager) LAppTextureManager *textureManager;
+ (instancetype)shared;

+ (BOOL)applicationDidFinishLaunching;

+ (void)applicationDidEnterBackground;

+ (void)applicationWillEnterForeground;

@end

NS_ASSUME_NONNULL_END
