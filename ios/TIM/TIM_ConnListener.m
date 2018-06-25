//
//  TIM_ConnListener.m
//  TIM
//
//  Created by 马拉古 on 2018/5/28.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM_ConnListener.h"
#import "Define.h"
@implementation TIM_ConnListener
-(instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}
/**
 *  网络连接成功
 */
- (void)onConnSucc{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:@"0" forKey:@"code"];
    [dic setValue:@"连接成" forKey:@"err"];
    [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_CONNECTION object:self userInfo:dic];
}

/**
 *  网络连接失败
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onConnFailed:(int)code err:(NSString*)err{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:@(code) forKey:@"code"];
    [dic setValue:err forKey:@"err"];
    [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_CONNECTION object:self userInfo:dic];
}

/**
 *  网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onDisconnect:(int)code err:(NSString*)err{
    
}


/**
 *  连接中
 */
- (void)onConnecting{
    
}
@end
