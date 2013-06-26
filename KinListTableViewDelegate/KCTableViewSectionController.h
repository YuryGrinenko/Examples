//
//  KCTableViewSectionController.h
//  KinCentral
//
//  Created by Yury Grinenko on 07.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCTableViewSectionController : NSObject

- (void)setDataArray:(NSArray *)dataArray;
- (NSInteger)numberOfItems;
- (NSInteger)realNumberOfItems;
- (NSObject *)itemForIndex:(NSInteger)index;
- (void)invertVisibility;
- (BOOL)isVisible;
- (void)removeItemAtIndex:(NSInteger)index;

@end
