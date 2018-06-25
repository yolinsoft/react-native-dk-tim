//
//  TIM.m
//  TIM
//
//  Created by 马拉古 on 2018/5/22.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM.h"
#import "TIM_ConnListener.h"
#import "Define.h"
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
@property (nonatomic, strong) TIM_ConnListener *connectListener;
@end

@implementation TIM

RCT_EXPORT_MODULE();

#pragma mark life cycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EVENT_CONNECTION object:nil];
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
}

#pragma TIMMessageListener
/**
 *  新消息回调通知
 *
 *  @param msgs 新消息列表，TIMMessage 类型数组
 */
- (void)onNewMessage:(NSArray*)msgs{
    NSMutableArray *messageList = [[NSMutableArray alloc] init];
    for (TIMMessage *message in msgs)
    {
        NSDictionary *msg = [self createMessage:message];
        [messageList addObject: msg];

//        [self addMessageToConversation:[[message getConversation] getReceiver]
//                                 msgId:[msg objectForKey:@"msgId"]
//                               message:message];
    }
    [self sendEventWithName:EVENT_MESSAGE body:messageList];
}

- (NSDictionary*)createMessage:(TIMMessage*)msg
{
    if (!msg)
    {
        return nil;
    }
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    NSMutableArray *elems = [[NSMutableArray alloc] init];
    
    [message setValue:[[NSUUID UUID] UUIDString] forKey:@"msgId"];
    [message setValue:[NSNumber numberWithBool:msg.isSelf] forKey:@"isSelf"];
    
    [message setValue:[NSNumber numberWithInt:msg.elemCount] forKey:@"elemCount"];
    [message setValue:msg.sender forKey:@"sender"];
    
    [message setValue:[NSString stringWithFormat:@"%ld",(long)msg.status] forKey:@"status"];
    [message setValue:msg.msgId forKey:@"tMsgId"];
    [message setValue:[NSNumber numberWithUnsignedLongLong:msg.uniqueId] forKey:@"tUniqueId"];
    
    if (msg.timestamp)
    {
        NSTimeInterval interval = [msg.timestamp timeIntervalSince1970];
        
        [message setValue:[NSNumber numberWithDouble:interval * 1000] forKey:@"timestamp"];
    }
    
    if ([[msg getConversation] getType] == TIM_GROUP)
    {
        [message setValue:[[msg getConversation] getReceiver] forKey:@"groupId"];
    }
    
    [message setValue:elems forKey:@"elems"];
    
    for (int i = 0; i < [msg elemCount]; i++)
    {
        TIMElem *elem = [msg getElem:i];
        NSMutableDictionary *elemDic = nil;
        
        if ([elem isKindOfClass:[TIMTextElem class]])
        {
            TIMTextElem *textElem = (TIMTextElem*)elem;
            
            elemDic = @{@"data": textElem.text,@"type": @"text"};
        }
        else if([elem isKindOfClass:[TIMImageElem class]])
        {
            TIMImageElem *imageElem = (TIMImageElem*)elem;
            elemDic = [[NSMutableDictionary alloc] init];
            [elemDic setValue:@"image" forKey:@"type"];
            [elemDic setValue:[NSNumber numberWithInt:imageElem.format] forKey:@"format"];
            
            for (TIMImage *image in imageElem.imageList)
            {
                NSDictionary *imageDic = @{@"size": [NSNumber numberWithInt:image.size],
                                           @"width": [NSNumber numberWithInt:image.width],
                                           @"height": [NSNumber numberWithInt:image.height],
                                           @"uuid": image.uuid};
                if (image.type == TIM_IMAGE_TYPE_ORIGIN)
                {
                    [elemDic setValue:imageDic forKey:@"origin"];
                }
                else if (image.type == TIM_IMAGE_TYPE_THUMB)
                {
                    [elemDic setValue:imageDic forKey:@"thumb"];
                }
                else if (image.type == TIM_IMAGE_TYPE_LARGE)
                {
                    [elemDic setValue:imageDic forKey:@"large"];
                }
            }
        }
        else if([elem isKindOfClass:[TIMSoundElem class]])
        {
            TIMSoundElem *soundElem = (TIMSoundElem*)elem;
            elemDic = @{@"type": @"audio",
                        @"uuid": soundElem.uuid,
                        @"duration": [NSNumber numberWithInt:soundElem.second]
                        };
        }
        else if([elem isKindOfClass:[TIMLocationElem class]])
        {
            TIMLocationElem *locationElem = (TIMLocationElem*)elem;
            elemDic = @{@"type": @"location",
                        @"lat": [NSNumber numberWithDouble:locationElem.latitude],
                        @"lon": [NSNumber numberWithDouble:locationElem.longitude],
                        @"desc": locationElem.desc
                        };
        }
        else if([elem isKindOfClass:[TIMFileElem class]])
        {
            TIMFileElem *fileElem = (TIMFileElem*)elem;
            elemDic = @{@"type": @"file",
                        @"uuid": fileElem.uuid,
                        @"size": [NSNumber numberWithInt: fileElem.fileSize],
                        @"filename": fileElem.filename
                        };
        }
        else if([elem isKindOfClass:[TIMCustomElem class]])
        {
            TIMCustomElem *customElem = (TIMCustomElem*)elem;
            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:customElem.data
                                                                 options:NSJSONReadingMutableLeaves
                                                                   error:nil];
            
            elemDic = @{@"data": data,@"type": @"custom"};
        }
        else if([elem isKindOfClass:[TIMGroupSystemElem class]])
        {
            TIMGroupSystemElem *groupSystemElem = (TIMGroupSystemElem*)elem;
            NSString *userData = nil;
            if (groupSystemElem.userData)
            {
                userData = [[NSString alloc] initWithData:groupSystemElem.userData encoding:NSUTF8StringEncoding];
            }
            elemDic = @{@"type":@"groupSystem",
                        @"subType":[NSNumber numberWithInteger:groupSystemElem.type],
                        @"groupId":groupSystemElem.group,
                        @"user": groupSystemElem.user,
                        @"msg": groupSystemElem.msg,
                        @"content": userData ? userData : [NSNull null]
                        };
        }
        else if([elem isKindOfClass:[TIMGroupTipsElem class]])
        {
            TIMGroupTipsElem *groupTips = (TIMGroupTipsElem*)elem;
            elemDic = @{@"type":@"groupTips",
                        @"subType":[NSNumber numberWithInteger:groupTips.type],
                        @"groupId": groupTips.group,
                        @"user": groupTips.opUser,
                        @"userList": groupTips.userList ? groupTips.userList : [NSNull null],
                        @"groupName": groupTips.groupName,
                        @"groupChangeList": groupTips.groupChangeList ? [self createGroupChangeList:groupTips.groupChangeList]:[NSNull null],
                        @"memberChangeList": groupTips.memberChangeList ? [self createMemberChangeList:groupTips.memberChangeList]:[NSNull null],
                        @"userInfo": [self createUserInfo:groupTips.opUserInfo],
                        @"groupMemberInfo": [self createGroupMemberInfo:groupTips.opGroupMemberInfo],
                        @"changedUserInfo": [self createChangedUserInfo:groupTips.changedUserInfo],
                        @"changedGroupMemberInfo":[self createChangedGroupMemberInfo:groupTips.changedGroupMemberInfo],
                        @"memberNum": [NSNumber numberWithUnsignedInt:groupTips.memberNum]
                        };
        }
        else
        {
            elemDic = @{@"data":@"unknown message type.",@"type":@"unknown"};
        }
        
        [elems addObject:elemDic];
    }
    
    return message;
}

