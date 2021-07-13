//
//  MMBeautyViewController.h
//  MMBeautyKit_Example
//
//  Created by momo783 on 2021/4/14.
//  Copyright © 2021 sunfei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"

#import <Masonry/Masonry.h>
@import MetalPetal;
NS_ASSUME_NONNULL_BEGIN

@interface MMBeautyViewController : UIViewController

@property (nonatomic, strong) MMBeautyRender *render;

@property (nonatomic, strong) MMCameraTabSegmentView *lookupView;
@property (nonatomic, strong) MMCameraTabSegmentView *beautyView;
@property (nonatomic, strong) MMCameraTabSegmentView *makeuUpView;
@property (nonatomic, strong) MMCameraTabSegmentView *stickerView;

@end

NS_ASSUME_NONNULL_END
