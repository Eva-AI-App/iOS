//
//  NYCubismManager.h
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import <Foundation/Foundation.h>
@class NYLDRenderStageVC;

NS_ASSUME_NONNULL_BEGIN
/// Manage Live2D SDK
@interface NYLDSDKManager : NSObject

@property (nonatomic, strong) NYLDRenderStageVC *stageVC;
@property (nonatomic, assign, readonly) BOOL isSuspend;

+ (instancetype)shared;
/// init
+ (void)setup;

/// Suspend when background
+ (void)suspend;

/// resume when foreground
+ (void)resume;

@end

NS_ASSUME_NONNULL_END
