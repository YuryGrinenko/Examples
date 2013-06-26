//
//  KCSlideshowService.h
//  KinCentral
//
//  Created by Yury Grinenko on 21.11.12.
//
//

#import "KCSlideshowService.h"

#import "KCSlideshowViewController.h"
#import "KCNavigationHelper.h"

static const NSInteger kNumberOfPostsInSlideshow = 20;
static const NSInteger kIdleTimeIntervalBeforeSlideShowInSeconds = 30;
static const NSInteger kSlideshowTimerInterval = 3;

@interface KCSlideshowService ()

@property (nonatomic, strong) NSTimer *idleTimer;
@property (nonatomic, strong) NSMutableArray *photosUrlsArray;
@property (nonatomic, strong) KCSlideshowViewController *slideshowController;
@property (nonatomic, assign) BOOL primaryEnabledFlag;
@property (nonatomic, assign) BOOL isShowingSlideshow;
@property (nonatomic, assign) BOOL isEnabled;

@end

@implementation KCSlideshowService

+ (KCSlideshowService *)sharedInstance {
    static KCSlideshowService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [KCSlideshowService new];
        sharedInstance.isEnabled = NO;
        sharedInstance.photosUrlsArray = [NSMutableArray array];
        [sharedInstance addObservers];
    });
    return sharedInstance;
}

- (void)dealloc {
    [self removeObservers];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPosts) name:NEED_RELOAD_SLIDESHOW object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEED_RELOAD_SLIDESHOW object:nil];
}

- (void)startIdleTimer {
    if (_isEnabled) {
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:kIdleTimeIntervalBeforeSlideShowInSeconds target:self selector:@selector(showSlideshow:) userInfo:nil repeats:NO];
    }
}

- (void)stopIdleTimer {
    [_idleTimer invalidate];
    _idleTimer = nil;
}

- (void)resetIdleTimer {
    if (_isShowingSlideshow) {
        [self stopSlideshow];
    }
    [self stopIdleTimer];
    [self startIdleTimer];
}

- (void)showSlideshow:(id)sender {
    if ([[KCProfileService sharedInstance] isUserLogined] && _primaryEnabledFlag && [_photosUrlsArray count] > 0 && !_isShowingSlideshow) {
        _slideshowController = (KCSlideshowViewController *)[KCNavigationHelper controllerWithStoryboardId:@"Slideshow"];
        [_slideshowController setImagesUrlsArray:_photosUrlsArray];
        [_slideshowController setSlideshowTimeInterval:kSlideshowTimerInterval];
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
        
        UIView *slideshowView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
        [_slideshowController setParentView:slideshowView];
        [[UIApplication sharedApplication].keyWindow addSubview:slideshowView];
        [slideshowView addSubview:_slideshowController.view];
        
        _isShowingSlideshow = YES;
    }
}
- (void)stopSlideshow {
    if (_isShowingSlideshow) {
        [_slideshowController dismiss];
        _slideshowController = nil;
        _isShowingSlideshow = NO;
    }
    [self resetIdleTimer];
}

- (void)updatePrimaryEnabledFlagValue {
    _primaryEnabledFlag = [KCProfileService sharedInstance].currentUser.slideshowEnabled;
    [self setSlideshowEnabled];
}

- (void)setSlideshowEnabled {
    if (!_isEnabled && _primaryEnabledFlag) {
        _isEnabled = YES;
        [self loadPosts];
        [self startIdleTimer];
    }
}

- (void)setSlideshowDisabled {
    _isEnabled = NO;
    [self stopIdleTimer];
}

#pragma mark -
#pragma mark Request
- (void)loadPosts {
    KCPaginationRequestHTTP *paginationRequest = [[KCStreamAPI sharedInstance] loadStreamWithOrder:nil];
    [paginationRequest setNumberOfObjectsPerPage:kNumberOfPostsInSlideshow];
    [paginationRequest addSuccessHandler:^(id response) {
        NSArray *receivedPostsArray = [NSArray arrayWithArray:[response objectForKey:@"posts"]];
        NSLog(@"successfully recieve  %i posts for slideshow", [receivedPostsArray count]);
        for (KCPost *post in receivedPostsArray) {
            [_photosUrlsArray addObject:post.thumbnailUrl];
        }
    }];
    [paginationRequest addErrorHandler:^void(NSError *error) {
        NSLog(@"loading posts for slideshow error = %@", error);
    }];
    [_photosUrlsArray removeAllObjects];
    [paginationRequest loadNextPage];
}

@end
