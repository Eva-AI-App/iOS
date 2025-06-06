//
//  NYLDRenderStageVC.m
//  Live2DSDK
//
//  Created by niyao on 3/26/25.
//

#import "NYLDRenderStageVC.h"
#import <math.h>
#import <string>
#import <QuartzCore/QuartzCore.h>
#import "CubismFramework.hpp"
#import <CubismMatrix44.hpp>
#import <CubismViewMatrix.hpp>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "NYLDModelManager.h"
#import "LAppSprite.h"
#import "TouchManager.h"
#import "LAppDefine.h"


#import "LAppPal.h"
#import "NYLDSDKManager.h"
#include "CubismOffscreenSurface_OpenGLES2.hpp"
#import "LAppModel.h"
#import "NYGLTextureLoader.h"

#define BUFFER_OFFSET(bytes) ((GLubyte *)NULL + (bytes))

using namespace std;
using namespace LAppDefine;


@interface NYLDRenderStageVC () 

@property (nonatomic, strong) NYGLTextureLoader *backgroundTexture;
@property (nonatomic) LAppSprite *renderSprite; //レンダリングターゲット描画用
@property (nonatomic) TouchManager *touchManager; ///< タッチマネージャー
@property (nonatomic) Csm::CubismMatrix44 *deviceToScreen;///< デバイスからスクリーンへの行列
@property (nonatomic) Csm::CubismViewMatrix *viewMatrix;

@property (nonatomic) Csm::Rendering::CubismOffscreenSurface_OpenGLES2 renderBuffer;

@end

@implementation NYLDRenderStageVC
@synthesize mOpenGLRun;

- (void)releaseView
{
    _renderBuffer.DestroyOffscreenSurface();

    _renderSprite = nil;

    GLKView *view = (GLKView*)self.view;

    view = nil;

    delete(_viewMatrix);
    _viewMatrix = nil;
    delete(_deviceToScreen);
    _deviceToScreen = nil;
    _touchManager = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication.sharedApplication setIdleTimerDisabled:NO];
    mOpenGLRun = true;
    NYLog(@"1");
    _anotherTarget = false;
    _spriteColorR = _spriteColorG = _spriteColorB = _spriteColorA = 1.0f;
    _clearColorR = _clearColorG = _clearColorB = 1.0f;
    _clearColorA = 0.0f;
    
  

    // タッチ関係のイベント管理
    _touchManager = [[TouchManager alloc]init];

    // デバイス座標からスクリーン座標に変換するための
    _deviceToScreen = new CubismMatrix44();

    // 画面の表示の拡大縮小や移動の変換を行う行列
    _viewMatrix = new CubismViewMatrix();

    [self initializeScreen];
    
    GLKView *view = (GLKView*)self.view;

    // GL描画周期を60FPSに設定
    self.preferredFramesPerSecond = 60;

    // OpenGL ES2を指定
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    // set context
    [EAGLContext setCurrentContext:view.context];

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    glGenBuffers(1, &_vertexBufferId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferId);

    glGenBuffers(1, &_fragmentBufferId);
    glBindBuffer(GL_ARRAY_BUFFER,  _fragmentBufferId);
    
    
    [self changeBackgroundWithImagePath:[NYLDModelManager backgroundDirFilePathsWithError:nil].firstObject];
    self.paused = false;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.paused = false;
}

