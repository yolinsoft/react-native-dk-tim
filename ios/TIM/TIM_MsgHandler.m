//
//  TIM_MsgHandler.m
//  TIM
//
//  Created by 马拉古 on 2018/5/29.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import "TIM_MsgHandler.h"

@implementation TIM_MsgHandler

+(NSDictionary*)createMessage:(TIMMessage*)msg
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
    
    [message setValue:elems forKey:@"msg"];
    
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
                                           @"uuid": image.uuid,
                                           @"url":image.url
                                           };
                
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
                        @"duration": [NSNumber numberWithInt:soundElem.second],
                        @"path":soundElem.path,
                        @"dataSize":[NSNumber numberWithInt:soundElem.dataSize],
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
                        @"filename": fileElem.filename,
                        @"filePath":fileElem.path
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

+(NSArray*)createGroupChangeList:(NSArray*)groupChanges
{
    NSMutableArray *groupChangeList = [[NSMutableArray alloc] init];
    
    for (TIMGroupTipsElemGroupInfo *group in groupChanges)
    {
        [groupChangeList addObject:[self createGroupChangeInfo:group]];
    }
    
    return groupChangeList;
}
+(NSDictionary*)createGroupChangeInfo:(TIMGroupTipsElemGroupInfo*)group
{
    NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
    
    [groupInfo setValue:[NSNumber numberWithInteger:group.type] forKey:@"type"];
    [groupInfo setValue:group.value forKey:@"value"];
    
    return groupInfo;
}

+(NSDictionary*)createMemberChangeInfo:(TIMGroupTipsElemMemberInfo*)member
{
    NSMutableDictionary *memberInfo = [[NSMutableDictionary alloc] init];
    
    [memberInfo setValue:member.identifier forKey:@"identifier"];
    [memberInfo setValue:[NSNumber numberWithUnsignedInt:member.shutupTime] forKey:@"shutupTime"];
    
    return memberInfo;
}
+(NSArray*)createMemberChangeList:(NSArray*)memberChanges
{
    NSMutableArray *memberChangeList = [[NSMutableArray alloc] init];
    
    for (TIMGroupTipsElemMemberInfo *member in memberChanges)
    {
        [memberChangeList addObject:[self createMemberChangeInfo:member]];
    }
    
    return memberChangeList;
}

+(NSDictionary*)createUserInfo:(TIMUserProfile*)profile
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

+(NSDictionary*)createGroupMemberInfo:(TIMGroupMemberInfo*)memberInfo
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

+(NSDictionary*)createChangedUserInfo:(NSDictionary*)changedUserInfo
{
    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in changedUserInfo)
    {
        [infoList setValue:[self createUserInfo:[changedUserInfo objectForKey:key]] forKey:key];
    }
    
    return infoList;
}

+(NSDictionary*)createChangedGroupMemberInfo:(NSDictionary*)changedGroupMemberInfo
{
    NSMutableDictionary *infoList = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in changedGroupMemberInfo)
    {
        [infoList setValue:[self createGroupMemberInfo:[changedGroupMemberInfo objectForKey:key]] forKey:key];
    }
    
    return infoList;
}


@end
