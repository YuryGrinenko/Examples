//
//  KCMediaSharingService.m
//  KinCentral
//
//  Created by Yury Grinenko on 29.11.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import "KCMediaSharingService.h"

#import "KCGraphicsHelper.h"

static const NSInteger kUploadConcurrencyLimit = 2;

@interface KCMediaSharingService ()

@property (nonatomic, strong) NSMutableArray *unfinishedRequestsArray;
@property (nonatomic, strong) NSMutableArray *executingRequestsArray;
@property (nonatomic, strong) NSMutableArray *waitingRequestsArray;
@property (nonatomic, strong) NSArray *stopedRequestsArray;

@end

@implementation KCMediaSharingService

+ (KCMediaSharingService *)sharedInstance {
    static KCMediaSharingService *sharedInstanse = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstanse = [KCMediaSharingService new];
    });
    return sharedInstanse;
}

- (id)init {
    self = [super init];
    if (self) {
        _unfinishedRequestsArray = [NSMutableArray array];
        _waitingRequestsArray = [NSMutableArray array];
        _executingRequestsArray = [NSMutableArray arrayWithCapacity:kUploadConcurrencyLimit];
        [self addApplicationStatesObservers];
    }
    return self;
}

- (void)dealloc {
    [self removeApplicationsStatesObservers];
}

- (void)addApplicationStatesObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeApplicationsStatesObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appWillResignActive {
    if ([_unfinishedRequestsArray count] > 0) {
        UIApplication *application = [UIApplication sharedApplication];
        __weak KCMediaSharingService *weakSelf = self;
        __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^(void) {
            [application endBackgroundTask:backgroundTaskIdentifier];
            [weakSelf stopAndSaveUnfinishedRequests];
        }];
    }
}

- (void)stopAndSaveUnfinishedRequests {
    _stopedRequestsArray = [NSArray arrayWithArray:_unfinishedRequestsArray];
    for (KCMultipartRequestHTTP *request in _executingRequestsArray) {
        [request stop];
    }
    [_unfinishedRequestsArray removeAllObjects];
    [_executingRequestsArray removeAllObjects];
}

- (void)appDidBecomeActive {
    if ([_stopedRequestsArray count] > 0) {
        _unfinishedRequestsArray = [NSMutableArray arrayWithArray:_stopedRequestsArray];
        for (int i = 0; i < kUploadConcurrencyLimit; i++) {
            [self tryToStartNextRequest];
        }
    }
}

- (void)setPhotoToShare:(UIImage *)photoToShare thumbnail:(UIImage *)thumbnailImage {
    [self sharePhoto:photoToShare thumbnailImage:thumbnailImage];
}

- (void)setVideoToShareUrl:(NSURL *)videoToShareUrl {
    UIImage *thumbnailImage = [KCGraphicsHelper getThumbnailImageForVideoWithUrl:videoToShareUrl];
    [self shareVideoWithUrl:videoToShareUrl thumbnailImage:thumbnailImage];
}

- (void)addRequest:(KCMultipartRequestHTTP *)request {
    [_unfinishedRequestsArray addObject:request];
    [_waitingRequestsArray addObject:request];
    [self tryToStartNextRequest];
}

- (void)removeRequest:(KCMultipartRequestHTTP *)request {
    [_executingRequestsArray removeObject:request];
    [_waitingRequestsArray removeObject:request];
    [_unfinishedRequestsArray removeObject:request];
    [self tryToStartNextRequest];
}

- (void)stopRequest:(KCMultipartRequestHTTP *)request {
    request.canceled = YES;
    [request stop];
    [KCProgressHUD showSuccessWithStatus:KCRequestsErrorMessagesStruct.canceledPostUpload];
    [self removeRequest:request];
    [self locallyReloadStream];
}

- (NSArray *)sharingRequests {
    return _unfinishedRequestsArray;
}

- (void)locallyReloadStream {
    [[NSNotificationCenter defaultCenter] postNotificationName:NEED_LOCALLY_RELOAD_STREAM object:nil];
}

