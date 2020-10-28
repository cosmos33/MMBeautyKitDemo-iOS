//
//  MMVideoAssetsCollectionViewController.m
//  MDRecordSDK
//
//  Created by sunfei on 2019/4/25.
//  Copyright © 2019 sunfei. All rights reserved.
//

#import "MMVideoAssetsCollectionViewController.h"
#import "MMAssetGridViewCell.h"
@import Photos;

@interface MMVideoAssetsCollectionViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, readonly) PHFetchResult<PHAsset *> *fetchResult;

@property (nonatomic, strong) PHCachingImageManager *imageManger;
@property (nonatomic, assign) CGSize thumbnailSize;
@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, assign) CGFloat availableWidth;

@end

@implementation MMVideoAssetsCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.imageManger = [[PHCachingImageManager alloc] init];

    [self resetCachedAssets];
    [self.collectionView registerClass:[MMAssetGridViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)resetCachedAssets {
    [self.imageManger stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)viewWillLayoutSubviews {
    CGFloat width = self.view.bounds.size.width;
    if (@available(iOS 11.0, *)) {
        width = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets).size.width;
    }
    if (self.availableWidth != width) {
        self.availableWidth = width;
        float columnCount = floor(width / 80);
        float itemLength = (width - columnCount - 1) / columnCount;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
        layout.itemSize = CGSizeMake(itemLength, itemLength);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat scale = UIScreen.mainScreen.scale;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    CGSize cellSize = layout.itemSize;
    self.thumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

- (void)updateCachedAssets {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    
    CGRect visibleRect = (CGRect) {
        .origin = self.collectionView.contentOffset,
        .size = self.collectionView.bounds.size
    };
    
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
    CGFloat delta = fabs(CGRectGetMinY(preheatRect) - CGRectGetMinY(_previousPreheatRect));
    if (delta <= self.view.bounds.size.height / 3) {
        return;
    }
    
    NSDictionary *dic = [self differencesBetweenRectsWithOld:_previousPreheatRect new:preheatRect];
    NSMutableArray *addedAssets = [NSMutableArray array];
    for (NSValue *rect in dic[@"added"]) {
        NSArray<NSIndexPath *> *indexPaths = [self indexPathsForElementsForCollectionView:self.collectionView in:[rect CGRectValue]];
        for (NSIndexPath *indexPath in indexPaths) {
            [addedAssets addObject:[self.fetchResult objectAtIndex:indexPath.item]];
        }
    }
    
    NSMutableArray *removedAssets = [NSMutableArray array];
    for (NSValue *rect in dic[@"removed"]) {
        NSArray<NSIndexPath *> *indexPaths = [self indexPathsForElementsForCollectionView:self.collectionView in:[rect CGRectValue]];
        for (NSIndexPath *indexPath in indexPaths) {
            [removedAssets addObject:[self.fetchResult objectAtIndex:indexPath.item]];
        }
    }
    
    [_imageManger startCachingImagesForAssets:addedAssets targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    [_imageManger stopCachingImagesForAssets:removedAssets targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    
    _previousPreheatRect = preheatRect;
}

- (NSArray<NSIndexPath *> *)indexPathsForElementsForCollectionView:(UICollectionView *)view in:(CGRect)rect {
    NSArray<__kindof UICollectionViewLayoutAttributes *> *allLayoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    NSMutableArray<NSIndexPath *> *array = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attribute in allLayoutAttributes) {
        [array addObject:attribute.indexPath];
    }
    return [array copy];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MMAssetGridViewCell *cell = (MMAssetGridViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = [self.fetchResult objectAtIndex:indexPath.item];
    
    cell.representedAssetIdentifier = asset.localIdentifier;
    [self.imageManger requestImageForAsset:asset targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
            cell.thumbnailImage = result;
        }
    }];
    
    return cell;
}

- (NSDictionary<NSString *, NSArray<NSValue *> *> *)differencesBetweenRectsWithOld:(CGRect)old new:(CGRect)new {
    if (CGRectIntersectsRect(old, new)) {
        NSMutableArray *added = [NSMutableArray array];
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old));
            [added addObject:[NSValue valueWithCGRect:rect]];
        }
        
        if (CGRectGetMinY(old) > CGRectGetMinY(new)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMinY(new), new.size.width, CGRectGetMinY(old) - CGRectGetMinY(new));
            [added addObject:[NSValue valueWithCGRect:rect]];
        }
        
        NSMutableArray *removed = [NSMutableArray array];
        if (CGRectGetMaxY(new) < CGRectGetMaxY(old)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMaxY(old) - CGRectGetMaxY(new));
            [removed addObject:[NSValue valueWithCGRect:rect]];
        }
        
        if (CGRectGetMinY(old) < CGRectGetMinY(new)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMinY(old), new.size.width, CGRectGetMinY(new) - CGRectGetMinY(old));
            [removed addObject:[NSValue valueWithCGRect:rect]];
        }
        return @{ @"added" : added, @"removed" : removed };
    } else {
        return @{ @"added" : @[[NSValue valueWithCGRect:new]], @"removed" : @[[NSValue valueWithCGRect:old]]};
    }
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCachedAssets];
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    PHAsset *asset = [self.fetchResult objectAtIndex:indexPath.item];

    if (asset.mediaType == PHAssetMediaTypeImage) {
        NSLog(@"image");
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                    targetSize:CGSizeMake(720, 1280)
                                   contentMode:PHImageContentModeDefault
                                       options:options
                                 resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        }];
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        NSLog(@"video");
        //    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([asset isKindOfClass:[AVURLAsset class]]) {
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    //                MDPlayerPlaySingleVideoViewController *vc = [[MDPlayerPlaySingleVideoViewController alloc] init];
                    //                vc.item = [[MDVideoItem alloc] initWithDictionary:@{
                    //                                                                    @"videoUrl" : [[[urlAsset URL] fileReferenceURL] path],
                    //                                                                    @"cover" : @"",
                    //                                                                    @"feedId" : @""
                    //                                                                    }];
                    //                [self.navigationController pushViewController:vc animated:YES];
                } else {
                    //                [self.view makeToast:@"不能获取该视频地址" duration:1.5 position:CSToastPositionCenter];
                }
            });
        }];
    }
}

#pragma mark <PHPhotoLibraryChangeObserver>

- (void)photoLibraryDidChange:(PHChange *)changeInstance {

    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if (!changes) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_fetchResult = changes.fetchResultAfterChanges;
        
        if (changes.hasIncrementalChanges) {
            [self.collectionView performBatchUpdates:^{
                
                // remove
                NSIndexSet *removedIndexs = changes.removedIndexes;
                NSMutableArray *deleteIndexPaths = [NSMutableArray array];
                [removedIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                    [deleteIndexPaths addObject:indexPath];
                }];
                [self.collectionView deleteItemsAtIndexPaths:deleteIndexPaths];
                
                // insert
                NSIndexSet *inserted = changes.insertedIndexes;
                NSMutableArray *insertIndexPaths = [NSMutableArray array];
                [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                    [insertIndexPaths addObject:indexPath];
                }];
                [self.collectionView insertItemsAtIndexPaths:insertIndexPaths];
                
                // move
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    NSIndexPath *from = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                    NSIndexPath *to = [NSIndexPath indexPathForItem:toIndex inSection:0];
                    [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
                }];
                
            } completion:^(BOOL finished) {
                
            }];
        } else {
            [self.collectionView reloadData];
        }
        [self resetCachedAssets];
    });
}

@end
