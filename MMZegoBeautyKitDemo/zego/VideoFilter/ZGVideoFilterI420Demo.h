//
//  ZGVideoFilterI420Demo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/30.
//  Copyright © 2019 Zego. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "MMBeautyRender.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-filter-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-filter-oc.h>
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 异步 I420 类型外部滤镜实现
 */
@interface ZGVideoFilterI420Demo : NSObject<ZegoVideoFilter, ZegoVideoBufferPool>

@property (nonatomic, strong) MMBeautyRender *render;

@end


NS_ASSUME_NONNULL_END
