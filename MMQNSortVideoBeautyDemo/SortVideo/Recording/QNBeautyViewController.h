//
//  QNBeautyViewController.h
//  MMQNSortVideoBeautyDemo
//
//  Created by momo783 on 2021/5/13.
//  Copyright © 2021 sunfei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMBeautyViewController.h"
#import "QNBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface QNBeautyViewController : MMBeautyViewController

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UILabel *progressLabel;

- (void)showWating;

- (void)hideWating;

- (void)setProgress:(CGFloat)progress;

+ (NSURL *)movieURL:(PHAsset *)phasset;

+ (QNDeviceType)deviceType;

+ (NSInteger)suitableVideoBitrateWithSize:(CGSize)videoSize;

+ (PLSAudioBitRate)suitableAudioBitrateWithSampleRate:(PLSAudioSampleRate)sampleRate channel:(NSInteger)channel;

- (void)showAlertMessage:(NSString *)title message:(NSString *)message;

- (void)requestMPMediaLibraryAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestCameraAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestMicrophoneAuth:(void(^)(BOOL succeed))completeBlock;

- (void)requestPhotoLibraryAuth:(void(^)(BOOL succeed))completeBlock;

- (NSString *)formatTimeString:(NSTimeInterval)time;

- (NSArray *)configureGlobalSettings;

- (NSArray *)getSettingInfos;

- (NSString *)getPreviewVideoSize;

- (NSInteger)getAudioChannels;

- (NSArray *)getEncodeVideoSize;

- (NSInteger)getEncodeBites;

@end

NS_ASSUME_NONNULL_END
