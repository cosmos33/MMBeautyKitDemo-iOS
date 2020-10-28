//
//  MMAssetGridViewCell.m
//  MDRecordSDK
//
//  Created by sunfei on 2019/4/26.
//  Copyright © 2019 sunfei. All rights reserved.
//

#import "MMAssetGridViewCell.h"

@interface MMAssetGridViewCell()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation MMAssetGridViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setupViews {
    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    [self.imageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor].active = YES;
    [self.imageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor].active = YES;
    [self.imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active= YES;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    
    self.imageView.image = thumbnailImage;
}

@end
