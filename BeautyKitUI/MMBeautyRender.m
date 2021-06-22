//
//  MMBeautyRender.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/19.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMBeautyRender.h"

#define LOOKUP 1
#define STICKER 1

@interface MMBeautyRender () <CosmosBeautySDKDelegate>

@property (nonatomic, strong) MMRenderModuleManager *render;
@property (nonatomic, strong) MMRenderFilterBeautyModule *beautyDescriptor;

#if LOOKUP == 1
@property (nonatomic, strong) MMRenderFilterLookupModule *lookupDescriptor;
#endif

#if STICKER == 1
@property (nonatomic, strong) MMRenderFilterStickerModule *stickerDescriptor;
#endif

@end

@implementation MMBeautyRender

- (void)dealloc {
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
#if DEBUG
            [CosmosBeautySDK initSDKWithAppId:@"b8b858e04e411665e20cf1145544d71c" delegate:self];
#else
            [CosmosBeautySDK initSDKWithAppId:@"6b38bc8e6afdbd040b8f6386b65c0aac" delegate:self];
#endif
        });
        
        MMRenderModuleManager *render = [[MMRenderModuleManager alloc] init];
        render.devicePosition = AVCaptureDevicePositionFront;
        render.inputType = MMRenderInputTypeStream;
        self.render = render;
        
        _beautyDescriptor = [[MMRenderFilterBeautyModule alloc] init];
        [render registerModule:_beautyDescriptor];
        
#if LOOKUP == 1
        _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
        [render registerModule:_lookupDescriptor];
#endif
        
#if STICKER == 1
        _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
        [render registerModule:_stickerDescriptor];
#endif
        NSLog(@"level = %d", [CosmosBeautySDK performSelector:NSSelectorFromString(@"__level__")]);
    }
    return self;
}

- (void)addBeauty {
    _beautyDescriptor = [[MMRenderFilterBeautyModule alloc] init];
    [_render registerModule:_beautyDescriptor];
}

- (void)removeBeauty {
    [_render unregisterModule:_beautyDescriptor];
    _beautyDescriptor = nil;
}

- (void)addLookup {
#if LOOKUP == 1
    _lookupDescriptor = [[MMRenderFilterLookupModule alloc] init];
    [_render registerModule:_lookupDescriptor];
#endif
}

- (void)removeLookup {
#if LOOKUP == 1
    [_render unregisterModule:_lookupDescriptor];
    _lookupDescriptor = nil;
#endif
}

- (void)addSticker {
#if STICKER == 1
    _stickerDescriptor = [[MMRenderFilterStickerModule alloc] init];
    [_render registerModule:_stickerDescriptor];
#endif
}

- (void)removeSticker {
#if STICKER == 1
    [_render unregisterModule:_stickerDescriptor];
    _stickerDescriptor = nil;
#endif
}

- (CVPixelBufferRef _Nullable)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                          error:(NSError * __autoreleasing _Nullable *)error {
    return [self.render renderFrame:pixelBuffer error:error];
}

- (MTIImage *_Nullable)renderToImage:(CVPixelBufferRef)pixelBuffer error:(NSError * __autoreleasing _Nullable *)error {
    return [self.render renderFrameToImage:pixelBuffer error:error];
}

- (void)setInputType:(MMRenderInputType)inputType {
    self.render.inputType = inputType;
}

- (MMRenderInputType)inputType {
    return self.render.inputType;
}

- (void)setCameraRotate:(MMRenderModuleCameraRotate)cameraRotate {
    self.render.cameraRotate = cameraRotate;
}

- (MMRenderModuleCameraRotate)cameraRotate {
    return self.render.cameraRotate;
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition {
    self.render.devicePosition = devicePosition;
}

- (AVCaptureDevicePosition)devicePosition {
    return self.render.devicePosition;
}

- (void)setBeautyFactor:(float)value forKey:(MMBeautyFilterKey)key {
    [self.beautyDescriptor setBeautyFactor:value forKey:key];
}

- (void)setLookupPath:(NSString *)lookupPath {
#if LOOKUP == 1
    [self.lookupDescriptor setLookupResourcePath:lookupPath];
    [self.lookupDescriptor setIntensity:1.0];
#endif
}

- (void)setLookupIntensity:(CGFloat)intensity {
#if LOOKUP == 1
    [self.lookupDescriptor setIntensity:intensity];
#endif
}

- (void)clearLookup {
#if LOOKUP == 1
    [self.lookupDescriptor clear];
#endif
}

- (void)setMaskModelPath:(NSString *)path {
#if STICKER == 1
    [self.stickerDescriptor setMaskModelPath:path];
#endif
}

- (void)clearSticker {
#if STICKER == 1
    [self.stickerDescriptor clear];
#endif
}

#pragma mark - CosmosBeautySDKDelegate delegate

// 发生错误时，不可直接发起 `+[CosmosBeautySDK prepareBeautyResource]` 重新请求，否则会造成循环递归
- (void)context:(CosmosBeautySDK *)context result:(BOOL)result detectorConfigFailedToLoad:(NSError * _Nullable)error {
    NSLog(@"cv load error: %@", error);
}

// 发生错误时，不可直接发起  `+[CosmosBeautySDK requestAuthorization]` 重新请求，否则会造成循环递归
- (void)context:(CosmosBeautySDK *)context
authorizationStatus:(MMBeautyKitAuthrizationStatus)status
requestFailedToAuthorization:(NSError * _Nullable)error {
    NSLog(@"authorization failed: %@", error);
}

@end

