//
//  MMDeviceMotionObserver.h
//  CXBeautyKit
//
//  Created by sunfei on 2018/11/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMDeviceMotionHandling <NSObject>

- (void)handleDeviceMotionOrientation:(UIDeviceOrientation)orientation;

@end

/// 获取设备旋转信息
@interface MMDeviceMotionObserver : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)addDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler;
+ (void)removeDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler;

+ (void)startMotionObserve;
+ (void)stopMotionObserve;

@end

NS_ASSUME_NONNULL_END
