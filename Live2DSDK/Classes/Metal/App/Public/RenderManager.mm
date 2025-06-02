//
//  RenderManager.m
//  Live2DSDK
//
//  Created by NY on 2025/3/7.
//

#import "RenderManager.h"

#import <iostream>
#import "ViewController.h"
#import "LAppAllocator.h"
#import "LAppPal.h"
#import "LAppDefine.h"
#import "LAppLive2DManager.h"
#import "LAppTextureManager.h"


@interface RenderManager ()

@property (nonatomic) LAppAllocator cubismAllocator; // Cubism SDK Allocator
@property (nonatomic) Csm::CubismFramework::Option cubismOption; // Cubism SDK Option
@property (nonatomic, assign) bool captured; // クリックしているか
@property (nonatomic, assign) float mouseX; // マウスX座標
@property (nonatomic, assign) float mouseY; // マウスY座標
@property (nonatomic, strong) LAppTextureManager *textureManager; // テクスチャマネージャー
@property (nonatomic) Csm::csmInt32 sceneIndex;

@end

@implementation RenderManager

+ (instancetype)shared {
    static RenderManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RenderManager alloc] init];
    });
    
    return sharedInstance;
}

// Optional: Override init to customize initialization
- (instancetype)init {
    self = [super init];
    if (self) {
        // Perform any initialization here
        NSLog(@"MySingleton initialized");
    }
    return self;
}

+ (BOOL)applicationDidFinishLaunching {
    return [[RenderManager shared] applicationDidFinishLaunching];
}

+ (void)applicationDidEnterBackground {
    [[RenderManager shared] applicationDidEnterBackground];
}

+ (void)applicationWillEnterForeground {
    [[RenderManager shared] applicationWillEnterForeground];
}


- (BOOL)applicationDidFinishLaunching {

    _textureManager = [[LAppTextureManager alloc]init];

    [self initializeCubism];

//    [self.viewController initializeSprite];

    return YES;
}


- (void)applicationDidEnterBackground
{
    _textureManager = nil;

    _sceneIndex = [[LAppLive2DManager getInstance] sceneIndex];
}

- (void)applicationWillEnterForeground
{
    _textureManager = [[LAppTextureManager alloc]init];

    [[LAppLive2DManager getInstance] changeScene:_sceneIndex];
}


- (void)initializeCubism
{
    _cubismOption.LogFunction = LAppPal::PrintMessageLn;
    _cubismOption.LoggingLevel = LAppDefine::CubismLoggingLevel;

    Csm::CubismFramework::StartUp(&_cubismAllocator,&_cubismOption);

    Csm::CubismFramework::Initialize();

    [LAppLive2DManager getInstance];

    Csm::CubismMatrix44 projection;

    LAppPal::UpdateTime();

}



- (void)finishApplication
{
    

    _textureManager = nil;

    [LAppLive2DManager releaseInstance];

    Csm::CubismFramework::Dispose();
    
}

@end
