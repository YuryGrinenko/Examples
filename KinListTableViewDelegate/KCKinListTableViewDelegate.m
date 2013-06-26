//
//  KCKinListTableViewDelegate.m
//  KinCentral
//
//  Created by Yury Grinenko on 05.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import "KCKinListTableViewDelegate.h"
#import "KCYourKinListViewController.h"
#import "KCKinListCell.h"
#import "KCKinHeaderView.h"
#import "KCKinListService.h"

#import "KCTableViewSectionController.h"

typedef enum {
    kKinsMode = 0,
    kInvitesMode = 1
} ControllerMode;

static const NSInteger kUserSection = 0;
static const NSInteger kReceivedInvitesSection = 1;
static const NSInteger kSuggestedKinsSection = 2;
static const NSInteger kSentInvitesSection = 3;
static const NSInteger kKinsSection = 4;
static const NSInteger kFakeKinsSection = 5;
static const NSInteger kOtherFakeKinsSection = 6;

static const NSInteger kHeaderViewHeight = 40;
static const NSInteger kNotLastCellInSectionHeight = 57;
static const NSInteger kLastCellInSectionHeight = 59;

@interface KCKinListTableViewDelegate ()

@property (nonatomic, weak) KCYourKinListViewController *parentController;
@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, strong) NSArray *invitationsUserSentArray;
@property (nonatomic, strong) NSArray *headerTextArray;
@property (nonatomic, strong) NSArray *sectionsControllersArray;

@end

@implementation KCKinListTableViewDelegate

- (id)initWithTableView:(UITableView *)tableView delegate:(KCYourKinListViewController *)delegate {
    self = [super init];
    if (self) {
        _parentController = delegate;
        _tableView = tableView;
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [self createDataSourcesArrays];
    }
    return self;
}

- (void)createDataSourcesArrays {
    _headerTextArray = @[@"", KCKinListSectionsStruct.receivedInvites, KCKinListSectionsStruct.suggestedKins, KCKinListSectionsStruct.sentInvites, KCKinListSectionsStruct.kins, KCKinListSectionsStruct.suggestedRelations, KCKinListSectionsStruct.moreSuggestedRelations];
    
    KCTableViewSectionController *userSectionController = [KCTableViewSectionController new];
    KCTableViewSectionController *receivedInvitesSectionController = [KCTableViewSectionController new];
    KCTableViewSectionController *suggestionsController = [KCTableViewSectionController new];
    KCTableViewSectionController *sentInvitesController = [KCTableViewSectionController new];
    KCTableViewSectionController *kinsSectionController = [KCTableViewSectionController new];
    KCTableViewSectionController *fakeKinsSectionController = [KCTableViewSectionController new];
    KCTableViewSectionController *otherFakeKinsSectionController = [KCTableViewSectionController new];
    
    _sectionsControllersArray = [NSArray arrayWithObjects:userSectionController, receivedInvitesSectionController, suggestionsController, sentInvitesController, kinsSectionController, fakeKinsSectionController, otherFakeKinsSectionController, nil];
}

- (void)createUserSectionArray {
    NSArray *userArray = [NSArray arrayWithObject:[KCProfileService sharedInstance].currentUser];
    [self setDataArray:userArray forSection:kUserSection];
}

- (void)setKins:(NSArray *)kinsArray {
    [self setDataArray:kinsArray forSection:kKinsSection];
    [self createFakeKinsArray];
    [self createOtherFakeKinsArray];
    [self createUserSectionArray];
}

- (void)setRecommendations:(NSArray *)recommendationsArray {
    [self setDataArray:recommendationsArray forSection:kSuggestedKinsSection];
}

- (void)createFakeKinsArray {
    NSArray *fakeKinsArray = [KCKinListService fakeKinsArray];
    [self setDataArray:fakeKinsArray forSection:kFakeKinsSection];
}

- (void)createOtherFakeKinsArray {
    NSArray *otherFakeKinsArray = [KCKinListService otherFakeKinsArray];
    [self setDataArray:otherFakeKinsArray forSection:kOtherFakeKinsSection];
}

- (void)setInvitesUserSent:(NSArray *)invitesUserSent {
    [self setDataArray:invitesUserSent forSection:kSentInvitesSection];
}

- (void)setInvitesUserReceived:(NSArray *)invitesUserReceived {
    [self setDataArray:invitesUserReceived forSection:kReceivedInvitesSection];
}

- (void)setDataArray:(NSArray *)array forSection:(NSInteger)section {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
    [sectionController setDataArray:array];
}

- (BOOL)isVisibleHeaderInSection:(NSInteger)section {
    if (section > 0) {
        KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
        return ([sectionController numberOfItems] > 0);
    }
    return NO;
}

