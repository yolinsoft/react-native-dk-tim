//
//  TIM.h
//  TIM
//
//  Created by 马拉古 on 2018/5/22.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTConvert.h>
#import "Define.h"
#import "TLSSDK/TLSRefreshTicketListener.h"
#import "TLSSDK/TLSOpenLoginListener.h"
#import "TLSSDK/TLSHelper.h"
@interface TIM : RCTEventEmitter<TIMMessageListener,TIMUserStatusListener,TLSRefreshTicketListener,TIMRefreshListener,TIMMessageReceiptListener,RCTBridgeModule>

@end
