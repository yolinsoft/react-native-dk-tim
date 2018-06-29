//
//  TIM.m
//  TIM
//
//  Created by 马拉古 on 2018/5/22.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM.h"
#import "TIM_EventListener.h"
#import "Define.h"
#import "TIM_MsgHandler.h"
#import "TIM_Push.h"
#import "TIM_ConversionManager.h"
#define EVENT_USERSTATUS @"UserStatus"
#define EVENT_REFRESH @"Refresh"
#define EVENT_NOTIFICATION @"Notification"

#define RecvMessageReceipts @"RecvMessageReceipts" //已读回执


#define SUBEVENT_CONN_SUCCESS @"success"
#define SUBEVENT_CONN_FAILED @"failed"
#define SUBEVENT_CONN_DISCONNECT @"disconnect"
#define SUBEVENT_CONN_CONNECTING @"connecting"

#define SUBEVENT_STATUS_FORCE_OFFLINE @"forceOffLine"
#define SUBEVENT_STATUS_RECONN_FAILED @"reconnFailed"
#define SUBEVENT_STATUS_SIG_EXPIRED @"sigExpired"

NSString *const kTIMReceiveNotification = @"TIM_RECEIVE_NOTIFICATION";

@interface TIM()
@property (nonatomic, strong) TIM_EventListener *eventListener;
@end

@implementation TIM

RCT_EXPORT_MODULE();

#pragma mark life cycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EVENT_CONNECTION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EVENT_MsgLocator object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EVENT_UploaderProgress object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:EVENT_groupTips object:nil];
}

-(instancetype)init{
    self = [super init];
    if (self) {
        [self initListeners];
        [self addNotifications];
    }
    return self;
}

//初始化监听
- (void)initListeners
{
    TIMManager *imManager = [TIMManager sharedInstance];
    [imManager addMessageListener:self];
//    [TIMManager sharedInstance] disableCrashReport];
    
}

-(void)addNotifications{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addConnListener:) name:EVENT_CONNECTION object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addMsgLocator:) name:EVENT_MsgLocator object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addMsgUploaderProgress:) name:EVENT_UploaderProgress object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(groupTips:) name:EVENT_groupTips object:nil];
}

#pragma TIMMessageListener
/**
 *  新消息回调通知
 *
 *  @param msgs 新消息列表，TIMMessage 类型数组RT
 */
- (void)onNewMessage:(NSArray*)msgs{
    NSMutableArray *messageList = [[NSMutableArray alloc] init];
    for (TIMMessage *message in msgs)
    {
        NSDictionary *msg = [TIM_MsgHandler createMessage:message];
        [messageList addObject: msg];

//        [self addMessageToConversation:[[message getConversation] getReceiver]
//                                 msgId:[msg objectForKey:@"msgId"]
//                               message:message];
    }
    [self sendEventWithName:EVENT_MESSAGE body:messageList];
}


//rn代码
- (NSArray<NSString *> *)supportedEvents
{
    return @[EVENT_MESSAGE,
             EVENT_CONNECTION,
             EVENT_USERSTATUS,
             EVENT_REFRESH,
             EVENT_NOTIFICATION,
             RecvMessageReceipts,
             EVENT_MsgLocator,
             EVENT_groupTips,
             EVENT_UploaderProgress];
}

