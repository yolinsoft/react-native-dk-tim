//
//  TIM_ConnListener.m
//  TIM
//
//  Created by 马拉古 on 2018/5/28.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM_EventListener.h"
#import "TIM_MsgHandler.h"
@implementation TIM_EventListener
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

#pragma mark TIMMessageRevokeListener delegate
- (void)onRevokeMessage:(TIMMessageLocator*)locator{
    
    NSDictionary *dic = [locator yy_modelToJSONObject];
    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_MsgLocator object:nil userInfo:[dic mutableCopy]];
}

/**
 *  上传进度回调
 *
 *  @param msg      正在上传的消息
 *  @param elemidx  正在上传的elem的索引
 *  @param taskid   任务id
 *  @param progress 上传进度
 */
- (void)onUploadProgressCallback:(TIMMessage*)msg elemidx:(uint32_t)elemidx taskid:(uint32_t)taskid progress:(uint32_t)progress{
    
    
    NSNumber *elemidxNum = [NSNumber numberWithUnsignedInteger:elemidx];
    NSNumber *taskidNum = [NSNumber numberWithUnsignedInteger:taskid];
    NSNumber *progressNum = [NSNumber numberWithUnsignedInteger:progress];
    NSDictionary *msgDic = [TIM_MsgHandler createMessage:msg];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:elemidxNum forKey:@"elemidx"];
    [param setValue:taskidNum forKey:@"taskid"];
    [param setValue:progressNum forKey:@"progress"];
    [param setObject:msgDic forKey:@"msg"];
     [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_UploaderProgress object:nil userInfo:[param mutableCopy]];
}

#pragma mark TIMGroupEventListener delegate
/**
 *  群tips回调
 *
 *  @param elem  群tips消息
 */
- (void)onGroupTipsEvent:(TIMGroupTipsElem*)elem{
    NSDictionary *dic = [elem yy_modelToJSONObject];
    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_groupTips object:nil userInfo:dic];
}
@end
