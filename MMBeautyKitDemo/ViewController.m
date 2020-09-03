//
//  ViewController.m
//  MMBeautyKitDemo
//
//  Created by sunfei on 2019/12/25.
//  Copyright © 2019 sunfei. All rights reserved.
//

#import "ViewController.h"
#import "MMCameraViewController.h"
#import "MMVideoAssetsCollectionViewController.h"
#import "MMQiNiuViewController.h"
#import "MMTXViewController.h"
@import Photos;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray *items;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.items = @[@"相机", @"七牛", @"腾讯推流"];
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
        MMCameraViewController *vc = [[MMCameraViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1: {
        MMQiNiuViewController *qiniuVC = [MMQiNiuViewController new];
        [self.navigationController pushViewController:qiniuVC animated:true];
        }
            break;
        case 2:
        {
        MMTXViewController *vc = [[MMTXViewController alloc] init];
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