#pragma Native method
- (TIMMessage*)createTIMMessage:(NSDictionary*)msg
{
    TIMMessage *message = [[TIMMessage alloc] init];
    TIMElem *elem = nil;

    TIMOfflinePushInfo *offlinePush = [[TIMOfflinePushInfo alloc] init];
    if ([msg objectForKey:@"offlinePush"])
    {
        NSDictionary *offlinePushObj = [msg objectForKey:@"offlinePush"];
        if ([offlinePushObj objectForKey:@"desc"])
        {
            offlinePush.desc = [offlinePushObj objectForKey:@"desc"];
        }

        if ([offlinePushObj objectForKey:@"ext"])
        {
            offlinePush.ext = [offlinePushObj objectForKey:@"ext"];
        }

        if ([offlinePushObj objectForKey:@"iosConfig"])
        {
            //ios 推送配置
            NSDictionary *iosDic = [offlinePushObj objectForKey:@"iosConfig"];
            TIMIOSOfflinePushConfig *iosConfig = [[TIMIOSOfflinePushConfig alloc]init];
            iosConfig.sound = iosDic[@"sound"];
            iosConfig.ignoreBadge = [iosDic[@"ignoreBadge"]boolValue];
            offlinePush.iosConfig = iosConfig;
        }
        if ([offlinePushObj objectForKey:@"androidConfig"]) {
             NSDictionary *dic = [offlinePushObj objectForKey:@"androidConfig"];
            TIMAndroidOfflinePushConfig *androidConfig = [[TIMAndroidOfflinePushConfig alloc]init];
            androidConfig.title = dic[@"title"];
            androidConfig.sound = dic[@"sound"];
            androidConfig.notifyMode = [dic[@"notifyMode"]integerValue];
            offlinePush.androidConfig = androidConfig;
        }
        //推送标标志
        offlinePush.pushFlag = [offlinePushObj[@"pushFlag"] integerValue];
        [message setOfflinePushInfo:offlinePush];
    }

    NSString *type = [msg objectForKey:@"type"];
    if ([type isEqualToString:@"text"])
    {
        TIMTextElem *textElem = [[TIMTextElem alloc] init];
        textElem.text = [msg objectForKey:@"data"];
        elem = textElem;
    }
    else if ([type isEqualToString:@"image"])
    {
        TIMImageElem *imageElem = [[TIMImageElem alloc] init];
        imageElem.path = [msg objectForKey:@"path"];
        imageElem.format = [[msg objectForKey:@"format"] intValue];
        elem = imageElem;
    }
    else if ([type isEqualToString:@"audio"])
    {
        TIMSoundElem *soundElem = [[TIMSoundElem alloc] init];
        soundElem.path = [msg objectForKey:@"path"];
        soundElem.second = [[msg objectForKey:@"duration"] intValue];
        elem = soundElem;
    }
    else if ([type isEqualToString:@"location"])
    {
        TIMLocationElem *locationElem = [[TIMLocationElem alloc] init];
        locationElem.desc = [msg objectForKey:@"desc"];
        locationElem.latitude = [[msg objectForKey:@"lat"] doubleValue];
        locationElem.longitude = [[msg objectForKey:@"lon"] doubleValue];
        elem = locationElem;
    }
    else if ([type isEqualToString:@"file"])
    {
        TIMFileElem *fileElem = [[TIMFileElem alloc] init];
        fileElem.path = [msg objectForKey:@"path"];
        fileElem.filename = [msg objectForKey:@"filename"];
        elem = fileElem;
    }
    else if ([type isEqualToString:@"custom"])
    {
        TIMCustomElem *customElem = [[TIMCustomElem alloc] init];
        customElem.data = [NSJSONSerialization dataWithJSONObject:[msg objectForKey:@"data"]
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        elem = customElem;
    }
    else
    {
        return nil;
    }

    [message addElem:elem];
    return message;
}
//- (NSArray*)createGroupChangeList:(NSArray*)groupChanges
//{
//    NSMutableArray *groupChangeList = [[NSMutableArray alloc] init];
//
//    for (TIMGroupTipsElemGroupInfo *group in groupChanges)
//    {
//        [groupChangeList addObject:[self createGroupChangeInfo:group]];
//    }
//
//    return groupChangeList;
//}
//- (NSDictionary*)createGroupChangeInfo:(TIMGroupTipsElemGroupInfo*)group
//{
//    NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
//
//    [groupInfo setValue:[NSNumber numberWithInteger:group.type] forKey:@"type"];
//    [groupInfo setValue:group.value forKey:@"value"];
//
//    return groupInfo;
//}
//
//- (NSDictionary*)createMemberChangeInfo:(TIMGroupTipsElemMemberInfo*)member
//{
//    NSMutableDictionary *memberInfo = [[NSMutableDictionary alloc] init];
//
//    [memberInfo setValue:member.identifier forKey:@"identifier"];
//    [memberInfo setValue:[NSNumber numberWithUnsignedInt:member.shutupTime] forKey:@"shutupTime"];
//
//    return memberInfo;
//}
//- (NSArray*)createMemberChangeList:(NSArray*)memberChanges
//{
//    NSMutableArray *memberChangeList = [[NSMutableArray alloc] init];
//
//    for (TIMGroupTipsElemMemberInfo *member in memberChanges)
//    {
//        [memberChangeList addObject:[self createMemberChangeInfo:member]];
//    }
//
//    return memberChangeList;
//}
//
//- (NSDictionary*)createUserInfo:(TIMUserProfile*)profile
//{
//    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
//
//    [userInfo setValue:profile.identifier forKey:@"identifier"];
//    [userInfo setValue:profile.nickname forKey:@"nickname"];
//    [userInfo setValue:profile.remark forKey:@"remark"];
//    [userInfo setValue:[NSNumber numberWithInteger:profile.allowType] forKey:@"allowType"];
//    [userInfo setValue:profile.faceURL forKey:@"faceURL"];
//    [userInfo setValue:[[NSString alloc] initWithData:profile.selfSignature
//                                             encoding:NSUTF8StringEncoding] forKey:@"selfSignature"];
//    [userInfo setValue:[NSNumber numberWithInteger:profile.gender] forKey:@"gender"];
//    [userInfo setValue:[NSNumber numberWithUnsignedInt:profile.birthday] forKey:@"birthday"];
//    [userInfo setValue:[[NSString alloc] initWithData:profile.location
//                                             encoding:NSUTF8StringEncoding] forKey:@"location"];
//    [userInfo setValue:[NSNumber numberWithUnsignedInt:profile.language] forKey:@"language"];
//    [userInfo setValue:profile.friendGroups forKey:@"friendGroups"];
//    [userInfo setValue:profile.customInfo forKey:@"customInfo"];
//
//    return userInfo;
//}
//
//- (NSDictionary*)createGroupMemberInfo:(TIMGroupMemberInfo*)memberInfo
//{
//    NSMutableDictionary *member = [[NSMutableDictionary alloc] init];
//
//    [member setValue:memberInfo.member forKey:@"member"];
//    [member setValue:memberInfo.nameCard forKey:@"nameCard"];
//    [member setValue:[NSNumber numberWithLong:memberInfo.joinTime] forKey:@"joinTime"];
//    [member setValue:[NSNumber numberWithInteger:memberInfo.role] forKey:@"role"];
//    [member setValue:[NSNumber numberWithUnsignedInt:memberInfo.silentUntil] forKey:@"silentUntil"];
//    [member setValue:memberInfo.customInfo forKey:@"customInfo"];
//    return member;
//}
//
//- (NSDictionary*)createChangedUserInfo:(NSDictionary*)changedUserInfo
//{
//    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
//
//    for (NSString *key in changedUserInfo)
//    {
//        [infoList setValue:[self createUserInfo:[changedUserInfo objectForKey:key]] forKey:key];
//    }
//
//    return infoList;
//}
//
//- (NSDictionary*)createChangedGroupMemberInfo:(NSDictionary*)changedGroupMemberInfo
//{
//    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
//
//    for (NSString *key in changedGroupMemberInfo)
//    {
//        [infoList setValue:[self createGroupMemberInfo:[changedGroupMemberInfo objectForKey:key]] forKey:key];
//    }
//
//    return infoList;
//}


#pragma mark  TIMUserStatusListener delegate
/**
 *  踢下线通知
 */
- (void)onForceOffline{
    
}

/**
 *  断线重连失败
 */
- (void)onReConnFailed:(int)code err:(NSString*)err{
    
}


#pragma mark  TIMRefreshListener delegate

/**
 *  刷新会话
 */
- (void)onRefresh{
    [self sendEventWithName:EVENT_REFRESH
                       body:nil];
}

/**
 *  刷新部分会话（包括多终端已读上报同步）
 *
 *  @param conversations 会话（TIMConversation*）列表
 */
- (void)onRefreshConversations:(NSArray*)conversations{
    
}


/**
 *  收到了已读回执
 *
 *  @param receipts 已读回执（TIMMessageReceipt*）列表
 */
- (void)onRecvMessageReceipts:(NSArray*)receipts{
//
    __block NSMutableArray *arr = [NSMutableArray array];
   
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [receipts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            TIMMessageReceipt *msgRpt = obj;
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setValue:[NSString stringWithFormat:@"%ld",msgRpt.timestamp] forKey:@"timestamp"];
            NSString *conversationId = [msgRpt.conversation getReceiver];
            NSString *selfIdentifier   = [msgRpt.conversation getSelfIdentifier];
            NSString *conversationType = [NSString stringWithFormat:@"%ld",(long)[msgRpt.conversation getType]];
            [dic setValue:conversationId forKey:@"conversationId"];
            [dic setValue:selfIdentifier forKey:@"selfIdentifier"];
            [dic setValue:conversationType forKey:@"conversationType"];
            [arr addObject:dic];
        }];
        [self sendEventWithName:RecvMessageReceipts body:[arr mutableCopy]];
    });
}


