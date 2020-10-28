//
//  MMCameraTabSegmentView.m
//  MMBeautyKit_Example
//
//  Created by sunfei on 2020/7/8.
//  Copyright © 2020 sunfei_fish@sina.cn. All rights reserved.
//

#import "MMCameraTabSegmentView.h"

@implementation MMSegmentItem

@end

@interface MMCameraTabSegmentView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, copy) MMSegmentItem *currentItem;
@property (nonatomic, strong) UILabel *contetLabel;
@property (nonatomic, strong) UISlider *slider;
 
@end

@implementation MMCameraTabSegmentView

- (void)setItems:(NSArray<MMSegmentItem *> *)items {
    _items = items;
    
    self.currentItem = items.firstObject;

    UICollectionView *collectionView = [self viewWithTag:34];
    [collectionView reloadData];
}

- (void)setCurrentItem:(MMSegmentItem *)currentItem {
    _currentItem = currentItem;
    UISlider *slider = [self viewWithTag:33];
    slider.value = currentItem.intensity;
    self.contetLabel.text = [NSString stringWithFormat:@"%.1f", slider.value];
    
    self.slider.minimumValue = currentItem.begin;
    self.slider.maximumValue = currentItem.end;
    
    !self.clickedHander ?: self.clickedHander(currentItem);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        UILabel *label = [[UILabel alloc] init];
        label.tag = 35;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = @"0.0";
        label.textColor = UIColor.redColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:18];
        _contetLabel = label;
        
        UISlider *slider = [[UISlider alloc] init];
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.tag = 33;
        slider.continuous = YES;
        slider.minimumValue = 0;
        slider.maximumValue = 1.0;
        slider.value = 1.0;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        _slider = slider;
        
        UIStackView *hStack = [[UIStackView alloc] initWithArrangedSubviews:@[slider, label]];
        hStack.translatesAutoresizingMaskIntoConstraints = NO;
        hStack.alignment = UIStackViewAlignmentCenter;
        hStack.distribution = UIStackViewDistributionEqualSpacing;
        hStack.axis = UILayoutConstraintAxisHorizontal;
        hStack.spacing = 8;
        [self addSubview:hStack];
        
        [hStack.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [hStack.widthAnchor constraintEqualToConstant:260].active = YES;
        [hStack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        
        [slider.widthAnchor constraintEqualToConstant:200].active = YES;
        
        [label.widthAnchor constraintEqualToConstant:52].active = YES;
        [label.heightAnchor constraintEqualToConstant:40].active = YES;
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(80, 80);
        layout.minimumLineSpacing = 8;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.tag = 34;
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.clipsToBounds = NO;
        [self addSubview:collectionView];
        
        [collectionView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [collectionView.topAnchor constraintEqualToAnchor:hStack.bottomAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [collectionView.heightAnchor constraintEqualToConstant:100].active = YES;
        
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UILabel *label = [cell viewWithTag:23];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        label.tag = 23;
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = UIColor.redColor;
    }
    label.text = self.items[indexPath.row].name;
    [cell.contentView addSubview:label];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentItem = self.items[indexPath.row];
}

- (void)sliderValueChanged:(UISlider *)slider {
    self.contetLabel.text = [NSString stringWithFormat:@"%.1f", slider.value];
    !self.sliderValueChanged ?: self.sliderValueChanged(self.currentItem, slider.value);
}

@end
