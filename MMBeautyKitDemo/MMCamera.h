//
//  MMCamera.h
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/12.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@interface MMCamera : NSObject

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset
                             position:(AVCaptureDevicePosition)position;
- (void)startRunning;
- (void)stopRunning;

- (void)rotateCamera;

- (AVCaptureDevicePosition)currentPosition;

- (void)enableVideoDataOutputWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate
                                                queue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
