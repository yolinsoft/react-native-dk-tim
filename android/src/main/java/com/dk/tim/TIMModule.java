package com.dk.tim;

import android.support.annotation.Nullable;
import android.text.TextUtils;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.gson.Gson;
import com.dk.tim.bean.WrapperBean;
import com.dk.tim.im.ConstantsIm;
import com.dk.tim.im.Conversation;
import com.dk.tim.im.IConnectionListener;
import com.dk.tim.im.IMsgListener;
import com.dk.tim.im.ITimCallback;
import com.dk.tim.im.ImHelper;
import com.dk.tim.im.ImMessage;

public class TIMModule extends ReactContextBaseJavaModule {
    private Gson gson;

    public TIMModule(ReactApplicationContext reactContext) {
        super(reactContext);
        gson = new Gson();
    }

    @Override
    public String getName() {
        return "TIM";
    }

    @ReactMethod
    public void initSdk(ReadableMap param, Promise promise) {
        ImHelper.initIM(Integer.valueOf(param.getString("sdkAppId")), getReactApplicationContext());
        WrapperBean bean = new WrapperBean();
        bean.code = ConstantsIm.SUCCESS_CODE;
        promise.resolve(gson.toJson(bean));
    }

    @ReactMethod
    public void setUserConfig(ReadableMap param, Promise promise) {
        ImHelper.initUserInfo(param.getBoolean("enableReadReceipt"), new IMsgListener() {
            @Override
            public void onReceiveMsg(Object params) {
                sendEvent(getReactApplicationContext(), "MsgLocator", params);
            }
        }, new IConnectionListener() {
            @Override
            public void onConnectionStatus(Object param) {
                sendEvent(getReactApplicationContext(), "Connection", param);
            }
        });
        WrapperBean bean = new WrapperBean();
        bean.code = ConstantsIm.SUCCESS_CODE;
        promise.resolve(gson.toJson(bean));
    }

    @ReactMethod
    public void login(final ReadableMap param, final Promise promise) {
        ImHelper.login(param.getString("identifier"), param.getString("userSig"), new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        }, new IMsgListener() {
            @Override
            public void onReceiveMsg(Object params) {
                sendEvent(getReactApplicationContext(), "Message", params);
            }
        });

    }

    @ReactMethod
    public void sendMsg(ReadableMap param, final Promise promise) {
        ImMessage.setContext(getReactApplicationContext());
        ImMessage.send(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    //注册token
    @ReactMethod
    public void registerDeviceToken(ReadableMap param, final Promise promise) {
        ImHelper.registerToken(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    //程序进入前台
    @ReactMethod
    public void appEnterForeground(Promise promise) {

    }

    //程序进入后台
    @ReactMethod
    public void appEnterBackground(Promise promise) {

    }


    @ReactMethod
    public void getConversaionList(Promise promise) {
        WrapperBean bean = new WrapperBean();
        bean.code = ConstantsIm.SUCCESS_CODE;
        bean.Data = Conversation.getList();
        promise.resolve(gson.toJson(bean));
    }

    @ReactMethod
    public void getMsgByConversation(ReadableMap param, final Promise promise) {
        Conversation.getLocalMessage(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    @ReactMethod
    public void deletConversation(ReadableMap param, final Promise promise) {
        Conversation.deleteConversation(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    @ReactMethod
    public void getConversationLastMsg(ReadableMap param, final Promise promise) {
        String data = Conversation.getLastMsg(param);
        if (TextUtils.isEmpty(data)) {
            promise.reject(ConstantsIm.FAIL_CODE + "", "");
        } else {
            promise.resolve(data);
        }
    }

    @ReactMethod
    public void sendOlineMsg(ReadableMap param, final Promise promise) {
        ImMessage.sendOnlineMsg(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    @ReactMethod
    public void revokeMsg(ReadableMap param, final Promise promise) {
        ImMessage.revokeMessage(param, new ITimCallback() {
            @Override
            public void success(Object map) {
                promise.resolve(map);
            }

            @Override
            public void failure(WritableMap map) {
                promise.reject(map.getInt(ConstantsIm.CODE) + "", map.getString(ConstantsIm.MSG));
            }
        });
    }

    //保存草稿
    @ReactMethod
    public void setDraft(ReadableMap param, final Promise promise) {
        int result = Conversation.setDraft(param);
        WrapperBean bean = new WrapperBean();
        bean.code = result;
        if (result == ConstantsIm.SUCCESS_CODE)
            promise.resolve(gson.toJson(bean));
        else
            promise.reject(result + "", "");
    }

    //获取草稿
    @ReactMethod
    public void getDraftConversation(ReadableMap param, Promise promise) {
        Conversation.getDraft(param, promise);
    }

    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable Object params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

}