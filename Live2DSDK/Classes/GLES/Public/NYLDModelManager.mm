//
//  NYLDModelManager.m
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import "NYLDModelManager.h"
#import <CubismFramework.hpp>
#import <Foundation/Foundation.h>
#import <CubismMatrix44.hpp>
#import <csmVector.hpp>
#import <csmString.hpp>
#import "LAppModel.h"
#import <CubismUserModel.hpp>
#import "LAppTextureManager.h"
#import <string.h>
#import <stdlib.h>

#import "LAppModel.h"
#import "LAppDefine.h"
#import "LAppPal.h"

NSErrorDomain const BundleErrorDomain = @"NYLDModelManagerBundleErrorDomain";

void NYLDBeganMotion(Csm::ACubismMotion* motion)
{
    LAppPal::PrintLogLn("Motion began: %x", motion);
}

void NYLDFinishedMotion(Csm::ACubismMotion* motion)
{
    LAppPal::PrintLogLn("Motion Finished: %x", motion);
}

@interface NYLDModelManager()

@property (nonatomic) Csm::CubismMatrix44 *viewMatrix; //モデル描画に用いるView行列
@property (nonatomic) Csm::csmVector<LAppModel*> models; //モデルインスタンスのコンテナ

@property (nonatomic) Csm::csmVector<Csm::csmString> modelDir; ///< モデルディレクトリ名のコンテナ

@property (nonatomic, strong, readwrite) NSBundle *modelBundle;
@property (nonatomic, strong, readwrite) NSString *resourcePath;
@property (nonatomic, assign, readwrite) NSInteger sceneIndex;
@property (nonatomic, assign, readwrite) NSDictionary *currentModel;
@property (nonatomic, strong, readwrite) NSMutableArray <NSString *> *modelDirectories;
@property (nonatomic, strong, readwrite) NSMutableArray <NSString *> *modelJSONs;
@property (nonatomic, strong, readwrite) NSMutableArray <NSString *> *modelAvatarPaths;
@property (nonatomic, copy) NSString *resPath;

@end

@implementation NYLDModelManager

+ (instancetype)shared {
    static NYLDModelManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NYLDModelManager alloc] init];
        // Additional initialization code here, if needed
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Frameworks/Live2DSDK" withExtension:@"framework"];
        NSString *bundlePath = nil;
        if (url != nil) {
            bundlePath = [[NSBundle bundleWithURL:url] pathForResource:@"Live2DModels" ofType:@"bundle"];
        } else {
            bundlePath = [[NSBundle mainBundle] pathForResource:@"Live2DModels" ofType:@"bundle"];
        }
         
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        _modelBundle = bundle;
        _resPath = @"Resources";
        _resourcePath = [bundlePath stringByAppendingPathComponent:self.resPath];
        NYLog(@"resourcePath: %@", self.resourcePath);
        
        _modelDirectories = [[NSMutableArray alloc] init];
        _modelJSONs = [[NSMutableArray alloc] init];
        _modelAvatarPaths = [[NSMutableArray alloc] init];
        _sceneIndex = 0;
        _viewMatrix = new Csm::CubismMatrix44();
    }
    return self;
}


- (void)dealloc
{
    delete _viewMatrix;
    _viewMatrix = nil;
    [_modelDirectories removeAllObjects];
    _modelDirectories = nil;
    [_modelJSONs removeAllObjects];
    _modelJSONs = nil;
    [self releaseAllModel];
    [super dealloc];
}

- (void)releaseAllModel
{
    for (Csm::csmUint32 i = 0; i < _models.GetSize(); i++)
    {
        delete _models[i];
    }

    _models.Clear();
}

- (LAppTextureManager *)textureManager {
    if (!_textureManager) {
        _textureManager = [[LAppTextureManager alloc] init];
    }
    return _textureManager;
}

+ (NSArray<NSString *> *)modelJSONPaths {
    return  [NYLDModelManager shared].modelJSONs;
}

+ (NSArray<NSString *> *)modelAvatarPaths {
    return  [[NYLDModelManager shared].modelAvatarPaths copy];
}


+ (NSString * _Nullable)backgroundDirWithError:(NSError ** _Nullable)error {
    // 加载 Live2DModels.bundle
    NSBundle *resourceBundle = [NYLDModelManager shared].modelBundle;
    
    if (!resourceBundle) {
        if (error) {
            *error = [NSError errorWithDomain:BundleErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Live2DModels.bundle not found"}];
        }
        return nil;
    }
    
    // 获取 backgroundDir 目录路径
    NSString *backgroundDirPath = [resourceBundle pathForResource:@"Background" ofType:nil];
    if (!backgroundDirPath) {
        if (error) {
            *error = [NSError errorWithDomain:BundleErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"backgroundDir not found in Live2DModels.bundle"}];
        }
        return nil;
    }
    return backgroundDirPath;
}

