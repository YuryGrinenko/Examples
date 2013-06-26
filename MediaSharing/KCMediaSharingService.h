//
//  KCMediaSharingService.h
//  KinCentral
//
//  Created by Yury Grinenko on 29.11.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Domain/KCMultipartRequestHTTP.h>

@interface KCMediaSharingService : NSObject

+ (KCMediaSharingService *)sharedInstance;
- (void)setPhotoToShare:(UIImage *)photoToShare thumbnail:(UIImage *)thumbnailImage;
- (void)setVideoToShareUrl:(NSURL *)videoToShareUrl;
- (void)stopRequest:(KCMultipartRequestHTTP *)request;
- (NSArray *)sharingRequests;

@end