#pragma mark - export method
//初始化SDK
RCT_EXPORT_METHOD(initSdk:(NSDictionary*)sdkConfig resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    TIMManager *imManager = [TIMManager sharedInstance];
    TIMSdkConfig *config = [[TIMSdkConfig alloc] init];
    config.sdkAppId =  [sdkConfig[@"sdkAppId"] intValue];
    config.accountType = sdkConfig[@"accountType"];
//    config.sdkAppId =  [@"1400062998" intValue];
//    config.accountType = @"27442";
    config.disableCrashReport = YES;
    
    if (sdkConfig[@"dbPath"]) {
        config.dbPath = sdkConfig[@"dbPath"];
    }
    config.connListener = self.eventListener;
    if ([imManager initSdk:config] == 0) {
        //succ
        resolve([NSNumber numberWithInteger:0]);
    } else {
        reject(@"1",@"未知",nil);
    }
}

//设置用户配置
RCT_EXPORT_METHOD(setUserConfig:(NSDictionary*)config resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    TIMManager *imManager = [TIMManager sharedInstance];
    TIMUserConfig *userConfig = [[TIMUserConfig alloc] init];
    userConfig.userStatusListener = self;
    userConfig.refreshListener = self;
    userConfig.receiptListener = self;
    userConfig.messgeRevokeListener = self.eventListener;
    userConfig.uploadProgressListener = self.eventListener;
    userConfig.groupEventListener = self.eventListener;
    //    userConfig.disableStorage = YES;//禁用本地存储（加载消息扩展包有效）
    //    userConfig.disableAutoReport = YES;//禁止自动上报（加载消息扩展包有效）
    userConfig.enableReadReceipt = YES;//开启C2C已读回执（加载消息扩展包有效）
    userConfig.disableRecnetContact = YES;//不开启最近联系人（加载消息扩展包有效）
    userConfig.disableRecentContactNotify = NO;//不通过onNewMessage:抛出最新联系人的最后一条消息（加载消息扩展包有效）
    userConfig.enableFriendshipProxy = YES;//开启关系链数据本地缓存功能（加载好友扩展包有效）
    userConfig.enableGroupAssistant = YES;//开启群组数据本地缓存功能（加载群组扩展包有效）
    /*
    TIMGroupInfoOption *giOption = [[TIMGroupInfoOption alloc] init];
    giOption.groupFlags = 0xffffff;//需要获取的群组信息标志（TIMGetGroupBaseInfoFlag）,默认为0xffffff
    giOption.groupCustom = nil;//需要获取群组资料的自定义信息（NSString*）列表
    userConfig.groupInfoOpt = giOption;//设置默认拉取的群组资料
    TIMGroupMemberInfoOption *gmiOption = [[TIMGroupMemberInfoOption alloc] init];
    gmiOption.memberFlags = 0xffffff;//需要获取的群成员标志（TIMGetGroupMemInfoFlag）,默认为0xffffff
    gmiOption.memberCustom = nil;//需要获取群成员资料的自定义信息（NSString*）列表
    userConfig.groupMemberInfoOpt = gmiOption;//设置默认拉取的群成员资料
    
    TIMFriendProfileOption *fpOption = [[TIMFriendProfileOption alloc] init];
    fpOption.friendFlags = 0xffffff;//需要获取的好友信息标志（TIMProfileFlag）,默认为0xffffff
    fpOption.friendCustom = nil;//需要获取的好友自定义信息（NSString*）列表
    fpOption.userCustom = nil;//需要获取的用户自定义信息（NSString*）列表
    userConfig.friendProfileOpt = fpOption;//设置默认拉取的好友资料
    userConfig.userStatusListener = self;//用户登录状态监听器
    userConfig.refreshListener = self;//会话刷新监听器（未读计数、已读同步）（加载消息扩展包有效）
    //    userConfig.receiptListener = self;//消息已读回执监听器（加载消息扩展包有效）
    //    userConfig.messageUpdateListener = self;//消息svr重写监听器（加载消息扩展包有效）
    //    userConfig.uploadProgressListener = self;//文件上传进度监听器
    //    userConfig.groupEventListener todo
//    userConfig.messgeRevokeListener = self.conversationMgr;
//    userConfig.friendshipListener = self;//关系链数据本地缓存监听器（加载好友扩展包、enableFriendshipProxy有效）
//    userConfig.groupListener = self;//群组据本地缓存监听器（加载群组扩展包、enableGroupAssistant有效）
*/
    
    if ([imManager setUserConfig:userConfig] == 0) {
        resolve([NSNumber numberWithInteger:0]);
    } else {
        reject(@"1",@"未知",nil);
    }
}

