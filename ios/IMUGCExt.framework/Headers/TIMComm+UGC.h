//
//  TIMComm+UGC.h
//  IMUGCExt
//
//  Created by tomzhu on 2017/4/28.
//
//

#ifndef TIMComm_UGC_h
#define TIMComm_UGC_h

#import <ImSDK/ImSDK.h>

#pragma mark - block回调

/**
 *  UGC视频上传进度
 *
 *  @param progress 上传进度:0~100
 */
typedef void (^TIMUGCUploadProgress)(int progress);

/**
 *  UGC视频上传进度
 *
 *  @param videoId      视频id
 *  @param videoUrl     视频url
 *  @param coverUrl     封面图片url
 */
typedef void (^TIMUGCUploadSucc)(NSString * videoId, NSString * videoUrl, NSString * coverUrl);

#endif /* TIMComm_UGC_h */
