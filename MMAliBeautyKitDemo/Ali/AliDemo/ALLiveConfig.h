//
//  RaceBeautyConfig.h
//  AliLiveSdk-Demo
//
//  Created by ZhouGuixin on 2020/7/28.
//  Copyright © 2020 alilive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALLiveConfig : NSObject

// 美颜相关
@property (nonatomic, strong) NSMutableArray *raceBeautyConfig;
- (void)resetRaceBeautyConfig;

// 推流设置
@property (nonatomic, strong) NSMutableArray *liveConfig;
@property (nonatomic, strong) NSDictionary *livePickersConfig;
@property (nonatomic, strong) NSDictionary *liveProfileBitrateMap;
- (void)resetLiveConfig;
- (NSString *)descOfPickerValue:(NSString *)name value:(id)value;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
