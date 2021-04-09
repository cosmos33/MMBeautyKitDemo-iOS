//
//  AliLiveEngineFactory.m
//  AliLiveSdk-Demo
//
//  Created by ZhouGuixin on 2020/8/4.
//  Copyright © 2020 alilive. All rights reserved.
//

#import "AliLiveEngineMaker.h"

@implementation AliLiveEngineMaker

+ (AliLiveEngine *)createEngine:(id<AliLiveRtsDelegate, AliLivePushInfoStatusDelegate>)delegate {
    return [AliLiveEngineMaker createEngine:nil delegate:delegate];
}

+ (AliLiveEngine *)createEngine:(nullable AliLiveConfig *)config delegate:(id<AliLiveRtsDelegate, AliLivePushInfoStatusDelegate>)delegate {
    AliLiveConfig *myConfig = config;
    if (myConfig == nil) {
        myConfig = [[AliLiveConfig alloc] init];
        myConfig.videoProfile = AliLiveVideoProfile_540P;
        myConfig.videoFPS = 20;
        myConfig.enablePureAudioPush = false;
        myConfig.beautyOn = YES;
    }
    myConfig.pauseImage = [UIImage imageNamed:@"background_img.png"];
    NSString *live_config_accountid = [[NSUserDefaults standardUserDefaults] objectForKey:@"live_config_accountid"];
    if (!live_config_accountid || live_config_accountid.length == 0) {
        myConfig.accountID = @"182692"; //线上
    }else{
        myConfig.accountID = live_config_accountid; // 预发 166224
    }
    AliLiveEngine *engine = [[AliLiveEngine alloc] initWithConfig:myConfig];
    [engine setAudioSessionOperationRestriction:AliLiveAudioSessionOperationRestrictionDeactivateSession];
    [engine setRtsDelegate:delegate];
    [engine setStatusDelegate:delegate];
    return engine;
}

@end
