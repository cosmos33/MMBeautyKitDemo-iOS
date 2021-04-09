//
//  RaceBeautyConfig.m
//  AliLiveSdk-Demo
//
//  Created by ZhouGuixin on 2020/7/28.
//  Copyright © 2020 alilive. All rights reserved.
//

#import "ALLiveConfig.h"
#import <AliLiveSdk/AliLiveSdk.h>

@interface ALLiveConfig ()

@property (nonatomic, strong) NSMutableArray *raceBeautyConfig_bak;
@property (nonatomic, strong) NSMutableArray *liveConfig_bak;

@end

@implementation ALLiveConfig

+ (instancetype)sharedInstance {
    static ALLiveConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ALLiveConfig alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self mkConfig];
        [self mkLiveConfig];
    }
    return self;
}

- (void)resetRaceBeautyConfig {
    self.raceBeautyConfig = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(self.raceBeautyConfig_bak), kCFPropertyListMutableContainersAndLeaves));
}

- (void)resetLiveConfig {
    self.liveConfig = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(self.liveConfig_bak), kCFPropertyListMutableContainersAndLeaves));
}

- (void)mkConfig {
    NSArray *config = @[
        @{
                    @"type" : @(0), // 美颜
                    @"isopen" : @(YES),
                    @"data" : @[
                            @{@"name":@"磨皮",        @"key":@(0),    @"value":@(0.6),    @"min":@(0), @"max":@(1), @"type":@"slider"},
                            @{@"name":@"锐化",        @"key":@(1),        @"value":@(0.8),    @"min":@(0), @"max":@(1), @"type":@"slider"},
                    ]
                },
    ];
    self.raceBeautyConfig_bak = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(config), kCFPropertyListMutableContainersAndLeaves));
    [self resetRaceBeautyConfig];
}

