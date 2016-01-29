//
//  HMImageGridViewController.m
//  HMImagePicker
//
//  Created by 刘凡 on 16/1/26.
//  Copyright © 2016年 itheima. All rights reserved.
//

#import "HMImageGridViewController.h"
#import "HMImagePickerGlobal.h"
#import "HMAlbum.h"
#import "HMImageGridCell.h"
#import "HMImageGridViewLayout.h"
#import "HMSelectCounterButton.h"
#import "HMPreviewViewController.h"

static NSString *const HMImageGridViewCellIdentifier = @"HMImageGridViewCellIdentifier";

@interface HMImageGridViewController () <HMImageGridCellDelegate>

@end

@implementation HMImageGridViewController {
    /// 相册模型
    HMAlbum *_album;
    /// 选中素材数组
    NSMutableArray <PHAsset *>*_selectedAssets;
    /// 最大选择图像数量
    NSInteger _maxPickerCount;
    
    /// 预览按钮
    UIBarButtonItem *_previewItem;
    /// 完成按钮
    UIBarButtonItem *_doneItem;
    /// 选择计数按钮
    HMSelectCounterButton *_counterButton;
}

#pragma mark - 构造函数
- (instancetype)initWithAlbum:(HMAlbum *)album
               selectedAssets:(NSMutableArray<PHAsset *> *)selectedAssets
               maxPickerCount:(NSInteger)maxPickerCount {
    
    HMImageGridViewLayout *layout = [[HMImageGridViewLayout alloc] init];
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _album = album;
        _selectedAssets = selectedAssets;
        _maxPickerCount = maxPickerCount;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - HMImageGridCellDelegate
- (void)imageGridCell:(HMImageGridCell *)cell didSelected:(BOOL)selected {
    
    // 判断是否已经到达最大数量
    if (_selectedAssets.count == _maxPickerCount && selected) {
        
        NSString *message = [NSString stringWithFormat:@"最多只能选择 %zd 张照片", _maxPickerCount];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        [cell clickSelectedButton];
        
        return;
    }
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    PHAsset *asset = [_album assetWithIndex:indexPath.item];
    
    if (selected) {
        [_selectedAssets addObject:asset];
    } else {
        [_selectedAssets removeObject:asset];
    }
    
    [self updateCounter];
}

/// 更新计数显示
- (void)updateCounter {
    _counterButton.count = _selectedAssets.count;
    _doneItem.enabled = _counterButton.count > 0;
    _previewItem.enabled = _counterButton.count > 0;
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _album.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HMImageGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:HMImageGridViewCellIdentifier forIndexPath:indexPath];
    
    cell.imageView.image = [_album emptyImageWithSize:cell.bounds.size];
    [_album requestThumbnailWithAssetIndex:indexPath.item Size:cell.bounds.size completion:^(UIImage * _Nonnull thumbnail) {
        cell.imageView.image = thumbnail;
    }];
    cell.selectedButton.selected = [_selectedAssets containsObject:[_album assetWithIndex:indexPath.item]];
    
    cell.delegate = self;
    
    return cell;
}

#pragma mark - 监听方法
- (void)clickPreviewButton {
    HMPreviewViewController *preview = [[HMPreviewViewController alloc] init];
    
    [self.navigationController pushViewController:preview animated:YES];
}

- (void)clickFinishedButton {
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:HMImagePickerDidSelectedNotification
     object:self
     userInfo:@{HMImagePickerDidSelectedAssetsKey: _selectedAssets}];
}

- (void)clickCloseButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 设置界面
- (void)prepareUI {
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    self.title = _album.title;
    
    // 工具条
    _previewItem = [[UIBarButtonItem alloc] initWithTitle:@"预览" style:UIBarButtonItemStylePlain target:self action:@selector(clickPreviewButton)];
    _previewItem.enabled = NO;
    
    _counterButton = [[HMSelectCounterButton alloc] init];
    UIBarButtonItem *counterItem = [[UIBarButtonItem alloc] initWithCustomView:_counterButton];
    
    _doneItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(clickFinishedButton)];
    _doneItem.enabled = NO;
    
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[_previewItem, spaceItem, counterItem, _doneItem];
    
    // 取消按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(clickCloseButton)];
    
    // 注册可重用 cell
    [self.collectionView registerClass:[HMImageGridCell class] forCellWithReuseIdentifier:HMImageGridViewCellIdentifier];
    
    // 更新计数器显示
    [self updateCounter];
}

@end
