//
//  KCTableViewSectionController.m
//  KinCentral
//
//  Created by Yury Grinenko on 07.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import "KCTableViewSectionController.h"

@interface KCTableViewSectionController ()

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) BOOL visible;

@end

@implementation KCTableViewSectionController

- (id)init {
    self = [super init];
    if (self) {
        _visible = YES;
        _dataArray = [NSMutableArray array];
    }
    return self;
}

- (void)setDataArray:(NSArray *)dataArray {
    _dataArray = [dataArray mutableCopy];
}

- (NSInteger)numberOfItems {
    if (_visible) {
        return [self realNumberOfItems];
    }
    return 0;
}

- (NSInteger)realNumberOfItems {
    return [_dataArray count];
}

- (NSObject *)itemForIndex:(NSInteger)index {
    if (_visible) {
        return [_dataArray objectAtIndex:index];
    }
    return nil;
}

- (void)invertVisibility {
    _visible = !_visible;
}

- (BOOL)isVisible {
    return _visible;
}

- (void)removeItemAtIndex:(NSInteger)index {
    [_dataArray removeObjectAtIndex:index];
}

@end
