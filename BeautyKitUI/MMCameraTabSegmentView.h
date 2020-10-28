//
//  MMCameraTabSegmentView.h
//  MMBeautyKit_Example
//
//  Created by sunfei on 2020/7/8.
//  Copyright © 2020 sunfei_fish@sina.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMBeautyRender.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMSegmentItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) CGFloat intensity;
@property (nonatomic, assign) CGFloat begin;
@property (nonatomic, assign) CGFloat end;

@end

@interface MMCameraTabSegmentView : UIView

@property (nonatomic, copy) NSArray<MMSegmentItem *> *items;

@property (nonatomic, copy) void(^sliderValueChanged)(MMSegmentItem *item, CGFloat intensity);
@property (nonatomic, copy) void(^clickedHander)(MMSegmentItem *);

@end

NS_ASSUME_NONNULL_END
