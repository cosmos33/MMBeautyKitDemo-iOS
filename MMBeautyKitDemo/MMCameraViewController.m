//
//  MMCameraViewController.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2019/12/17.
//  Copyright © 2019 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMCameraViewController.h"
#import "MMCamera.h"
#import "MMDeviceMotionObserver.h"
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"
@import MetalPetal;
@import AVFoundation;

@interface MMCameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MMDeviceMotionHandling>

@property (nonatomic, strong) MMCamera *camera;
@property (nonatomic, strong) MTIImageView *previewView;

@end

@implementation MMCameraViewController

- (void)dealloc {
    [MMDeviceMotionObserver removeDeviceMotionHandler:self];
    [MMDeviceMotionObserver stopMotionObserve];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.view.backgroundColor = UIColor.blackColor;
    
    self.previewView = [[MTIImageView alloc] initWithFrame:[UIScreen.mainScreen bounds]];
    [self.view insertSubview:self.previewView atIndex:0];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.camera = [[MMCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 position:AVCaptureDevicePositionFront];
    dispatch_queue_t queue = dispatch_queue_create("com.mmbeautykit.demo", nil);
    [self.camera enableVideoDataOutputWithSampleBufferDelegate:self queue:queue];
    
    [MMDeviceMotionObserver startMotionObserve];
    [MMDeviceMotionObserver addDeviceMotionHandler:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.camera startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer) {
        
        NSError *error = nil;
//        CVPixelBufferRef renderedPixelBuffer = [self.render renderPixelBuffer:pixelBuffer error:&error];
//        if (!renderedPixelBuffer || error) {
//            NSLog(@"error: %@", error);
//        } else {
//            MTIImage *image = [[MTIImage alloc] initWithCVPixelBuffer:renderedPixelBuffer alphaType:MTIAlphaTypeAlphaIsOne];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.previewView.image = image;
//            });
//        }
        MTIImage *image = [self.render renderToImage:pixelBuffer error:&error];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewView.image = image;
            });
        } else {
            CVPixelBufferRetain(pixelBuffer);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewView.image = [[MTIImage alloc] initWithCVPixelBuffer:pixelBuffer alphaType:MTIAlphaTypeAlphaIsOne];
                CVPixelBufferRelease(pixelBuffer);
            });
        }
        
    }
}

- (void)flipButtonTapped:(UIButton *)button {
    [self.camera rotateCamera];
    self.render.devicePosition = self.camera.currentPosition;
}

#pragma mark - MMDeviceMotionHandling methods

- (void)handleDeviceMotionOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            self.render.cameraRotate = MMRenderModuleCameraRotate90;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.render.cameraRotate = MMRenderModuleCameraRotate0;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.render.cameraRotate = MMRenderModuleCameraRotate180;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.render.cameraRotate = MMRenderModuleCameraRotate270;
            break;
            
        default:
            break;
    }
}

@end