//登录
RCT_EXPORT_METHOD(login:(NSDictionary*)params resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    TIMLoginParam *loginParm = [[TIMLoginParam alloc] init];
    loginParm.userSig = [params objectForKey:@"userSig"];
    loginParm.appidAt3rd = [params objectForKey:@"appidAt3rd"];
    loginParm.identifier = [params objectForKey:@"identifier"];
   
    [[TIMManager sharedInstance]login:loginParm succ:^{
       resolve([NSNumber numberWithInteger:0]);
    } fail:^(int code, NSString *msg) {
        
         reject([NSString stringWithFormat:@"%d",code],msg,nil);
    }];
}

/**
 发送消息
 @param NSDictionary 消息内容
 @param type 1 单聊 、2群聊  3系统消息
 @param receiver 接收者
 */
RCT_EXPORT_METHOD(sendMsg:(NSDictionary *)msg conversationType:(NSInteger)type receiver:(NSString*)receiver resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){

    TIMConversation *conversation = [[TIMManager sharedInstance] getConversation:type receiver:receiver];

    TIMMessage *TIMMsg = [self createTIMMessage:msg];

    [conversation sendMessage:TIMMsg succ:^{
        
       resolve([NSNumber numberWithInteger:0]);
    } fail:^(int code, NSString *msg) {
        
        reject([NSString stringWithFormat:@"%d",code],msg,nil);
    }];
}

