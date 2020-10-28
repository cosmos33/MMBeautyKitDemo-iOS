//
//  MMDeviceMotionObserver.m
//  CXBeautyKit
//
//  Created by sunfei on 2018/11/27.
//

#import "MMDeviceMotionObserver.h"
@import CoreMotion;

@interface MMDeviceMotionObserver ()

@property (nonatomic, strong) NSHashTable<id<MMDeviceMotionHandling>> *handlers;

@property (nonatomic, readonly, class) MMDeviceMotionObserver *sharedObserver;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation MMDeviceMotionObserver

+ (instancetype)sharedObserver {
    static MMDeviceMotionObserver *observer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [[MMDeviceMotionObserver alloc] initDeviceMotion];
    });
    return observer;
}

- (instancetype)initDeviceMotion {
    self = [super init];
    if (self) {
        _handlers = [NSHashTable weakObjectsHashTable];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

+ (void)addDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler {
    [self.sharedObserver addDeviceMotionHandler:deviceMotionHandler];
}

- (void)addDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler {
    [_lock lock];
    [self.handlers addObject:deviceMotionHandler];
    [_lock unlock];
}

+ (void)removeDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler {
    [self.sharedObserver removeDeviceMotionHandler:deviceMotionHandler];
}

- (void)removeDeviceMotionHandler:(id<MMDeviceMotionHandling>)deviceMotionHandler {
    [_lock lock];
    [self.handlers removeObject:deviceMotionHandler];
    [_lock unlock];
}

+ (void)startMotionObserve {
    [self.sharedObserver createMotionManager];
}

+ (void)stopMotionObserve {
    [self.sharedObserver.motionManager stopDeviceMotionUpdates];
    [self.sharedObserver removeAllHandlers];
}

- (void)removeAllHandlers {
    [_lock lock];
    [self.handlers removeAllObjects];
    [_lock unlock];
}

- (void)handleDeviceMotion:(CMDeviceMotion *)motion {
    UIDeviceOrientation orientation = UIDeviceOrientationPortrait;
    
    double x = motion.gravity.x;
    double y = motion.gravity.y;
    
    if (ABS(motion.gravity.z) > 0.5f) {
        return;
    }
    
    if (fabs(y) >= fabs(x)) {
        orientation = y >= 0 ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
    } else {
        orientation = x >= 0 ? UIDeviceOrientationLandscapeRight : UIDeviceOrientationLandscapeLeft;
    }
    
    [_lock lock];
    for (id<MMDeviceMotionHandling> handler in self.handlers) {
        [handler handleDeviceMotionOrientation:orientation];
    }
    [_lock unlock];
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

- (void)createMotionManager {
    if (self.motionManager.deviceMotionAvailable) {
        self.motionManager.deviceMotionUpdateInterval = 0.5f;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                                withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                    [self handleDeviceMotion:motion];
                                                }];
    }
}

@end
