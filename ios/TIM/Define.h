//
//  Define.h
//  TIM
//
//  Created by 马拉古 on 2018/5/28.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#ifndef Define_h
#define Define_h
#import "YYModel.h"
#import "imSDK/imSDK.h"
#import <IMMessageExt/IMMessageExt.h>

#define EVENT_CONNECTION @"Connection"//连接状态
#define EVENT_MESSAGE @"Message" // 收到的消息
#define EVENT_MsgLocator @"MsgLocator" //消息回撤
#define EVENT_UploaderProgress @"UploaderProgress" //上传进度
#define EVENT_groupTips  @"groupTips" //群事件
//用户状态变更
static NSString * const forceOffline = @"forceOffline";//断线重连失败
static NSString * const reConnFailed = @"reConnFailed";//断线重连失败
static NSString * const userSigExpired = @"userSigExpired";//断线重连失败
typedef void(^requestSucceed)(NSString *code,id data);
typedef void(^requestFail)(NSString *code,NSString *err);
#endif /* Define_h */