/**
 发送在线消息

 @param NSDictionary 对象
 @return
 */
RCT_EXPORT_METHOD(sendOlineMsg:(NSDictionary*)msg conversationType:(NSInteger)type receiver:(NSString*)receiver resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    
    TIMConversation *conversation = [[TIMManager sharedInstance] getConversation:type receiver:receiver];
    TIMMessage *TIMMsg = [self createTIMMessage:msg];
    [TIM_ConversionManager sendOnlineMessage:TIMMsg conversion:conversation succ:^(NSString *code, id data) {
        resolve(@(0));
    } fail:^(NSString *code, NSString *err) {
        reject(@"1",@"发送失败",nil);
    }];
}

/**
 保存草稿
 @param NSString
 @return
 */
RCT_EXPORT_METHOD(setDraft:(NSString*)draft conversationType:(NSInteger)type receiver:(NSString*)receiver resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    TIMMessageDraft *darftMsg = [[TIMMessageDraft alloc]init];
    [darftMsg setUserData:[draft dataUsingEncoding:NSUTF8StringEncoding]];
    TIMConversation *conversation = [[TIMManager sharedInstance] getConversation:type receiver:receiver];
   
    if ( [conversation setDraft:darftMsg] == 0) {
        resolve(@(0));
    } else {
        reject(@"1",@"保存草稿失败",nil);
    }
}

