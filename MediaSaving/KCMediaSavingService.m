//
//  KCMediaSavingService.m
//  KinCentral
//
//  Created by Yury Grinenko on 04.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import "KCMediaSavingService.h"

@implementation KCMediaSavingService

+ (void)saveImageWithUrl:(NSURL *)url {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    AFImageRequestOperation *saveImageOperation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
        return image;
    } success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_STOP object:nil];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
        }];
        [KCProgressHUD showSuccessWithStatus:KCSuccessMessagesStruct.photoSaved];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_STOP object:nil];
        if (error.code == 404) {
            [KCProgressHUD showErrorWithStatus:KCRequestsErrorMessagesStruct.removedPost];
        }
        else if (error.code > 0) {
            [KCProgressHUD showErrorWithStatus:KCRequestsErrorMessagesStruct.savePhoto];
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_START object:nil];
    [saveImageOperation start];
}

+ (void)saveVideoWithUrl:(NSURL *)url {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    AFHTTPRequestOperation *downloadVideoDataOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [downloadVideoDataOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_STOP object:nil];
        NSData *videoData = [NSData dataWithData:responseObject];
        [self saveToCameraRollVideoData:videoData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_STOP object:nil];
        if (error.code == 404) {
            [KCProgressHUD showErrorWithStatus:KCRequestsErrorMessagesStruct.removedPost];
        }
        else if (error.code > 0) {
            [KCProgressHUD showErrorWithStatus:KCRequestsErrorMessagesStruct.saveVideo];
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_DID_START object:nil];
    [downloadVideoDataOperation start];
}

+ (void)saveToCameraRollVideoData:(NSData *)data {
    NSString *tempFilePath = [self pathForTempFile];
    if ([self writeVideoData:data toFile:tempFilePath]) {
        NSURL *videoFileUrl = [NSURL URLWithString:tempFilePath];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:videoFileUrl completionBlock:^(NSURL *assetURL, NSError *error) {
            [KCProgressHUD showSuccessWithStatus:KCSuccessMessagesStruct.saveVideo];
            [self removeFileWithPath:tempFilePath];
        }];
    }
    else {
        [KCProgressHUD showErrorWithStatus:KCRequestsErrorMessagesStruct.saveVideo];
    }
}

+ (NSString *)pathForTempFile {
    NSString *tempDirectory = NSTemporaryDirectory();
    return [tempDirectory stringByAppendingPathComponent:@"video.m4v"];
}

+ (BOOL)writeVideoData:(NSData *)data toFile:(NSString *)fileName {
    NSError *error;
    [data writeToFile:fileName options:NSDataWritingAtomic error:&error];
    if (error) {
        return NO;
    }
    return YES;
}

+ (void)removeFileWithPath:(NSString *)tempFilePath {
    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
}

@end
