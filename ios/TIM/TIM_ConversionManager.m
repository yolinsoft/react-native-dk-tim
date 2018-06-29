//
//  TIM_ConversionManager.m
//  TIM
//
//  Created by 马拉古 on 2018/5/31.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM_ConversionManager.h"
#import "TIM_MsgHandler.h"
@implementation TIM_ConversionManager
+(NSArray *)_getALLConversionList{
   __block NSMutableArray *arr = [NSMutableArray array];
    NSArray *conversions = [[TIMManager sharedInstance]getConversationList];
    __weak typeof(self)weakself = self;
    [conversions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TIMConversation *conversation = obj;
         NSMutableDictionary *dic = [weakself _getConversionInfoWithConversionId:[conversation getReceiver] conversionType:[conversation getType]];
        [arr addObject:dic];
        
    }];
    return  arr;
}

+(NSDictionary *)_getConversionInfoWithConversionId:(NSString *)conversionId conversionType:(TIMConversationType)conversionType{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    TIMConversation *conversion = [[TIMManager sharedInstance]getConversation:conversionType receiver:conversionId];
     int unread;
    
    if (conversion) {
        unread = conversion.getUnReadMessageNum;
        [dic setValue:[NSString stringWithFormat:@"%d",unread] forKey:@"unread"];
    }
    [dic setValue:conversionId forKey:@"conversionId"];
    [dic setValue:@(conversionType) forKey:@"conversationType"];
    return [dic mutableCopy];
}

+(int)getLocalConversion:(TIMConversation *)conversation  Message:(int)count last:(TIMMessage *)last success:(requestSucceed)succ fail:(requestFail)fail{
    int result = [conversation getLocalMessage:count last:last succ:^(NSArray * msgList) {
        
        __block  NSMutableArray *msgArr = [NSMutableArray array];
        
      
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [msgList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                TIMMessage * msg = obj;
                if ([msg isKindOfClass:[TIMMessage class]]) {
                    NSDictionary *msgDic = [TIM_MsgHandler createMessage:msg];
                    [msgArr addObject:msgDic];
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                succ(@(0).stringValue,[msgArr mutableCopy]);
            });
        });
        
    }fail:^(int code, NSString * err) {
        fail(@(code).stringValue,err);
    }];
    return result;
}

+(TIMConversation *)_getConversationByConversationType:(TIMConversationType)type conversationId:(NSString *)conversationId{
    return [[TIMManager sharedInstance]getConversation:type receiver:conversationId];
}

+(BOOL)deletConversationByConversationType:(TIMConversationType)type conversationId:(NSString *)conversationId isDeletMsg:(BOOL)isDeletMsg{
    if (isDeletMsg) {
        //删除会话的同时删除会话的所有消息
      return  [[TIMManager sharedInstance]deleteConversationAndMessages:type receiver:conversationId];
    } else {
      return  [[TIMManager sharedInstance]deleteConversation:type receiver:conversationId];
    }
    return NO;
}

+(NSArray *)getLastMsgs:(int)count conversion:(TIMConversation *)conversation{
   __block NSMutableArray *msgArr = [NSMutableArray array];
    NSArray *arr  = [conversation getLastMsgs:count];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TIMMessage *message = obj;
        NSDictionary *msgDic = [TIM_MsgHandler createMessage:message];
        [msgArr addObject:msgDic];
    }];
    return [msgArr mutableCopy];
}

+(int)sendOnlineMessage:(TIMMessage *)msg conversion:(TIMConversation *)conversation succ:(requestSucceed)succ fail:(requestFail)fail{
  return [conversation sendOnlineMessage:msg succ:^{
      succ(@"0",@"成功");
    } fail:^(int code, NSString *msg) {
        fail(@(code).stringValue,msg);
    }];
}

+(int)revokeMessage:(TIMMessage *)msg conversion:(TIMConversation *)conversation succ:(requestSucceed)succ fail:(requestFail)fail{
    return [conversation revokeMessage:msg succ:^{
        succ(@"0",@"成功");
    } fail:^(int code, NSString *msg) {
        fail(@(code).stringValue,msg);
    }];
}

@end
