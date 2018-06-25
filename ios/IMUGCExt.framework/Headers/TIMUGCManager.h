//
//  TIMUGCManager.h
//  IMUGCExt
//
//  Created by tomzhu on 2017/4/28.
//
//

#ifndef TIMUGCManager_h
#define TIMUGCManager_h

#import <ImSDK/ImSDK.h>
#import "TIMComm+UGC.h"

@interface TIMUGCManager : NSObject

/**
 *  获取UGC管理器实例
 *
 *  @return 管理器实例
 */
+ (instancetype)sharedInstance;

/**
 *  上传UGC视频
 *
 *  @param videoPath        视频文件路径，填写正确文件类型后缀
 *  @param coverPath        封面图片文件路径，填写正确文件类型后缀
 *  @param uploadListener   上传进度回调
 *  @param succ             成功回调，返回url
 *  @param fail             失败回调
 *
 *  @return 任务id
 */
- (uint64_t)uploadUGCVideo:(NSString*)videoPath coverPath:(NSString*)coverPath uploadListener:(TIMUGCUploadProgress)uploadListener succ:(TIMUGCUploadSucc)succ fail:(TIMFail)fail;

@end

#endif /* TIMUGCManager_h */