- (void)mkLiveConfig {
    NSArray *liveConfig = @[
        @{
            @"title":@"全局配置",
            @"data":@[
//                @{@"name":@"cameraPosition",            @"desc":@"前后置摄像头",         @"type":@"picker",    @"value":@(AliLiveCameraPositionFront)        },
                @{@"name":@"beautyOn",                  @"desc":@"美颜开关",            @"type":@"switch",      @"value":@(YES)     },

                @{@"name":@"autoFocus",                 @"desc":@"自动对焦",      @"type":@"switch",      @"value":@(NO)       },
                @{@"name":@"videoFPS",                  @"desc":@"视频帧率",            @"type":@"textfield",    @"value":@"20", @"unit":@"fps"    },
                @{@"name":@"enableHighDefPreview",      @"desc":@"高清预览",            @"type":@"switch",    @"value":@(NO)    },
                @{@"name":@"videoProfile",              @"desc":@"推流分辨率",       @"type":@"picker",    @"value":@(AliLiveVideoProfile_540P)},
//                @{@"name":@"enablePureAudioPush",       @"desc":@"纯音频连麦",          @"type":@"switch",       @"value":@(NO)     },
//                @{@"name":@"videoPreProcess",           @"desc":@"视频预处理",            @"type":@"switch",      @"value":@(NO)     },
            ]
        },
        @{
            @"title":@"rtmp配置",
            @"data":@[
                @{@"name":@"enableVideoHWAcceleration", @"desc":@"视频硬编码",           @"type":@"switch",      @"value":@(YES) },
                @{@"name":@"enableAudioHWAcceleration", @"desc":@"音频硬编码",           @"type":@"switch",      @"value":@(NO) },
                @{@"name":@"videoGopSize",              @"desc":@"视频编码GOP",    @"type":@"picker",    @"value":@(AliLivePushVideoEncodeGOP_2)   },
                @{@"name":@"videoInitBitrate",          @"desc":@"视频编码初始编码码率",  @"type":@"textfield",   @"value":@"1000", @"unit":@"kbps"    },
                @{@"name":@"videoTargetBitrate",        @"desc":@"视频编码目标编码码率",  @"type":@"textfield",   @"value":@"1500", @"unit":@"kbps"    },
                @{@"name":@"videoMinBitrate",           @"desc":@"视频编码最小编码码率",  @"type":@"textfield",   @"value":@"600", @"unit":@"kbps"    },
                @{@"name":@"audioChannel",              @"desc":@"音频采集声道数",  @"type":@"picker",  @"value":@(AliLivePushAudioChannel_1)    },
                @{@"name":@"audioSampleRate",           @"desc":@"音频采样率",           @"type":@"picker",   @"value":@(AliLivePushAudioSampleRate44100)    },
                @{@"name":@"audioEncoderProfile",       @"desc":@"音频编码格式",          @"type":@"picker",  @"value":@(AliLiveAudioEncoderProfile_AAC_LC)     },
                @{@"name":@"autoReconnectRetryCount",   @"desc":@"推流自动重连次数",      @"type":@"textfield",   @"value":@"5", @"unit":@"次"      },
                @{@"name":@"autoReconnectRetryInterval", @"desc":@"推流自动重连间隔",     @"type":@"textfield",   @"value":@"1000", @"unit":@"ms"      },
            ]
        }
    ];
    
    self.liveConfig_bak = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(liveConfig), kCFPropertyListMutableContainersAndLeaves));
    [self resetLiveConfig];
    
    self.livePickersConfig = @{
        @"cameraPosition":@[
                @{@"name":@"AliLiveCameraPositionBack", @"value":@(AliLiveCameraPositionBack)},
                @{@"name":@"AliLiveCameraPositionFront", @"value":@(AliLiveCameraPositionFront)},
        ],
        @"videoProfile":@[
                @{@"name":@"AliLiveVideoProfile_180P", @"value":@(AliLiveVideoProfile_180P)},
                @{@"name":@"AliLiveVideoProfile_360P", @"value":@(AliLiveVideoProfile_360P)},
                @{@"name":@"AliLiveVideoProfile_480P", @"value":@(AliLiveVideoProfile_480P)},
                @{@"name":@"AliLiveVideoProfile_540P", @"value":@(AliLiveVideoProfile_540P)},
                @{@"name":@"AliLiveVideoProfile_720P", @"value":@(AliLiveVideoProfile_720P)},
                @{@"name":@"AliLiveVideoProfile_1080P", @"value":@(AliLiveVideoProfile_1080P)},
        ],
        @"videoGopSize":@[
                @{@"name":@"AliLivePushVideoEncodeGOP_1", @"value":@(AliLivePushVideoEncodeGOP_1)},
                @{@"name":@"AliLivePushVideoEncodeGOP_2", @"value":@(AliLivePushVideoEncodeGOP_2)},
                @{@"name":@"AliLivePushVideoEncodeGOP_3", @"value":@(AliLivePushVideoEncodeGOP_3)},
                @{@"name":@"AliLivePushVideoEncodeGOP_4", @"value":@(AliLivePushVideoEncodeGOP_4)},
                @{@"name":@"AliLivePushVideoEncodeGOP_5", @"value":@(AliLivePushVideoEncodeGOP_5)},
        ],
        @"audioChannel":@[
                @{@"name":@"AliLivePushAudioChannel_1", @"value":@(AliLivePushAudioChannel_1)},
                @{@"name":@"AliLivePushAudioChannel_2", @"value":@(AliLivePushAudioChannel_2)},
        ],
        @"audioSampleRate":@[
                @{@"name":@"AliLivePushAudioSampleRate16000", @"value":@(AliLivePushAudioSampleRate16000)},
                @{@"name":@"AliLivePushAudioSampleRate32000", @"value":@(AliLivePushAudioSampleRate32000)},
                @{@"name":@"AliLivePushAudioSampleRate44100", @"value":@(AliLivePushAudioSampleRate44100)},
                @{@"name":@"AliLivePushAudioSampleRate48000", @"value":@(AliLivePushAudioSampleRate48000)},
        ],
        @"audioEncoderProfile":@[
                @{@"name":@"AliLiveAudioEncoderProfile_AAC_LC", @"value":@(AliLiveAudioEncoderProfile_AAC_LC)},
                @{@"name":@"AliLiveAudioEncoderProfile_HE_AAC", @"value":@(AliLiveAudioEncoderProfile_HE_AAC)},
                @{@"name":@"AliLiveAudioEncoderProfile_HE_AAC_V2", @"value":@(AliLiveAudioEncoderProfile_HE_AAC_V2)},
        ],
    };
    self.liveProfileBitrateMap = @{
        @"AliLiveVideoProfile_180P":@[@"300",     @"550",   @"120"],
        @"AliLiveVideoProfile_360P":@[@"600",     @"1000",  @"300"],
        @"AliLiveVideoProfile_480P":@[@"800",     @"1200",  @"300"],
        @"AliLiveVideoProfile_540P":@[@"1000",    @"1500",  @"600"],
        @"AliLiveVideoProfile_720P":@[@"1500",    @"2000",  @"600"],
        @"AliLiveVideoProfile_1080P":@[@"2000",   @"3500",  @"1200"],
    };
}

- (NSString *)descOfPickerValue:(NSString *)name value:(id)value {
    NSArray *valuesArray = [ALLiveConfig sharedInstance].livePickersConfig[name];
    NSInteger intvalue = [value integerValue];
    for (NSDictionary *dic in valuesArray) {
        if (intvalue == [dic[@"value"] integerValue]) {
            return dic[@"name"];
        }
    }
    return [NSString stringWithFormat:@"%@",value];
}

@end



