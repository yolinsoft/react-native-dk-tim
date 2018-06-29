//
//  TIM_Push.h
//  TIM
//
//  Created by 马拉古 on 2018/5/30.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Define.h"
typedef void(^responseSucceed)(BOOL);
typedef void(^responseFail)(int,NSString *);
@interface TIM_Push : NSObject
+ (void)registerForRemoteNotifications:(NSDictionary*)launchOptions;
+ (void)registerDeviceToken:(NSData *)deviceToken withBusiId:(unsigned int)busiId succ:(void(^)(BOOL))suc fail:(void(^)(int,NSString *))fail;
+ (void)didReceiveNotification:(NSDictionary*)notification;
+ (void)doEnterBackgroundSucc:(responseSucceed)succ fail:(responseFail)fail;
+ (void)doEnterForegroundSucc:(responseSucceed)succ fail:(responseFail)fail;
@end
