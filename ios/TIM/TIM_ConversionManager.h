//
//  TIM_ConversionManager.h
//  TIM
//
//  Created by 马拉古 on 2018/5/31.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Define.h"
@interface TIM_ConversionManager : NSObject
+(NSArray *)_getALLConversionList;

/**
 根据会话id获取会话相关信息

 @param conversionId 会话id
 @return 会话相关信息 暂时只有未读数
 */
+(NSMutableDictionary *)_getConversionInfoWithConversionId:(NSString *)conversionId conversionType:(TIMConversationType)conversionType;

/**
 *  获取本地会话消息
 *
 *  @param count 获取数量
 *  @param last  上次最后一条消息
 *  @param succ  成功时回调
 *  @param fail  失败时回调
 *
 *  @return 0 本次操作成功
 */
+(int)getLocalConversion:(TIMConversation *)conversation  Message:(int)count last:(TIMMessage *)last success:(requestSucceed)succ fail:(requestFail)fail;


/**
 获取某个会话

 @param type 会话类型
 @param conversationId 会话id
 @return 具体的会话
 */
+(TIMConversation *)_getConversationByConversationType:(TIMConversationType)type conversationId:(NSString *)conversationId;


/**
 删除某个会话

 @param type 会话类型
 @param conversationId
 @param isDeletMsg 是否在删除会话的同时删除类型
 @return yes or no 操作是否成功
 */
+(BOOL)deletConversationByConversationType:(TIMConversationType)type conversationId:(NSString *)conversationId isDeletMsg:(BOOL)isDeletMsg;

/**
 *  从 Cache 中获取最后几条消息
 *
 *  @param count 需要获取的消息数，最多为 20
 *
 *  @return 消息（TIMMessage*）列表，第一条为最新消息
 */
+ (NSArray*)getLastMsgs:(int)count conversion:(TIMConversation *)conversation;



/**
 *  发送在线消息（服务器不保存消息）
 *
 *  @param msg  消息体
 *  @param succ 成功回调
 *  @param fail 失败回调
 *
 *  @return 0 成功
 */
+ (int)sendOnlineMessage:(TIMMessage*)msg conversion:(TIMConversation *)conversation succ:(requestSucceed)succ fail:(requestFail)fail;

/**
 *  撤回消息（仅 C2C 和 GROUP 会话有效、onlineMessage 无效、AVChatRoom 和 BChatRoom 无效）
 *
 *  @param msg   被撤回的消息
 *  @param succ  成功时回调
 *  @param fail  失败时回调
 *
 *  @return 0 本次操作成功
 */
+ (int)revokeMessage:(TIMMessage*)msg conversion:(TIMConversation *)conversation succ:(requestSucceed)succ fail:(requestFail)fail;

@end