- (void)scrollStreamToTop {
    NSDictionary *userInfo = @{@"reason" : @"sharing"};
    [[NSNotificationCenter defaultCenter] postNotificationName:NEED_SCROLL_STREAM_TO_TOP object:nil userInfo:userInfo];
}

- (void)finishSharingRequest:(KCMultipartRequestHTTP *)request withResponse:(id)response {
    [self removeRequest:request];
    [self locallyReloadStream];
    KCPost *newPost = [self postFromSharingRequest:request response:response];
    NSDictionary *userInfo = @{@"post": newPost};
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_DID_SHARE_POST object:nil userInfo:userInfo];
}

- (KCPost *)postFromSharingRequest:(KCMultipartRequestHTTP *)request response:(id)response {
    KCPost *post = [KCPost new];
    if ([response isKindOfClass:[NSArray class]] && [response count] > 0) {
        post = [response objectAtIndex:0];
        post.kin.relation.name = KCDefinesStruct.currentUserRelationName;
    }
    post.thumbnailImage = request.sharingDataThubnail;
    return post;
}

- (void)notifyDelegateOfRequest:(KCMultipartRequestHTTP *)request aboutSharingProgressWithTotalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSLog(@"totalBytesWritten = %i, totalBytesExpectedToWrite = %i", totalBytesWritten, totalBytesExpectedToWrite);
    if (request.delegate && [request.delegate respondsToSelector:@selector(updateRequestProgress)]) {
        double currentProgress = (double)totalBytesWritten/totalBytesExpectedToWrite;
        [request setCurrentProgress:currentProgress];
        [request.delegate updateRequestProgress];
    }
}

- (void)processSharingError:(NSError *)error errorMessage:(NSString *)errorMessage {
    NSLog(@"sharing error = %@", error);
    [KCProgressHUD showErrorWithStatus:errorMessage];
    [self locallyReloadStream];
}

- (void)tryToStartNextRequest {
    if ([_executingRequestsArray count] < kUploadConcurrencyLimit && [_waitingRequestsArray count] > 0) {
        KCMultipartRequestHTTP *request = [_waitingRequestsArray objectAtIndex:0];
        [self startRequest:request];
    }
}

- (void)startRequest:(KCMultipartRequestHTTP *)request {
    [_waitingRequestsArray removeObject:request];
    [_executingRequestsArray addObject:request];
    [self scrollStreamToTop];
    [request start];
    [self locallyReloadStream];
}

- (void)restartRequest:(KCMultipartRequestHTTP *)request {
    [request start];
}

#pragma mark -
#pragma mark Requests
- (void)sharePhoto:(UIImage *)image thumbnailImage:(UIImage *)thumbnailImage {
    KCMultipartRequestHTTP *request = (KCMultipartRequestHTTP *)[[KCMediaSharingAPI sharedInstance] sharePhoto:image thumbnailImage:thumbnailImage];
    [request setSharingDataThubnail:thumbnailImage];
    
    [self addHandlersToRequest:request];
    [self addRequest:request];
}

- (void)shareVideoWithUrl:(NSURL *)videoUrl thumbnailImage:(UIImage *)thumbnailImage {
    KCMultipartRequestHTTP *request = (KCMultipartRequestHTTP *)[[KCMediaSharingAPI sharedInstance] shareVideoWithUrl:videoUrl thumbnailImage:thumbnailImage];
    [request setSharingDataThubnail:thumbnailImage];
    
    [self addHandlersToRequest:request];
    [self addRequest:request];
}

- (void)addHandlersToRequest:(KCMultipartRequestHTTP *)request {
    __weak KCMultipartRequestHTTP *weakRequest = request;
    [request addSuccessHandler:^(id response) {
        [self finishSharingRequest:weakRequest withResponse:response];
    }];
    [request addErrorHandler:^void(NSError *error) {
        if (!weakRequest.canceled) {
            if (error.code == 0) {
                [self restartRequest:weakRequest];
            }
            else if (error.code > 0 && error.code != 401) {
                [self removeRequest:weakRequest];
                [self processSharingError:error errorMessage:KCRequestsErrorMessagesStruct.uploadPost];
            }
        }
    }];
    [request setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        [self notifyDelegateOfRequest:weakRequest aboutSharingProgressWithTotalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }];
}

@end
