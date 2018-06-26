package com.dk.tim.im;

import android.content.Context;
import android.os.Environment;
import android.util.Log;

import com.dk.tim.bean.MsgRecBean;
import com.dk.tim.bean.WrapperBean;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.tencent.imsdk.TIMCallBack;
import com.tencent.imsdk.TIMConnListener;
import com.tencent.imsdk.TIMConversation;
import com.tencent.imsdk.TIMElem;
import com.tencent.imsdk.TIMGroupEventListener;
import com.tencent.imsdk.TIMGroupTipsElem;
import com.tencent.imsdk.TIMLogLevel;
import com.tencent.imsdk.TIMManager;
import com.tencent.imsdk.TIMMessage;
import com.tencent.imsdk.TIMMessageListener;
import com.tencent.imsdk.TIMOfflinePushToken;
import com.tencent.imsdk.TIMRefreshListener;
import com.tencent.imsdk.TIMSdkConfig;
import com.tencent.imsdk.TIMTextElem;
import com.tencent.imsdk.TIMUserConfig;
import com.tencent.imsdk.TIMUserStatusListener;
import com.tencent.imsdk.ext.message.TIMMessageLocator;
import com.tencent.imsdk.ext.message.TIMMessageRevokedListener;
import com.tencent.imsdk.ext.message.TIMUserConfigMsgExt;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by Administrator on 2018/6/12.
 */

public class ImHelper {
    private static final String tag = "dk_im";
    private static Gson gson = new Gson();

    public static void initIM(int sdkAppId, Context context) {
        //初始化 SDK 基本配置
        TIMSdkConfig config = new TIMSdkConfig(sdkAppId)//1400102005
                .enableCrashReport(false)
                .enableLogPrint(true)
                .setLogLevel(TIMLogLevel.DEBUG)
                .setLogPath(Environment.getExternalStorageDirectory().getPath() + "/justfortest/");

        //初始化 SDK
        TIMManager.getInstance().init(context, config);
    }

    public static void initUserInfo(boolean enableReadReceipt, final IMsgListener iMsgListener, final IConnectionListener iConnectionListener) {
        //基本用户配置
        TIMUserConfig userConfig = new TIMUserConfig()
                //设置群组资料拉取字段
//                .setGroupSettings(initGroupSettings())
                //设置资料关系链拉取字段
//                .setFriendshipSettings(initFriendshipSettings())
                //设置用户状态变更事件监听器
                .setUserStatusListener(new TIMUserStatusListener() {
                    @Override
                    public void onForceOffline() {
                        //被其他终端踢下线
                        Log.i(tag, "onForceOffline");
                    }

                    @Override
                    public void onUserSigExpired() {
                        //用户签名过期了，需要刷新 userSig 重新登录 SDK
                        Log.i(tag, "onUserSigExpired");
                    }
                })
                //设置连接状态事件监听器
                .setConnectionListener(new TIMConnListener() {
                    @Override
                    public void onConnected() {
                        Log.i(tag, "onConnected");
                        WrapperBean bean = new WrapperBean();
                        bean.code = ConstantsIm.SUCCESS_CODE;
                        iConnectionListener.onConnectionStatus(gson.toJson(bean));
                    }

                    @Override
                    public void onDisconnected(int code, String desc) {
                        Log.i(tag, "onDisconnected");
                        WrapperBean bean = new WrapperBean();
                        bean.code = code;
                        bean.msg = desc;
                        iConnectionListener.onConnectionStatus(gson.toJson(bean));
                    }

                    @Override
                    public void onWifiNeedAuth(String name) {
                        Log.i(tag, "onWifiNeedAuth");
                    }
                })
                //设置群组事件监听器
                .setGroupEventListener(new TIMGroupEventListener() {
                    @Override
                    public void onGroupTipsEvent(TIMGroupTipsElem elem) {
                        Log.i(tag, "onGroupTipsEvent, type: " + elem.getTipsType());
                    }
                })
                //设置会话刷新监听器
                .setRefreshListener(new TIMRefreshListener() {
                    @Override
                    public void onRefresh() {
                        Log.i(tag, "onRefresh");
                    }

                    @Override
                    public void onRefreshConversation(List<TIMConversation> conversations) {
                        Log.i(tag, "onRefreshConversation, conversation size: " + conversations.size());
                    }
                });
        TIMUserConfigMsgExt configMsgExt = new TIMUserConfigMsgExt(userConfig);
        configMsgExt.setMessageRevokedListener(new TIMMessageRevokedListener() {
            @Override
            public void onMessageRevoked(TIMMessageLocator timMessageLocator) {
                iMsgListener.onReceiveMsg(gson.toJson(timMessageLocator));
            }
        });
        //消息扩展用户配置
        userConfig = configMsgExt
                //禁用消息存储
                .enableStorage(false)
                //开启消息已读回执
                .enableReadReceipt(enableReadReceipt);

        //将用户配置与通讯管理器进行绑定
        TIMManager.getInstance().setUserConfig(userConfig);
    }

