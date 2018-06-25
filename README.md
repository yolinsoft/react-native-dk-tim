# react native 腾讯云通讯插件

云通信（Instant Messaging）承载亿级 QQ 用户即时通信技术，数十年技术积累，腾讯云为您提供超乎寻常即时通信聊天服务。

### 一、安装

#### android

暂无

#### ios

 添加以下依赖库

CoreTelephony.framework  
SystemConfiguration.framework  
libstdc++.6.dylib  
libc++.dylib  
libz.dylib  
libsqlite3.dylib

### 二、调用方法

#### 基础方法

| 方法名              | 参数                                     | 类型 | 描述                                                                               |
| ------------------- | ---------------------------------------- | ---- | ---------------------------------------------------------------------------------- |
| initSDK             | {sdkAppId:'',accountType:''}             | func | 设置 SDK 配置信息<br/>sdkAppId 应用 ID<br/>accountType 帐号体系                    |
| setUserConfig       | {enableReadReceipt:true,accountType:''}  | func | 设置用户的配置信息<br>enableReadReceipt 开启 C2C 已读回执<br/>accountType 帐号体系 |
| login               | {userSig:'',appidAt3rd:'',identifier:''} | func | 用户登录<br>userSig 用户登录凭证<br/>appidAt3rd 应用 ID<br/>identifier 用户帐号    |
| sendMsg             | {msg:'',type:1,receiver:''}              | func | 发送消息<br>msg 消息内容<br/>type 1.单聊 2.群聊 3.系统消息<br/>receiver 接收者     |
| registerDeviceToken | {token :''}                              | func | 注册 token 推送消息使用<br>token 用户标识                                          |
| appEnterForeground  | 无                                       | func | 程序进入前台                                                                       |
| appEnterBackground  | 无                                       | func | 程序进入后台                                                                       |

#### 会话操作

| 方法名                     | 参数                                      | 类型 | 描述                                                                                            |
| -------------------------- | ----------------------------------------- | ---- | ----------------------------------------------------------------------------------------------- |
| getConversaionList         | 无                                        | func | 获取所有会话                                                                                    |
| getMsgByConversationType   | {msgCount:10,lastMsg:''}                  | func | 获取某条会话的本地消息<br>msgCount 获取数量<br/>lastMsg 上次最后一条消息                        |
| deletConversationType      | {isDeletMsg:1}                            | func | 删除会话<br>isDeletMsg 删除会话的同时是否删除会话的本地消息                                     |
| getConversationLastMsgType | {MsgCount:20}                             | func | 获取会话最后一条消息<br>MsgCount 需要获取的消息数，最多为 20                                    |
| sendOlineMsg               | {msg:'',conversationType:1,receiver:''}   | func | 发送在线消息<br/>msg 消息内容<br/>conversationType 1.单聊 2.群聊 3.系统消息<br/>receiver 接收者 |
| revokeMsg                  | {msg:'',conversationType:1,receiver:''}   | func | 撤回消息<br/>msg 消息内容<br/>conversationType 1.单聊 2.群聊 3.系统消息<br/>receiver 接收者     |
| setDraft                   | {draft:'',conversationType:1,receiver:''} | func | 保存草稿<br/>draft 消息内容<br/>conversationType 1.单聊 2.群聊 3.系统消息<br/>receiver 接收者   |
| getDraftConversationType   | {type:1,receiver:''}                      | func | 获取草稿信息<br/>type 1.单聊 2.群聊 3.系统消息<br/>receiver 接收者                              |

发送消息模板

```
{
  offlinePush：{
      desc：“”，//自定义消息描述信息，做离线Push时文本展示
       ext：””,//离线Push时扩展字段信息
       iosConfig : {
          sound : “”,//离线Push时声音字段信息
          ignoreBadge : “”  //忽略badge计数
        }
       androidConfig : {
           title : “”,// 离线推送时展示标签
           sound : “”,//Android离线Push时声音字段信息
           notifyMode : “”// 0 通知栏消息 。1 不弹窗，由应用自行处理
        }
    },
  type : “text / image /  audio /  location / file / custom”,//消息类型
  data ：“”, // text 类型 的文本内容
  path ：“”，//image 、audio 、文件 类型 的本地路径
  format : “”, //  image 类型 的图片格式   1 jpg   2 gif   3png  4 bmp  5未知
  duration ：”” 发送消息时的语音长度
  desc : “”  地理位置描述信息，发送消息时设置
  lat : “” 纬度
  log : “” 经度
  filename : “” //文件名
}
```

### 三、示例

```
import TIM from 'react-native-dk-tim';

// 应用配置
const sdkAppId = '1400062998';
const accountType = '27442'

// 初始化参数
let initParams = {
  sdkAppId: sdkAppId,
  accountType: accountType
}

// 配置信息参数
let configParams = {
  enableReadReceipt: true,
  accountType: accountType
}

// 登录参数
let loginParams = {
  userSig:
            'eJxlj0tPg0AUhff8CsJWY4ZBXiYuSAVbigtTiZTNhM4McEPKc4CWxv*u0iaSeLffd3LOvUiyLCsfwe4hobTqS0HEueaK-CQrSLn-g3UNjCSCaC37B-mphpaTJBW8naGq6zpGaOkA46WAFG7GW5IBXeCOFWTuuOYff8IGtm1rqUB2jbrhauM2zdGzXiPNQ4GRZo3fjnk8VYdV-3lHp369CcageI8GCLcOuI5l2OfDtC5ovDVzZvbe6Hgh*Lv9yz6Ph1NhqX5Hg7FhUfW8qBRw5LeHsIk1bGvLQQNvO6jKWcBI1VWsod9TpC-pG4z-XlI_',
          appidAt3rd: sdkAppId,
          identifier: 'Magic'
}

// 设置 SDK 配置信息
TIM.initSDK(initParams).then(
  res => {
    console.warn(['initSDK success', res]);

    // 设置用户的配置信息
    TIM.setUserConfig(configParams).then(
      res => {
        console.warn(['setUserConfig success', res]);

        // 登录
        TIM.login(loginParams).then(
          res => {
            console.warn(['login success', res]);
          },
          err => {
            console.warn(['login fail', err]);
          }
        );
      },
      err => {
        console.warn(['setUserConfig fail', err]);
      }
    );
  },
  err => {
    console.warn(['initSDK fail', err]);
  }
);
```

### 四、集成问题

> 注意：  
> 使用互动直播业务的开发者，请集成 ImSDKv2 版本。
