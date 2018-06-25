//
//  TIMFriendshipManager+Ext.h
//  IMFriendshipExt
//
//  Created by tomzhu on 2017/1/19.
//
//

#ifndef TIMFriendshipManager_Ext_h
#define TIMFriendshipManager_Ext_h

#import <ImSDK/ImSDK.h>
#import "TIMComm+FriendshipExt.h"

@interface TIMFriendshipManager (Ext)

/**
 *  设置好友备注
 *
 *  @param identifier 用户标识
 *  @param remark 备注
 *  @param succ 成功回调
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)setFriendRemark:(NSString*)identifier remark:(NSString*)remark succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  设置好友自定义属性
 *
 *  @param identifier 用户标识
 *  @param custom     自定义属性（NSString*,NSData*）
 *  @param succ       成功回调
 *  @param fail       失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)setFriendCustom:(NSString*)identifier custom:(NSDictionary*)custom succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  添加好友
 *
 *  @param users 要添加的用户列表 TIMAddFriendRequest* 列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)addFriend:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  删除好友
 *
 *  @param delType 删除类型（单向好友、双向好友）
 *  @param users 要删除的用户列表 NSString* 列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)delFriend:(TIMDelFriendType)delType users:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  获取好友列表
 *
 *  @param succ 成功回调，返回好友列表，TIMUserProfile* 列表，只包含identifier，nickname，remark 三个字段
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getFriendList:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  获取好友列表（可增量、分页、自定义拉取字段）
 *
 *  @param flags 设置需要拉取的字段
 *  @param custom 自定义字段（目前还不支持）
 *  @param meta 好友元信息（详见TIMFriendMetaInfo说明）
 *  @param succ 成功回调
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getFriendListByPage:(TIMProfileFlag)flags custom:(NSArray*)custom meta:(TIMFriendMetaInfo*)meta succ:(TIMGetFriendListByPageSucc)succ fail:(TIMFail)fail;

/**
 *  获取指定好友资料
 *
 *  @param users 要获取的好友列表 NSString* 列表
 *  @param succ  成功回调，返回 TIMUserProfile* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getFriendsProfile:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  响应对方好友邀请
 *
 *  @param users     响应的用户列表，TIMFriendResponse列表
 *  @param succ      成功回调，返回 TIMFriendResult* 列表
 *  @param fail      失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)doResponse:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  添加用户到黑名单
 *
 *  @param users 用户列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)addBlackList:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  把用户从黑名单中删除
 *
 *  @param users 用户列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)delBlackList:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  获取黑名单列表
 *
 *  @param succ 成功回调，返回NSString*列表
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getBlackList:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  通过网络获取未决请求列表
 *
 *  @param meta  请求信息，详细参考TIMFriendPendencyMeta
 *  @param type  拉取类型（参考TIMPendencyGetType）
 *  @param succ 成功回调
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getPendencyFromServer:(TIMFriendPendencyMeta*)meta type:(TIMPendencyGetType)type succ:(TIMGetFriendPendencyListSucc)succ fail:(TIMFail)fail;

/**
 *  未决删除
 *
 *  @param type  未决好友类型
 *  @param users 要删除的未决列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)deletePendency:(TIMPendencyGetType)type users:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  未决请求已读上报
 *
 *  @param timestamp 已读时间戳，此时间戳以前的消息都将置为已读
 *  @param succ  成功回调
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)pendencyReport:(uint64_t)timestamp succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  推荐好友已读上报
 *
 *  @param timestamp 已读时间戳，此时间戳以前的消息都将置为已读
 *  @param succ  成功回调
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)recommendReport:(uint64_t)timestamp succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  推荐好友删除
 *
 *  @param users 要删除的推荐好友列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)deleteRecommend:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  已决删除
 *
 *  @param users 要删除的已决列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)deleteDecide:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;


/**
 *  未决请求和好友推荐拉取
 *
 *  @param flags        获取的资料标识
 *  @param futureFlag   获取的类型，按位设置
 *  @param custom       自定义字段，（尚未实现，填nil）
 *  @param meta         请求信息，参见TIMFriendFutureMeta
 *  @param succ  成功回调
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getFutureFriends:(TIMProfileFlag)flags futureFlag:(TIMFutureFriendType)futureFlag custom:(NSArray*)custom meta:(TIMFriendFutureMeta*)meta succ:(TIMGetFriendFutureListSucc)succ fail:(TIMFail)fail;

/**
 *  按昵称信息搜索用户资料
 *
 *  @param nickName    用户名称内容
 *  @param pageIndex   分页号
 *  @param pageSize    每页用户数目
 *  @param succ  成功回调，返回 TIMUserProfile* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)searchUser:(NSString*)nickName pageIndex:(uint64_t)pageIndex pageSize:(uint64_t)pageSize succ:(TIMUserSearchSucc)succ fail:(TIMFail)fail DEPRECATED_ATTRIBUTE;

/**
 *  新建好友分组
 *
 *  @param groupNames  分组名称列表,必须是当前不存在的分组
 *  @param users       要添加到分组中的好友列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)createFriendGroup:(NSArray*)groupNames users:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  删除好友分组
 *
 *  @param groupNames  要删除的好友分组名称列表
 *  @param succ  成功回调
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)deleteFriendGroup:(NSArray*)groupNames succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  添加好友到一个好友分组
 *
 *  @param groupName   好友分组名称
 *  @param users       要添加到分组中的好友列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)addFriendsToFriendGroup:(NSString*)groupName users:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  从好友分组中删除好友
 *
 *  @param groupName   好友分组名称
 *  @param users       要移出分组的好友列表
 *  @param succ  成功回调，返回 TIMFriendResult* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)delFriendsFromFriendGroup:(NSString*)groupName users:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;

/**
 *  修改好友分组的名称
 *
 *  @param oldName   原来的分组名称
 *  @param newName   新的分组名称
 *  @param succ  成功回调
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)renameFriendGroup:(NSString*)oldName newName:(NSString*)newName succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  获取指定的好友分组信息
 *
 *  @param groupNames      要获取信息的好友分组名称列表,传入nil获得所有分组信息
 *  @param succ  成功回调，返回 TIMFriendGroup* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getFriendGroups:(NSArray*)groupNames succ:(TIMFriendGroupSucc)succ fail:(TIMFail)fail;

/**
 *  检查指定用户的好友关系
 *
 *  @param checkInfo 好友检查信息
 *  @param succ  成功回调，返回检查结果
 *  @param fail  失败回调
 *
 *  @return 0 发送成功
 */
- (int)checkFriends:(TIMFriendCheckInfo*)checkInfo succ:(TIMFriendCheckSucc)succ fail:(TIMFail)fail;

#pragma mark - 开启本地缓存后有效

/**
 *  获取指定好友资料
 *
 *  @param users 好友id（NSString*）列表，nil时返回全部
 *
 *  @return 好友资料（TIMUserProfile*）列表，proxy未同步时返回nil
 */
- (NSArray*)getFriendsProfile:(NSArray*)users;

/**
 *  获取指定好友分组
 *
 *  @param groups 好友分组名称（NSString*）列表，nil时返回全部
 *
 *  @return 好友分组（TIMFriendGroupWithProfiles*）列表，proxy未同步时返回nil
 */
- (NSArray*)getFriendGroup:(NSArray*)groups;

@end

#endif /* TIMFriendshipManager_Ext_h */