//rn代码
- (NSArray<NSString *> *)supportedEvents
{
    return @[EVENT_MESSAGE,
             EVENT_CONNECTION,
             EVENT_USERSTATUS,
             EVENT_REFRESH,
             EVENT_NOTIFICATION,RecvMessageReceipts];
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
- (NSArray*)createGroupChangeList:(NSArray*)groupChanges
{
    NSMutableArray *groupChangeList = [[NSMutableArray alloc] init];
    
    for (TIMGroupTipsElemGroupInfo *group in groupChanges)
    {
        [groupChangeList addObject:[self createGroupChangeInfo:group]];
    }
    
    return groupChangeList;
}
- (NSDictionary*)createGroupChangeInfo:(TIMGroupTipsElemGroupInfo*)group
{
    NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
    
    [groupInfo setValue:[NSNumber numberWithInteger:group.type] forKey:@"type"];
    [groupInfo setValue:group.value forKey:@"value"];
    
    return groupInfo;
}

- (NSDictionary*)createMemberChangeInfo:(TIMGroupTipsElemMemberInfo*)member
{
    NSMutableDictionary *memberInfo = [[NSMutableDictionary alloc] init];
    
    [memberInfo setValue:member.identifier forKey:@"identifier"];
    [memberInfo setValue:[NSNumber numberWithUnsignedInt:member.shutupTime] forKey:@"shutupTime"];
    
    return memberInfo;
}
- (NSArray*)createMemberChangeList:(NSArray*)memberChanges
{
    NSMutableArray *memberChangeList = [[NSMutableArray alloc] init];
    
    for (TIMGroupTipsElemMemberInfo *member in memberChanges)
    {
        [memberChangeList addObject:[self createMemberChangeInfo:member]];
    }
    
    return memberChangeList;
}

- (NSDictionary*)createUserInfo:(TIMUserProfile*)profile
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    
    [userInfo setValue:profile.identifier forKey:@"identifier"];
    [userInfo setValue:profile.nickname forKey:@"nickname"];
    [userInfo setValue:profile.remark forKey:@"remark"];
    [userInfo setValue:[NSNumber numberWithInteger:profile.allowType] forKey:@"allowType"];
    [userInfo setValue:profile.faceURL forKey:@"faceURL"];
    [userInfo setValue:[[NSString alloc] initWithData:profile.selfSignature
                                             encoding:NSUTF8StringEncoding] forKey:@"selfSignature"];
    [userInfo setValue:[NSNumber numberWithInteger:profile.gender] forKey:@"gender"];
    [userInfo setValue:[NSNumber numberWithUnsignedInt:profile.birthday] forKey:@"birthday"];
    [userInfo setValue:[[NSString alloc] initWithData:profile.location
                                             encoding:NSUTF8StringEncoding] forKey:@"location"];
    [userInfo setValue:[NSNumber numberWithUnsignedInt:profile.language] forKey:@"language"];
    [userInfo setValue:profile.friendGroups forKey:@"friendGroups"];
    [userInfo setValue:profile.customInfo forKey:@"customInfo"];
    
    return userInfo;
}

