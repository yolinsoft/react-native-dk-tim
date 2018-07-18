//
//  TIM_ConnListener.h
//  TIM
//
//  Created by 马拉古 on 2018/5/28.
//  Copyright © 2018年 shanghaiDouke.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Define.h"
@interface TIM_EventListener : NSObject<TIMConnListener,TIMMessageRevokeListener,TIMUploadProgressListener,TIMGroupEventListener,TIMUserStatusListener>

@end

