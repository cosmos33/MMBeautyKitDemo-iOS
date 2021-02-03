//
//  ViewController.m
//  MMZegoBeautyKitDemo
//
//  Created by sunfei on 2021/2/3.
//  Copyright © 2021 sunfei. All rights reserved.
//

#import "ViewController.h"
#import "MMZegoBeautyKitViewController.h"
@import Photos;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray *items;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.items = @[@"异步pixelBuffer", @"同步pixelbuffer"];
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MMViewControllerCell"];
    
    [self.view addSubview:self.tableView];
}

#pragma mark - tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.row) {
        case 0:
        {
        MMZegoBeautyKitViewController *vc = [[MMZegoBeautyKitViewController alloc] init];
        vc.bufferType = ZegoVideoBufferTypeAsyncPixelBuffer;
        [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
        MMZegoBeautyKitViewController *vc = [[MMZegoBeautyKitViewController alloc] init];
        vc.bufferType = ZegoVideoBufferTypeSyncPixelBuffer;
        [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
        MMZegoBeautyKitViewController *vc = [[MMZegoBeautyKitViewController alloc] init];
        vc.bufferType = ZegoVideoBufferTypeAsyncI420PixelBuffer;
        [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 3:
        {
        MMZegoBeautyKitViewController *vc = [[MMZegoBeautyKitViewController alloc] init];
        vc.bufferType = ZegoVideoBufferTypeAsyncNV12PixelBuffer;
        [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - tableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MMViewControllerCell" forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}

@end

