//
//  AliLiveEngineFactory.h
//  AliLiveSdk-Demo
//
//  Created by ZhouGuixin on 2020/8/4.
//  Copyright © 2020 alilive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AliLiveSdk/AliLiveSdk.h>
NS_ASSUME_NONNULL_BEGIN

@interface AliLiveEngineMaker : NSObject

+ (AliLiveEngine *)createEngine:(id<AliLiveRtsDelegate, AliLivePushInfoStatusDelegate>)delegate;

+ (AliLiveEngine *)createEngine:(nullable AliLiveConfig *)config delegate:(id<AliLiveRtsDelegate, AliLivePushInfoStatusDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