/**
 获取草稿

 @param NSInteger <#NSInteger description#>
 @return <#return value description#>
 */
RCT_EXPORT_METHOD(getDraftConversationType:(NSInteger)type receiver:(NSString*)receiver resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
//    TIMMessageDraft *darftMsg = [[TIMMessageDraft alloc]init];
//    [darftMsg setUserData:[draft dataUsingEncoding:NSUTF8StringEncoding]];
    TIMConversation *conversation = [[TIMManager sharedInstance] getConversation:type receiver:receiver];
   TIMMessageDraft *darf = [conversation getDraft];
    NSData *darfData = [darf getUserData];
    NSString *darfText = [[NSString alloc]initWithData:darfData encoding:NSUTF8StringEncoding];
    if (darfText.length > 0) {
        resolve(darfText);
    }else{
        reject(@"1",@"没有草稿",nil);
    }
}


/**
 *  撤回消息（仅 C2C 和 GROUP 会话有效、onlineMessage 无效、AVChatRoom 和 BChatRoom 无效）
 *
 *  @param msg   被撤回的消息
 *
 */
RCT_EXPORT_METHOD(revokeMsg:(NSDictionary*)msg conversationType:(NSInteger)type receiver:(NSString*)receiver resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    
    TIMConversation *conversation = [[TIMManager sharedInstance] getConversation:type receiver:receiver];
    TIMMessage *TIMMsg = [self createTIMMessage:msg];
    [TIM_ConversionManager revokeMessage:TIMMsg conversion:conversation succ:^(NSString *code, id data) {
        resolve(@(0));
    } fail:^(NSString *code, NSString *err) {
        reject(code,err,nil);
    }];
}

/**
 注册token

 @param NSString token
 @return busiId 业务ID
 */
RCT_EXPORT_METHOD(registerDeviceToken:(NSString *)token withBusiId:(NSString *)busiId resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
//    NSObject
    NSData *data = [RCTConvert NSData:token];
    [TIM_Push registerDeviceToken:data withBusiId:[busiId intValue] succ:^(BOOL result) {
        resolve([NSNumber numberWithInt:0]);
    } fail:^(int code, NSString *err) {
        reject([NSString stringWithFormat:@"%d",code],err,nil);
    }];
}

/**
 应用程序即将进入前台

 @param RCTPromiseResolveBlock
 @return
 */
RCT_EXPORT_METHOD(appEnterForeground:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    [TIM_Push doEnterForegroundSucc:^(BOOL result) {
         resolve([NSNumber numberWithInteger:0]);
    } fail:^(int code, NSString *err) {
          reject([NSString stringWithFormat:@"%d",code],err,nil);
    }];
}

/**
 应用程序即将进入后台

 @param RCTPromiseResolveBlock
 @return
 */
RCT_EXPORT_METHOD(appEnterBackground:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    [TIM_Push doEnterBackgroundSucc:^(BOOL result) {
        
         resolve([NSNumber numberWithInteger:0]);
    } fail:^(int code, NSString *err) {
        
         reject([NSString stringWithFormat:@"%d",code],err,nil);
    }];
}