- (NSDictionary*)createGroupMemberInfo:(TIMGroupMemberInfo*)memberInfo
{
    NSMutableDictionary *member = [[NSMutableDictionary alloc] init];
    
    [member setValue:memberInfo.member forKey:@"member"];
    [member setValue:memberInfo.nameCard forKey:@"nameCard"];
    [member setValue:[NSNumber numberWithLong:memberInfo.joinTime] forKey:@"joinTime"];
    [member setValue:[NSNumber numberWithInteger:memberInfo.role] forKey:@"role"];
    [member setValue:[NSNumber numberWithUnsignedInt:memberInfo.silentUntil] forKey:@"silentUntil"];
    [member setValue:memberInfo.customInfo forKey:@"customInfo"];
    return member;
}

- (NSDictionary*)createChangedUserInfo:(NSDictionary*)changedUserInfo
{
    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in changedUserInfo)
    {
        [infoList setValue:[self createUserInfo:[changedUserInfo objectForKey:key]] forKey:key];
    }
    
    return infoList;
}

- (NSDictionary*)createChangedGroupMemberInfo:(NSDictionary*)changedGroupMemberInfo
{
    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in changedGroupMemberInfo)
    {
        [infoList setValue:[self createGroupMemberInfo:[changedGroupMemberInfo objectForKey:key]] forKey:key];
    }
    
    return infoList;
}


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
            NSString *conversationType = [NSString stringWithFormat:@"%ld",[msgRpt.conversation getType]];
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
//    config.disableCrashReport = YES;
    config.connListener = self.connectListener;
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
    
    //    userConfig.disableStorage = YES;//禁用本地存储（加载消息扩展包有效）
    //    userConfig.disableAutoReport = YES;//禁止自动上报（加载消息扩展包有效）
    userConfig.enableReadReceipt = YES;//开启C2C已读回执（加载消息扩展包有效）
    userConfig.disableRecnetContact = YES;//不开启最近联系人（加载消息扩展包有效）
    userConfig.disableRecentContactNotify = NO;//不通过onNewMessage:抛出最新联系人的最后一条消息（加载消息扩展包有效）
    userConfig.enableFriendshipProxy = NO;//开启关系链数据本地缓存功能（加载好友扩展包有效）
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

#pragma mark notification event
-(void)addConnListener:(NSNotification *)notivicaiton{
    NSDictionary *dic = notivicaiton.userInfo;
    [self sendEventWithName:EVENT_CONNECTION body:[dic mutableCopy]];
}


#pragma mark get or set
-(TIM_ConnListener *)connectListener{
    if (_connectListener == nil) {
        _connectListener = [[TIM_ConnListener alloc]init];
    }
    return _connectListener;
}

@end
