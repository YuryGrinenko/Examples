//
//  KCKinListTableViewDelegate.h
//  KinCentral
//
//  Created by Yury Grinenko on 05.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCYourKinListViewController;
@protocol KCKinCellPressing;
@protocol KCKinHeaderButtonPressing;

@interface KCKinListTableViewDelegate : NSObject <UITableViewDataSource, UITableViewDelegate, KCKinCellPressing, KCKinHeaderButtonPressing>

- (id)initWithTableView:(UITableView *)tableView delegate:(KCYourKinListViewController *)delegate;

- (void)setKins:(NSArray *)kinsArray;
- (void)setRecommendations:(NSArray *)recommendationsArray;
- (void)setInvitesUserSent:(NSArray *)invitesUserSent;
- (void)setInvitesUserReceived:(NSArray *)invitesUserReceived;

@end
