//
//  TIM_Push.m
//  TIM
//
//  Created by 马拉古 on 2018/5/30.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM_Push.h"
#import <UIKit/UIKit.h>
@implementation TIM_Push
+ (void)registerForRemoteNotifications:(NSDictionary*)launchOptions;
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                                                             settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                                                             categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification)
    {
//        [RCTTIMPush didReceiveNotification:notification];
    }
}

+ (void)registerDeviceToken:(NSData *)deviceToken withBusiId:(unsigned int)busiId
{
   
}

+(void)registerDeviceToken:(NSData *)deviceToken withBusiId:(unsigned int)busiId succ:(void (^)(BOOL))suc fail:(void (^)(int, NSString *))fail{
    TIMTokenParam * param = [[TIMTokenParam alloc] init];
    
    [param setToken:deviceToken];
    [param setBusiId:busiId];
    
    [[TIMManager sharedInstance] setToken:param succ:^{
        suc(YES);
    } fail:^(int code, NSString *msg) {
        fail(code,msg);
    }];
}
+(void)doEnterForegroundSucc:(responseSucceed)succ fail:(responseFail)fail{
    [[TIMManager sharedInstance] doForeground:^() {
        succ(YES);
    } fail:^(int code, NSString * err) {
        fail(code,err);
    }];
}

+(void)doEnterBackgroundSucc:(responseSucceed)succ fail:(responseFail)fail{

//    NSUInteger unReadCount = [[IMAPlatform sharedInstance].conversationMgr unReadMessageCount];
    NSArray *conversationArr = [[TIMManager sharedInstance]getConversationList];
    __block int unreadMsg = 0;
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        for (TIMConversation *conversation in conversationArr) {
            unreadMsg += [conversation getUnReadMessageNum];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            TIMBackgroundParam  *param = [[TIMBackgroundParam alloc] init];
            [param setC2cUnread:unreadMsg];
            [[TIMManager sharedInstance] doBackground:param succ:^() {
                
            } fail:^(int code, NSString * err) {
                
            }];
        });
    });
}

+ (void)didReceiveNotification:(NSDictionary*)notification
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:kTIMReceiveNotification object:[notification objectForKey:@"ext"]];
}
@end
