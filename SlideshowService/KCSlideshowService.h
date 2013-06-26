//
//  KCSlideshowService.h
//  KinCentral
//
//  Created by Yury Grinenko on 21.11.12.
//
//

@interface KCSlideshowService : NSObject

+ (KCSlideshowService *)sharedInstance;
- (void)resetIdleTimer;
- (void)stopIdleTimer;
- (void)stopSlideshow;
- (void)setSlideshowEnabled;
- (void)setSlideshowDisabled;
- (void)updatePrimaryEnabledFlagValue;

@end