+ (NSArray<NSString *> * _Nullable )backgroundDirFilePathsWithError:(NSError ** _Nullable)error {
    
    // 获取 backgroundDir 目录路径
    NSString *backgroundDirPath = [self backgroundDirWithError:error];
    if (!backgroundDirPath) {
        if (error) {
            *error = [NSError errorWithDomain:BundleErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"backgroundDir not found in Live2DModels.bundle"}];
        }
        return nil;
    }
    
    // 使用 NSFileManager 枚举 backgroundDir 下的所有文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray<NSString *> *filePaths = [NSMutableArray array];
    
    // 枚举目录（包括子目录）
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:backgroundDirPath];
    NSString *filePath;
    while ((filePath = [enumerator nextObject])) {
        NSString *fullPath = [backgroundDirPath stringByAppendingPathComponent:filePath];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            [filePaths addObject:fullPath];
        }
    }
    
    return [filePaths copy];
}

- (void)setup {
    _modelDir.Clear();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.resourcePath error:&error];
    for (NSString *content in contents) {
        NSString *path = [self.resourcePath stringByAppendingPathComponent:content];
        NYLog(@"path:%@", path);
        NSString *modelName = [path lastPathComponent];
        NYLog(@"modelName:%@", modelName);
        
        BOOL isDirectory;
        BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
        if (isDirectory && exists) {
            NSString *targetFile = [path stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.model3.json", modelName]];
            NSString *avatarPath = [path stringByAppendingPathComponent: @"avatar.jpg"];
            NYLog(@"targetFile: %@", targetFile);
            if ([fileManager fileExistsAtPath:targetFile]) {
                [self.modelDirectories addObject:path];
                [self.modelJSONs addObject:targetFile];
                [self.modelAvatarPaths addObject:avatarPath];
                _modelDir.PushBack(Csm::csmString([modelName UTF8String]));
            }
        }
    }
    
    NYLog(@"modelDirectories: %@", self.modelDirectories);
}

- (LAppModel*)getModel:(Csm::csmUint32)no
{
    if (no < _models.GetSize())
    {
        return _models[no];
    }
    return nil;
}

- (void)onDrag:(Csm::csmFloat32)x floatY:(Csm::csmFloat32)y
{
    for (Csm::csmUint32 i = 0; i < _models.GetSize(); i++)
    {
        Csm::CubismUserModel* model = static_cast<Csm::CubismUserModel*>([self getModel:i]);
        model->SetDragging(x,y);
    }
}

- (void)onTap:(Csm::csmFloat32)x floatY:(Csm::csmFloat32)y;
{
    if (LAppDefine::DebugLogEnable)
    {
        LAppPal::PrintLogLn("[APP]tap point: {x:%.2f y:%.2f}", x, y);
    }

    for (Csm::csmUint32 i = 0; i < _models.GetSize(); i++)
    {
        if(_models[i]->HitTest(LAppDefine::HitAreaNameHead,x,y))
        {
            if (LAppDefine::DebugLogEnable)
            {
                LAppPal::PrintLogLn("[APP]hit area: [%s]", LAppDefine::HitAreaNameHead);
            }
            _models[i]->SetRandomExpression();
        }
        else if (_models[i]->HitTest(LAppDefine::HitAreaNameBody, x, y))
        {
            if (LAppDefine::DebugLogEnable)
            {
                LAppPal::PrintLogLn("[APP]hit area: [%s]", LAppDefine::HitAreaNameBody);
            }
            _models[i]->StartRandomMotion(LAppDefine::MotionGroupTapBody, LAppDefine::PriorityNormal, NYLDFinishedMotion, NYLDBeganMotion);
        }
    }
}

- (void)onUpdate;
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;