- (void)initializeScreen
{
    NYLog(@"2");
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;

    // 縦サイズを基準とする
    float ratio = static_cast<float>(width) / static_cast<float>(height);
    float left = -ratio;
    float right = ratio;
    float bottom = ViewLogicalLeft;
    float top = ViewLogicalRight;

    // デバイスに対応する画面の範囲。 Xの左端, Xの右端, Yの下端, Yの上端
    _viewMatrix->SetScreenRect(left, right, bottom, top);
    _viewMatrix->Scale(ViewScale, ViewScale);

    _deviceToScreen->LoadIdentity(); // サイズが変わった際などリセット必須
    if (width > height)
    {
      float screenW = fabsf(right - left);
      _deviceToScreen->ScaleRelative(screenW / width, -screenW / width);
    }
    else
    {
      float screenH = fabsf(top - bottom);
      _deviceToScreen->ScaleRelative(screenH / height, -screenH / height);
    }
    _deviceToScreen->TranslateRelative(-width * 0.5f, -height * 0.5f);

    // 表示範囲の設定
    _viewMatrix->SetMaxScale(ViewMaxScale); // 限界拡大率
    _viewMatrix->SetMinScale(ViewMinScale); // 限界縮小率

    // 表示できる最大範囲
    _viewMatrix->SetMaxScreenRect(
                                  ViewLogicalMaxLeft,
                                  ViewLogicalMaxRight,
                                  ViewLogicalMaxBottom,
                                  ViewLogicalMaxTop
                                  );
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //時間更新
    LAppPal::UpdateTime();
    
    if(mOpenGLRun)
    {
        
        // 画面クリア
//        glClear(GL_COLOR_BUFFER_BIT);
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
//        [_back renderBackgroundImageTexture];
        [self.backgroundTexture renderGLTexture];

        
        NYLDModelManager *Live2DManager = [NYLDModelManager shared];
        [Live2DManager SetViewMatrix:_viewMatrix->_tr];
        [Live2DManager onUpdate];

        // 各モデルが持つ描画ターゲットをテクスチャとする場合はスプライトへの描画はここ
        if (_renderTarget == NYLDSelectTargetModelFrameBuffer && _renderSprite)
        {
            
            float uvVertex[] =
            {
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f,
            };

            for(csmUint32 i=0; i<[Live2DManager GetModelNum]; i++)
            {
//                LAppModel* model = [Live2DManager getModel:i];
//                float a = i < 1 ? 1.0f : model->GetOpacity(); // 片方のみ不透明度を取得できるようにする
//                [_renderSprite SetColor:1.0f g:1.0f b:1.0f a:a];
//
//                if (model)
//                {
//                    Csm::Rendering::CubismOffscreenSurface_OpenGLES2& useTarget = model->GetRenderBuffer();
//                    GLuint textureId = useTarget.GetColorBuffer();
//                    [_renderSprite renderImmidiate:_vertexBufferId fragmentBufferID:_fragmentBufferId TextureId:textureId uvArray:uvVertex];
//                }
            }
        }

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];

    [_touchManager touchesBegan:point.x DeciveY:point.y];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];

    float viewX = [self transformViewX:[_touchManager getX]];
    float viewY = [self transformViewY:[_touchManager getY]];

    [_touchManager touchesMoved:point.x DeviceY:point.y];
    
    [[NYLDModelManager shared] onDrag:viewX floatY:viewY];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NYLog(@"%@", touch.view);

    CGPoint point = [touch locationInView:self.view];
    float pointY = [self transformTapY:point.y];

    // タッチ終了
//    LAppLive2DManager* live2DManager = [LAppLive2DManager getInstance];
    NYLDModelManager *live2DManager = [NYLDModelManager shared];
    [live2DManager onDrag:0.0f floatY:0.0f];
    {
        // シングルタップ
        float getX = [_touchManager getX];// 論理座標変換した座標を取得。
        float getY = [_touchManager getY]; // 論理座標変換した座標を取得。
        float x = _deviceToScreen->TransformX(getX);
        float y = _deviceToScreen->TransformY(getY);

        if (DebugTouchLogEnable)
        {
            LAppPal::PrintLogLn("[APP]touchesEnded x:%.2f y:%.2f", x, y);
        }
        [live2DManager onTap:x floatY:y];
        
    }
    if (self.didEndTouchActionHandler) {
        self.didEndTouchActionHandler();
    }
}

- (float)transformViewX:(float)deviceX
{
    float screenX = _deviceToScreen->TransformX(deviceX); // 論理座標変換した座標を取得。
    return _viewMatrix->InvertTransformX(screenX); // 拡大、縮小、移動後の値。
}

