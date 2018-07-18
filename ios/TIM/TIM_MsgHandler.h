//
//  TIM_MsgHandler.h
//  TIM
//
//  Created by 马拉古 on 2018/5/29.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Define.h"
//#import "TLSSDK/TLSRefreshTicketListener.h"
//#import "TLSSDK/TLSOpenLoginListener.h"
//#import "TLSSDK/TLSHelper.h"
@interface TIM_MsgHandler : NSObject

/**
 模型装json

 @param msg 消息模型
 @return 字典
 */
+(NSDictionary*)createMessage:(TIMMessage*)msg;

- (TIMMessageLocator*)locator;
@end