/**
 //获取所有会话
 @param RCTPromiseResolveBlock
 @return
 */
RCT_EXPORT_METHOD(getConversaionList:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    
    NSArray *conversions = [TIM_ConversionManager _getALLConversionList];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObject:conversions forKey:@"Data"];
    [dic setValue:@(0) forKey:@"code"];
    if (dic) {
        resolve(dic);
    } else {
        reject(@"1",@"无会话",nil);
    }
}



/**
 获取会话的本地消息

 @param NSString <#NSString description#>
 @return <#return value description#>
 */
RCT_EXPORT_METHOD(getMsgByConversationType:(NSString *)type conversationId:(NSString*)conversationId msgCount:(NSString*)msgCount lastMsg:(NSDictionary *)msg  resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    
    TIMConversation *conversation = [TIM_ConversionManager _getConversationByConversationType:type.integerValue conversationId:conversationId];
    TIMMessage *timMsg = [self createTIMMessage:msg];
    [TIM_ConversionManager getLocalConversion:conversation Message:msgCount.intValue last:timMsg success:^(NSString *code, id data) {
        NSArray *arr = data;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObject:arr forKey:@"Data"];
        [dic setValue:@(0) forKey:@"code"];
        resolve(dic);
    } fail:^(NSString *code, NSString *err) {
        reject(code,err,nil);
    }];
}


/**
 删除会话

 @param isDeletMsg 删除会话的同时是否删除会话的消息
 @return
 */
RCT_EXPORT_METHOD(deletConversationType:(NSString *)type conversationId:(NSString*)conversationId isDeletMsg:(NSNumber *)isDeletMsg resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    if ( [TIM_ConversionManager deletConversationByConversationType:[type integerValue] conversationId:conversationId isDeletMsg:isDeletMsg.boolValue]) {
        resolve(@(0));
    } else {
        reject(@"1",@"删除失败",nil);
    }
}


/**
 获取会话的最后一条消息

 @param NSString <#NSString description#>
 @return <#return value description#>
 */
RCT_EXPORT_METHOD(getConversationLastMsgType:(NSString *)type conversationId:(NSString*)conversationId MsgCount:(NSString*)MsgCount resolve:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
     TIMConversation *conversation = [TIM_ConversionManager _getConversationByConversationType:type.integerValue conversationId:conversationId];
     NSArray *msgArr =  [TIM_ConversionManager getLastMsgs:MsgCount.intValue conversion:conversation];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObject:msgArr forKey:@"Data"];
    [dic setValue:@(0) forKey:@"code"];
    if (dic) {
        resolve(dic);
    } else {
        reject(@"1",@"没有消息",nil);
    }
}

#pragma mark notification event
-(void)addConnListener:(NSNotification *)notivicaiton{
    NSDictionary *dic = notivicaiton.userInfo;
    [self sendEventWithName:EVENT_CONNECTION body:[dic mutableCopy]];
}

-(void)addMsgLocator:(NSNotification *)notivicaiton{
    NSDictionary *dic = notivicaiton.userInfo;
    [self sendEventWithName:EVENT_MsgLocator body:[dic mutableCopy]];
}

//文件上传
-(void)addMsgUploaderProgress:(NSNotification *)notivicaiton{
    NSDictionary *dic = notivicaiton.userInfo;
    [self sendEventWithName:EVENT_UploaderProgress body:[dic mutableCopy]];
}
//群事件
-(void)groupTips:(NSNotification *)notivicaition{
    NSDictionary *dic = notivicaition.userInfo;
    [self sendEventWithName:EVENT_groupTips body:[dic copy]];
}

#pragma mark get or set
-(TIM_EventListener *)eventListener{
    if (_eventListener == nil) {
        _eventListener = [[TIM_EventListener alloc]init];
    }
    return _eventListener;
}

@end
