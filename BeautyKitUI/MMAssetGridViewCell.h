//
//  MMAssetGridViewCell.h
//  MDRecordSDK
//
//  Created by sunfei on 2019/4/26.
//  Copyright © 2019 sunfei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMAssetGridViewCell : UICollectionViewCell

@property (nonatomic, copy) NSString *representedAssetIdentifier;

@property (nonatomic, strong) UIImage *thumbnailImage;

@end

NS_ASSUME_NONNULL_END