    /**
     * 登录
     *
     * @param identifier   用户帐号
     * @param userSig      userSig，用户帐号签名，由私钥加密获得，具体请参考文档
     * @param iTimCallback
     */
    public static void login(String identifier, String userSig, final ITimCallback iTimCallback, final IMsgListener iMsgListener) {
        TIMManager timManager = TIMManager.getInstance();

        timManager.addMessageListener(new TIMMessageListener() {
            @Override
            public boolean onNewMessages(List<TIMMessage> list) {
                ArrayList<MsgRecBean> msgRecBeans = new ArrayList<>();
                ArrayList<TIMElem> timElems;
                MsgRecBean msgRec;
                TIMMessage msg;
                for (int j = 0; j < list.size(); j++) {
                    msg = list.get(j);
                    msgRec = new MsgRecBean();
                    msgRec.conversation = msg.getConversation();
                    timElems = new ArrayList<>();
                    for (int i = 0; i < msg.getElementCount(); ++i) {
                        timElems.add(msg.getElement(i));
//                        TIMElem elem = msg.getElement(i);
                    }
                    msgRec.msg = timElems;
                    msgRecBeans.add(msgRec);
                }
                System.out.println("---------------------------" + gson.toJson(msgRecBeans));
                if (msgRecBeans.isEmpty())
                    return false;
                iMsgListener.onReceiveMsg(gson.toJson(msgRecBeans));
                return false;
            }
        });
        // identifier为用户名，userSig 为用户登录凭证
        timManager.login(identifier, userSig, new TIMCallBack() {
            @Override
            public void onError(int code, String desc) {
                //错误码 code 和错误描述 desc，可用于定位请求失败原因
                //错误码 code 列表请参见错误码表
                Log.d(tag, "login failed. code: " + code + " errmsg: " + desc);
                WritableMap map = Arguments.createMap();
                map.putInt(ConstantsIm.CODE, code);
                map.putString(ConstantsIm.MSG, desc);
                iTimCallback.failure(map);
            }

            @Override
            public void onSuccess() {
                WrapperBean bean = new WrapperBean();
                bean.code = ConstantsIm.SUCCESS_CODE;
                bean.msg = "login succ";
                iTimCallback.success(gson.toJson(bean));
            }
        });
    }

    /**
     * 注销
     *
     * @param callback 回调，不需要可以填 null
     */
    public static void logout(TIMCallBack callback) {
        //登出
        TIMManager.getInstance().logout(new TIMCallBack() {
            @Override
            public void onError(int code, String desc) {

                //错误码 code 和错误描述 desc，可用于定位请求失败原因
                //错误码 code 列表请参见错误码表
                Log.d(tag, "logout failed. code: " + code + " errmsg: " + desc);
            }

            @Override
            public void onSuccess() {
                //登出成功
            }
        });
    }

    public static void registerToken(ReadableMap param, final ITimCallback iTimCallback) {
        long bussId = Long.valueOf(param.getString("busiId"));
        //登录成功后，上报证书 ID 及设备 token
        TIMOfflinePushToken pushToken = new TIMOfflinePushToken(bussId, param.getString("token"));
        TIMManager.getInstance().setOfflinePushToken(pushToken, new TIMCallBack() {
            @Override
            public void onError(int i, String s) {
                WritableMap map = Arguments.createMap();
                map.putInt(ConstantsIm.CODE, i);
                map.putString(ConstantsIm.MSG, s);
                iTimCallback.failure(map);
            }

            @Override
            public void onSuccess() {
                WrapperBean bean = new WrapperBean();
                bean.code = ConstantsIm.SUCCESS_CODE;
                bean.msg = "register succ";
                iTimCallback.success(gson.toJson(bean));
            }
        });
    }

}
