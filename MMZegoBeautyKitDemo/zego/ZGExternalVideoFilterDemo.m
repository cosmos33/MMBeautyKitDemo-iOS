//
//  ZGExternalVideoFilterDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//


#import "ZGExternalVideoFilterDemo.h"
#import "ZGVideoFilterFactoryDemo.h"

#import <ZegoLiveRoom/ZegoLiveRoom.h>


@interface ZGExternalVideoFilterDemo () <ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) BOOL isAnchor;

@property (nonatomic, strong) ZGVideoFilterFactoryDemo *g_filterFactory;

@property (nonatomic, assign) BOOL isFront;

@end

@implementation ZGExternalVideoFilterDemo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isFront = YES;
    }
    return self;
}


- (void)dealloc {
    [self.zegoApi logoutRoom];
    self.zegoApi = nil;
    [self releaseFilterFactory];
}

#pragma mark - 外部滤镜工厂相关方法

/**
 初始化外部滤镜工厂对象
 
 @param type 视频缓冲区类型（Async, Sync, I420, NV12）
 @discussion 创建外部滤镜工厂对象后，先释放 ZegoLiveRoomSDK 确保 setVideoFilterFactory:channelIndex: 的调用在 initSDK 前
 */
- (void)initFilterFactoryType:(ZegoVideoBufferType)type {
    if (self.g_filterFactory == nil) {
        self.g_filterFactory = [[ZGVideoFilterFactoryDemo alloc] init];
        self.g_filterFactory.render = self.render;
        self.g_filterFactory.bufferType = type;
    }
    
    [ZegoExternalVideoFilter setVideoFilterFactory:self.g_filterFactory channelIndex:ZEGOAPI_CHN_MAIN];
}


/**
 释放外部滤镜工厂对象
 */
- (void)releaseFilterFactory {
    self.g_filterFactory = nil;
    // 需要在 initSDK 前调用（所以释放工厂也是在释放SDK后调用）
    [ZegoExternalVideoFilter setVideoFilterFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
}

#pragma mark - ZegoLiveRoom 的初始化、推拉流相关

- (void)initSDKWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor {
    self.roomID = roomID;
    self.streamID = streamID;
    self.isAnchor = isAnchor;
    
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:YES];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:NO];
    [ZegoLiveRoomApi requireHardwareDecoder:NO];
    

    Byte signKey[] = {0xd2,0x9a,0xce,0x6b,0x17,0xde,0xe0,0xc0,0xdc,0x49,0x7e,0xc1,0x43,0xf2,0xed,0xe4,0x96,0x01,0xca,0x65,0x7a,0xd8,0x08,0x35,0xb8,0x88,0x09,0x4d,0x1c,0xc0,0xfd,0x7e};
    NSData* sign = [NSData dataWithBytes:signKey length:32];
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)4254906461 appSignature:sign completionBlock:^(int errorCode) {
        if (errorCode == 0) {
            NSLog(@"初始化 SDK 成功");
        } else {
            NSLog(@"初始化 SDK 失败，错误码：%d", errorCode);
        }
    }];
    
    if (self.zegoApi) {
        ZegoAVConfig *avConfig = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_Veryhigh];
        [self.zegoApi setAVConfig:avConfig];
        [self.zegoApi setPublisherDelegate:self];
        [self.zegoApi setPlayerDelegate:self];
    }
}

- (void)loginRoom {
    NSString *userID = @"1721656114";
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    [self.zegoApi loginRoom:self.roomID role:self.isAnchor ? ZEGO_ANCHOR : ZEGO_AUDIENCE withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        if (errorCode == 0) {
            NSLog(@"登录房间成功");
        } else {
            NSLog(@"登录房间失败，错误码：%d", errorCode);
        }
    }];
}

- (void)logoutRoom {
    [self.zegoApi logoutRoom];
}

- (void)startPreview {
    if ([self.delegate respondsToSelector:@selector(getPlaybackView)]) {
        [self.zegoApi setPreviewView:[self.delegate getPlaybackView]];
//        [self.zegoApi setPreviewViewMode:ZegoVideoViewModeScaleAspectFill];
        [self.zegoApi startPreview];
    } else {
        NSLog(@"未设置预览 View");
    }
}

- (void)stopPreview {
    [self.zegoApi stopPreview];
    [self.zegoApi setPreviewView:nil];
    NSLog(@"停止预览");
}

- (void)startPublish {
    
    [ZegoLiveRoomApi setPublishQualityMonitorCycle:800];
    
    BOOL publishResult = [self.zegoApi startPublishing:self.streamID title:nil flag:ZEGOAPI_JOIN_PUBLISH];
    if (publishResult) {
        NSLog(@"推流成功, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
    } else {
        NSLog(@"推流失败, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
    }
}

- (void)stopPublish {
    [self.zegoApi stopPublishing];
    NSLog(@"停止推流");
}

- (void)startPlay {
    if ([self.delegate respondsToSelector:@selector(getPlaybackView)]) {
        [ZegoLiveRoomApi setPlayQualityMonitorCycle:800];
        BOOL result = [self.zegoApi startPlayingStream:self.streamID inView:[self.delegate getPlaybackView]];
        if (result) {
            NSLog(@"拉流成功, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
            [self.zegoApi setViewMode:ZegoVideoViewModeScaleAspectFill ofStream:self.streamID];
        } else {
            NSLog(@"拉流失败, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
        }
    } else {
        NSLog(@"未设置播放的 View");
    }
}

- (void)stopPlay {
    [self.zegoApi stopPlayingStream:self.streamID];
}

- (void)enablePreviewMirror:(BOOL)enable {
    [self.zegoApi enableCaptureMirror:enable];
    [self.zegoApi enablePreviewMirror:!enable];
}

- (void)flip {
    self.isFront = !self.isFront;
    [self.zegoApi setFrontCam:self.isFront];
    [self enablePreviewMirror:self.isFront];
}

#pragma mark - Publisher Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    NSLog(@"推流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPublishStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵推流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onExternalVideoFilterPublishStateUpdate:stateString];
    }
}



- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //    ZGLogInfo(@"推流质量更新：分辨率：%dx%d, 帧率：%ffps, 码率：%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPublishQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onExternalVideoFilterPublishQualityUpdate:qualityString];
    }
}

#pragma mark - Player Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    NSLog(@"拉流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPlayStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵拉流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onExternalVideoFilterPlayStateUpdate:stateString];
    }
}


- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //    ZGLogInfo(@"拉流质量更新:分辨率:%dx%d, 帧率:%ffps, 码率:%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPlayQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f vdecFps \n码率：%.2f kbps", quality.height, quality.width, quality.vdecFps, quality.kbps];
        [self.delegate onExternalVideoFilterPlayQualityUpdate:qualityString];
    }
}




@end