- (float)transformViewY:(float)deviceY
{
    float screenY = _deviceToScreen->TransformY(deviceY); // 論理座標変換した座標を取得。
    return _viewMatrix->InvertTransformY(screenY); // 拡大、縮小、移動後の値。
}

- (float)transformScreenX:(float)deviceX
{
    return _deviceToScreen->TransformX(deviceX);
}

- (float)transformScreenY:(float)deviceY
{
    return _deviceToScreen->TransformY(deviceY);
}

- (float)transformTapY:(float)deviceY
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int height = screenRect.size.height;
    return deviceY * -1 + height;
}
//
//- (void)PreModelDraw:(LAppModel&)refModel
//{
//    NYLog(@"5");
//    // 別のレンダリングターゲットへ向けて描画する場合の使用するフレームバッファ
//    Csm::Rendering::CubismOffscreenSurface_OpenGLES2* useTarget = NULL;
//
//    if (_renderTarget != SelectTarget_None)
//    {// 別のレンダリングターゲットへ向けて描画する場合
//
//        // 使用するターゲット
//        useTarget = (_renderTarget == SelectTarget_ViewFrameBuffer) ? &_renderBuffer : &refModel.GetRenderBuffer();
//
//        if (!useTarget->IsValid())
//        {// 描画ターゲット内部未作成の場合はここで作成
//            CGRect screenRect = [[UIScreen mainScreen] nativeBounds];
//            int width = screenRect.size.width;
//            int height = screenRect.size.height;
//
//            // モデル描画キャンバス
//            useTarget->CreateOffscreenSurface(height, width);
//        }
//
//        // レンダリング開始
//        useTarget->BeginDraw();
//        useTarget->Clear(_clearColorR, _clearColorG, _clearColorB, _clearColorA); // 背景クリアカラー
//    }
//}
//
//- (void)PostModelDraw:(LAppModel&)refModel
//{
//    NYLog(@"6");
//    // 別のレンダリングターゲットへ向けて描画する場合の使用するフレームバッファ
//    Csm::Rendering::CubismOffscreenSurface_OpenGLES2* useTarget = NULL;
//
//    if (_renderTarget != SelectTarget_None)
//    {// 別のレンダリングターゲットへ向けて描画する場合
//
//        // 使用するターゲット
//        useTarget = (_renderTarget == SelectTarget_ViewFrameBuffer) ? &_renderBuffer : &refModel.GetRenderBuffer();
//
//        // レンダリング終了
//        useTarget->EndDraw();
//
//        // LAppViewの持つフレームバッファを使うなら、スプライトへの描画はここ
//        if (_renderTarget == SelectTarget_ViewFrameBuffer && _renderSprite)
//        {
//            float uvVertex[] =
//            {
//                0.0f, 0.0f,
//                1.0f, 0.0f,
//                0.0f, 1.0f,
//                1.0f, 1.0f,
//            };
//
//            float a = [self GetSpriteAlpha:0];
//            [_renderSprite SetColor:1.0f g:1.0f b:1.0f a:a];
//            [_renderSprite renderImmidiate:_vertexBufferId fragmentBufferID:_fragmentBufferId TextureId:useTarget->GetColorBuffer() uvArray:uvVertex];
//        }
//    }
//}

- (void)SwitchRenderingTarget:(NYLDSelectTarget)targetType
{
    _renderTarget = targetType;
}

- (void)SetRenderTargetClearColor:(float)r g:(float)g b:(float)b
{
    _clearColorR = r;
    _clearColorG = g;
    _clearColorB = b;
}

- (float)GetSpriteAlpha:(int)assign
{
    // assignの数値に応じて適当に決定
    float alpha = 0.25f + static_cast<float>(assign) * 0.5f; // サンプルとしてαに適当な差をつける
    if (alpha > 1.0f)
    {
        alpha = 1.0f;
    }
    if (alpha < 0.1f)
    {
        alpha = 0.1f;
    }

    return alpha;
}

- (void)changeBackgroundWithImagePath:(NSString *)imagePath {
    self.backgroundTexture = [[NYGLTextureLoader alloc] initWithImagePath:imagePath];
}

@end
