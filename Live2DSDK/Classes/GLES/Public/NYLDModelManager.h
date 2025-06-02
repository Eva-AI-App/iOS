//
//  NYLDModelManager.h
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import <Foundation/Foundation.h>
#import "NYCommon.h"

#import <GLKit/GLKit.h>
@class LAppTextureManager;


NS_ASSUME_NONNULL_BEGIN

/**
 * Live2D Model Manager
 */
@interface NYLDModelManager : NSObject

@property (nonatomic, strong, nullable) LAppTextureManager *textureManager;
@property (nonatomic, strong, readonly) NSBundle *modelBundle;
@property (nonatomic, assign, readonly) NSInteger sceneIndex;
@property (nonatomic, assign) float mouthOpenRate;

+ (instancetype)shared;

+ (void)setup;

+ (NSArray <NSString *> * _Nullable)modelJSONPaths;

+ (NSArray <NSString *> * _Nullable)modelAvatarPaths;

+ (NSString * _Nullable)backgroundDirWithError:(NSError ** _Nullable)error;

+ (NSArray<NSString *> * _Nullable )backgroundDirFilePathsWithError:(NSError ** _Nullable)error;

- (void)changeScene:(NSInteger)sceneIndex;


/**
 * @brief  現在のシーンで保持している全てのモデルを解放する
 */
- (void)releaseAllModel;

/**
 * @brief   画面をドラッグしたときの処理
 *
 * @param[in]   x   画面のX座標
 * @param[in]   y   画面のY座標
 */
- (void)onDrag:(float)x floatY:(float)y;

/**
 * @brief   画面をタップしたときの処理
 *
 * @param[in]   x   画面のX座標
 * @param[in]   y   画面のY座標
 */
- (void)onTap:(float)x floatY:(float)y;

/**
 * @brief   画面を更新するときの処理
 *          モデルの更新処理および描画処理を行う
 */
- (void)onUpdate;

/**
 * @brief   次のシーンに切り替える
 *          サンプルアプリケーションではモデルセットの切り替えを行う。
 */
- (void)nextScene;


/**
 * @brief   モデル個数を得る
 * @return  所持モデル個数
 */
- (unsigned int)GetModelNum;

/**
 * @brief   viewMatrixをセットする
 */
- (void)SetViewMatrix:(float *)m;


- (float)getModelOpacityWithIndex:(int)index;

- (BOOL)modelExistsWithIndex:(int)index;

- (GLuint)modelTextureIdWithIndex:(int)index;
@end

NS_ASSUME_NONNULL_END