//    AppDelegate* delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
//    ViewController* view = [delegate viewController];

    Csm::csmUint32 modelCount = _models.GetSize();
    
    for (Csm::csmUint32 i = 0; i < modelCount; ++i)
    {
        Csm::CubismMatrix44 projection;
        LAppModel* model = [self getModel:i];
        
        if (model->GetModel() == NULL)
        {
            LAppPal::PrintLogLn("Failed to model->GetModel().");
            continue;
        }

        if (model->GetModel()->GetCanvasWidth() > 1.0f && width < height)
        {
          // 横に長いモデルを縦長ウィンドウに表示する際モデルの横サイズでscaleを算出する
          model->GetModelMatrix()->SetWidth(2.0f);
          projection.Scale(1.0f, static_cast<float>(width) / static_cast<float>(height));
        }
        else
        {
          projection.Scale(1.0f * static_cast<float>(height) / static_cast<float>(width), 1.0f);
        }
//        projection.TranslateRelative(0.5, 0.5);
        // 必要があればここで乗算
        if (_viewMatrix != NULL)
        {
          projection.MultiplyByMatrix(_viewMatrix);
        }

//        [view PreModelDraw:*model];

        model->Update();
        model->Draw(projection);///< 参照渡しなのでprojectionは変質する

//        [view PostModelDraw:*model];
    }
}

- (void)nextScene;
{
    Csm::csmInt32 no = ((int)_sceneIndex + 1) % _modelDir.GetSize();
    [self changeScene:no];
}

- (void)changeScene:(NSInteger)index;
{
    if (index < 0 || index >= self.modelJSONs.count ) {
        NYLog(@"Invalid Index!!!!");
        return;
    }
    _sceneIndex = index;
    if (LAppDefine::DebugLogEnable)
    {
        LAppPal::PrintLogLn("[APP]model index: %d", _sceneIndex);
    }

    // model3.jsonのパスを決定する.
    // ディレクトリ名とmodel3.jsonの名前を一致させておくこと.
    const Csm::csmString& model = _modelDir[(int)index];

    Csm::csmString modelPath(self.resPath.UTF8String);
    modelPath.Append(1, '/');
    modelPath += model;
    modelPath.Append(1, '/');

    Csm::csmString modelJsonName(model);
    modelJsonName += ".model3.json";

    [self releaseAllModel];
    _models.PushBack(new LAppModel());
    _models[0]->LoadAssets(modelPath.GetRawString(), modelJsonName.GetRawString());

    /*
     * モデル半透明表示を行うサンプルを提示する。
     * ここでUSE_RENDER_TARGET、USE_MODEL_RENDER_TARGETが定義されている場合
     * 別のレンダリングターゲットにモデルを描画し、描画結果をテクスチャとして別のスプライトに張り付ける。
     */
    {
#if defined(USE_RENDER_TARGET)
        // LAppViewの持つターゲットに描画を行う場合、こちらを選択
        SelectTarget useRenderTarget = SelectTarget_ViewFrameBuffer;
#elif defined(USE_MODEL_RENDER_TARGET)
        // 各LAppModelの持つターゲットに描画を行う場合、こちらを選択
        SelectTarget useRenderTarget = SelectTarget_ModelFrameBuffer;
#else
        // デフォルトのメインフレームバッファへレンダリングする(通常)
        NYLDSelectTarget useRenderTarget = NYLDSelectTargetNone;
#endif

#if defined(USE_RENDER_TARGET) || defined(USE_MODEL_RENDER_TARGET)
        // モデル個別にαを付けるサンプルとして、もう1体モデルを作成し、少し位置をずらす
        _models.PushBack(new LAppModel());
        _models[1]->LoadAssets(modelPath.GetRawString(), modelJsonName.GetRawString());
        _models[1]->GetModelMatrix()->TranslateX(0.2f);
#endif
        
    }
}

- (Csm::csmUint32)GetModelNum;
{
    return _models.GetSize();
}

- (void)SetViewMatrix:(float *)m;
{
    for (int i = 0; i < 16; i++) {
        _viewMatrix->GetArray()[i] = m[i];
//        NYLog(@"m->GetArray()[i]:%.2f _viewMatrix->GetArray()[i]:%.2f", m[i], _viewMatrix->GetArray()[i]);
    }
}

- (float)getModelOpacityWithIndex:(int)index {
    LAppModel* model = [self getModel:index];
    return model->GetOpacity();
}

- (BOOL)modelExistsWithIndex:(int)index {
    LAppModel* model = [self getModel:index];
    return model != nil;
}

- (GLuint)modelTextureIdWithIndex:(int)index {
    LAppModel* model = [self getModel:index];
    Csm::Rendering::CubismOffscreenSurface_OpenGLES2& useTarget = model->GetRenderBuffer();
    GLuint textureId = useTarget.GetColorBuffer();
    return textureId;
}

+ (void)setup {
    [[NYLDModelManager shared] setup];
    [[NYLDModelManager shared] changeScene:0];
}

@end