- (void)selectKinCellAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kUserSection:
            [_parentController performSegueWithIdentifier:@"goProfile" sender:self];
            break;
        case kReceivedInvitesSection:
            [_parentController performSegueWithIdentifier:@"goKinRequest" sender:self];
            break;
        case kSentInvitesSection:
            [_parentController performSegueWithIdentifier:@"goInviteDetails" sender:self];
            break;
        case kKinsSection:
            [_parentController performSegueWithIdentifier:@"goKinDetails" sender:self];
            break;
        case kSuggestedKinsSection:
            [_parentController performSegueWithIdentifier:@"goAcceptRecommendation" sender:self];
            break;
        case kFakeKinsSection: {
            KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:kFakeKinsSection];
            KCKin *kin = (KCKin *)[sectionController itemForIndex:indexPath.row];
            [_parentController performSegueWithIdentifier:@"goMultipleInvite" sender:kin];
            break;
        }
        case kOtherFakeKinsSection: {
            KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:kOtherFakeKinsSection];
            KCKin *kin = (KCKin *)[sectionController itemForIndex:indexPath.row];
            [_parentController performSegueWithIdentifier:@"goMultipleInvite" sender:kin];
            break;
        }
        default:
            break;
    }
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
    return [sectionController numberOfItems];
}

- (BOOL)isHintShowed {
    return (_tableView.frame.origin.y > 0);
}

#pragma mark -
#pragma mark KCKinHeaderButtonPressing
- (void)headerButtonDidPressed:(UIButton *)sender {
    NSInteger section = sender.tag;
    if (section != kFakeKinsSection) {
        [self updateRowsInSection:section];
    }
}

- (void)updateRowsInSection:(NSInteger)section {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
    [_tableView beginUpdates];
    
    if ([sectionController isVisible]) {
        [_tableView deleteRowsAtIndexPaths:[self indexPathesInSection:section] withRowAnimation:UITableViewRowAnimationFade];
        [sectionController invertVisibility];
    }
    else {
        [sectionController invertVisibility];
        [_tableView insertRowsAtIndexPaths:[self indexPathesInSection:section] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_tableView endUpdates];
}

- (NSArray *)indexPathesInSection:(NSInteger)section {
    NSMutableArray *indexPathes = [NSMutableArray array];
    NSInteger rowsNumberInSection = [self numberOfRowsInSection:section];
    for (int i = 0; i < rowsNumberInSection; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPathes addObject:indexPath];
    }
    return indexPathes;
}

- (BOOL)isLastCellInSectionWithIndexPath:(NSIndexPath *)indexPath {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:indexPath.section];
    return (indexPath.row == [sectionController numberOfItems] - 1);
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_sectionsControllersArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KCKinListCell *cell = (KCKinListCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[KCKinListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:indexPath.section];
    NSObject *contentObject = [sectionController itemForIndex:indexPath.row];
    
    [cell fillWithObject:contentObject indexPath:indexPath delegate:self];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectKinCellAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
    if (section == kUserSection || ([sectionController realNumberOfItems] == 0)) {
        return 0;
    }
    return kHeaderViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:section];
    if (section == kUserSection || [sectionController realNumberOfItems] == 0) {
        return nil;
    }
    
    NSString *sectionHeaderText = [_headerTextArray objectAtIndex:section];
    NSInteger itemsNumber = [sectionController realNumberOfItems];
    BOOL hideable = YES;
    BOOL showItemsNumber = YES;
    
    if (section == kFakeKinsSection) {
        showItemsNumber = NO;
        hideable = NO;
    }
    else if (section == kOtherFakeKinsSection) {
        showItemsNumber = NO;
    }
        
    return [KCKinHeaderView headerViewForSection:section withText:sectionHeaderText itemsNumber:itemsNumber delegate:self opened:[sectionController isVisible] hideable:hideable showItemsNumber:showItemsNumber];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLastCellInSectionWithIndexPath:indexPath]) {
        return kLastCellInSectionHeight;
    }
    return kNotLastCellInSectionHeight;
}

#pragma mark -
#pragma mark KCKinCellPressing
- (void)deleteButtonDidPressedOnCellWithIndexPath:(NSIndexPath *)indexPath {
    KCTableViewSectionController *sectionController = [_sectionsControllersArray objectAtIndex:indexPath.section];
    void (^removingRowAnimationBlock)(void) = ^{
        [_tableView beginUpdates];
        
        [sectionController removeItemAtIndex:indexPath.row];
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        
        [_tableView endUpdates];
    };
    
    if (indexPath.section == kSuggestedKinsSection) {
        KCRecommendation *recommendation = (KCRecommendation *)[sectionController itemForIndex:indexPath.row];
        [_parentController removeRecommendation:recommendation withSuccessBlock:^{
            removingRowAnimationBlock();
        }];
    }
    else {
        KCKin *fakeKin = (KCKin *)[sectionController itemForIndex:indexPath.row];
        [KCKinListService removeNecessaryKin:fakeKin];
        removingRowAnimationBlock();
    }
}

@end
