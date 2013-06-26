//
//  KCMediaSavingService.h
//  KinCentral
//
//  Created by Yury Grinenko on 04.12.12.
//  Copyright (c) 2012 111Minutes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCMediaSavingService : NSObject

+ (void)saveVideoWithUrl:(NSURL *)url;
+ (void)saveImageWithUrl:(NSURL *)url;

@end
