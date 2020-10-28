//
//  MMCamera.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/12.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMCamera.h"
@import AVFoundation;

@interface MMCamera ()

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;

@end

@implementation MMCamera

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset
                             position:(AVCaptureDevicePosition)position {
    self = [super init];
    if (self) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession beginConfiguration];
        if ([self.captureSession canSetSessionPreset:preset]) {
            self.captureSession.sessionPreset = preset;
        }
        [self setCaptureDevicePosition:position];
        [_captureSession commitConfiguration];
    }
    return self;
}

- (void)startRunning {
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stopRunning {
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)position {
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if ([device hasMediaType:AVMediaTypeVideo] && device.position == position) {
            [device lockForConfiguration:nil];
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            if ([device isLowLightBoostSupported]) {
                device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            }
            [device unlockForConfiguration];
            self.captureDevice = device;
            
            [self.captureSession beginConfiguration];
            AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
            if (self.captureInput) {
                [self.captureSession removeInput:self.captureInput];
            }
            if ([self.captureSession canAddInput:input]) {
                [self.captureSession addInput:input];
                self.captureInput = input;
            }
            [self.captureSession commitConfiguration];
        }
    }
}

- (void)enableVideoDataOutputWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate
                                                queue:(dispatch_queue_t)queue {
    [self.captureSession beginConfiguration];
    if (self.captureOutput) {
        [self.captureSession removeOutput:self.captureOutput];
        self.captureOutput = nil;
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    [output setSampleBufferDelegate:delegate queue:queue];
    if ([self.captureSession canAddOutput:output]) {
        [self.captureSession addOutput:output];
        self.captureOutput = output;
    }
    [self.captureSession commitConfiguration];
    
    [self configCameraConnection];
}

- (void)configCameraConnection {
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = (self.captureDevice.position == AVCaptureDevicePositionFront);
}

- (void)rotateCamera {
    [self stopRunning];
    
    if (self.captureDevice.position == AVCaptureDevicePositionFront) {
        [self setCaptureDevicePosition:AVCaptureDevicePositionBack];
    } else {
        [self setCaptureDevicePosition:AVCaptureDevicePositionFront];
    }
    
    [self configCameraConnection];

    [self startRunning];
}

- (AVCaptureDevicePosition)currentPosition {
    return self.captureDevice.position;
}

@end
