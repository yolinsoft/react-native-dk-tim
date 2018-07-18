package com.dk.tim.im;

import android.content.Context;
import android.net.Uri;
import android.util.Log;

import com.dk.tim.bean.MsgBean;
import com.dk.tim.bean.WrapperBean;
import com.dk.tim.utils.PathConvert;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.tencent.imsdk.TIMCallBack;
import com.tencent.imsdk.TIMConversation;
import com.tencent.imsdk.TIMConversationType;
import com.tencent.imsdk.TIMCustomElem;
import com.tencent.imsdk.TIMElem;
import com.tencent.imsdk.TIMFileElem;
import com.tencent.imsdk.TIMImageElem;
import com.tencent.imsdk.TIMLocationElem;
import com.tencent.imsdk.TIMManager;
import com.tencent.imsdk.TIMMessage;
import com.tencent.imsdk.TIMSoundElem;
import com.tencent.imsdk.TIMTextElem;
import com.tencent.imsdk.TIMValueCallBack;
import com.tencent.imsdk.ext.message.TIMConversationExt;

/**
 * Created by woo.lin on 2018/6/13.
 */

public class ImMessage {

    private static Gson gson = new Gson();
    private static final String tag = "dk_im_message";
    private static String sign = "eJxlj11PgzAARd-5FYTX*dFSKK2JD0MZEcd0k03iC6GjQCVjFboNs*y-q7hEEu-rObk396jpum5E05erdL3e7mqVqE-JDf1GN4Bx8QelFFmSqgQ12T-IOykanqS54k0PoW3bJgBDR2S8ViIXZ4PgS4gQgNihmNoDr82qpB-7LbK*W7BJKRkqouhh6C3vHlwMyezg05gVeBQFfEFf6-3mqXNZNF2FbfzRSSuYEG8CH8fCGwMRMisLFmWXH*bX0Xu1Kp*Xc*b7WDpFVe7Y233sjgqPueHtYFKJDT8-MwlxKEJwQPe8acW27gUTQBuaCPzE0E7aF7FgXWM_";
    private static String userName = "86-13301679695";
    private static Context context;

    public static void setContext(Context context1) {
        context = context1;
    }

    public static void send(ReadableMap param, ITimCallback iTimCallback) {
        TIMConversation conversation;
        String receiver = param.getString("receiver");
        switch (param.getInt("type")) {
            case ConstantsIm.TYPE_SINGLE:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.C2C,    //会话类型：单聊
                        receiver);
                break;
            case ConstantsIm.TYPE_GROUP:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.Group,    //会话类型：群聊
                        receiver);
                break;
            case ConstantsIm.TYPE_SYSTEM:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.System,    //会话类型：系统
                        receiver);
                break;
            default:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.Invalid,    //会话类型：
                        receiver);
        }
        ReadableMap msgMap = param.getMap("msg");
        try {
            switch (msgMap.getString("type")) {
                case ConstantsIm.MSG_TYPE_TEXT:
                    sendText(msgMap, conversation, iTimCallback, false);
                    break;
                case ConstantsIm.MSG_TYPE_IMAGE:
                    sendImage(msgMap, conversation, iTimCallback, false);
                    break;
                case ConstantsIm.MSG_TYPE_AUDIO:
                    sendAudio(msgMap, conversation, iTimCallback, false);
                    break;
                case ConstantsIm.MSG_TYPE_LOCATION:
                    sendLocation(msgMap, conversation, iTimCallback, false);
                    break;
                case ConstantsIm.MSG_TYPE_FILE:
                    sendFile(msgMap, conversation, iTimCallback, false);
                    break;
                case ConstantsIm.MSG_TYPE_CUSTOM:
                    sendCustom(msgMap, conversation, iTimCallback, false);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            WritableMap map = Arguments.createMap();
            map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
            map.putString(ConstantsIm.MSG, "addElement failed");
            iTimCallback.failure(map);
        }

    }

    public static void send(TIMMessage msg, TIMElem elem, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //将elem添加到消息
        if (msg.addElement(elem) != 0) {
            Log.d(tag, "addElement failed");
            WritableMap map = Arguments.createMap();
            map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
            map.putString(ConstantsIm.MSG, "addElement failed");
            iTimCallback.failure(map);
            return;
        }
        if (isOnlineMsg) {
            //发送在线消息
            conversation.sendOnlineMessage(msg, new TIMValueCallBack<TIMMessage>() {//发送消息回调
                @Override
                public void onError(int code, String desc) {//发送消息失败
                    //错误码 code 和错误描述 desc，可用于定位请求失败原因
                    //错误码 code 含义请参见错误码表
                    Log.d(tag, "send message failed. code: " + code + " errmsg: " + desc);
                    WritableMap map = Arguments.createMap();
                    map.putInt(ConstantsIm.CODE, code);
                    map.putString(ConstantsIm.MSG, desc);
                    iTimCallback.failure(map);
                }

                @Override
                public void onSuccess(TIMMessage msg) {//发送消息成功
                    WrapperBean bean = new WrapperBean();
                    bean.code = ConstantsIm.SUCCESS_CODE;
                    bean.msg = "SendMsg succ";
                    iTimCallback.success(gson.toJson(bean));
                }
            });
        } else {
            //发送消息
            conversation.sendMessage(msg, new TIMValueCallBack<TIMMessage>() {//发送消息回调
                @Override
                public void onError(int code, String desc) {//发送消息失败
                    //错误码 code 和错误描述 desc，可用于定位请求失败原因
                    //错误码 code 含义请参见错误码表
                    Log.d(tag, "send message failed. code: " + code + " errmsg: " + desc);
                    WritableMap map = Arguments.createMap();
                    map.putInt(ConstantsIm.CODE, code);
                    map.putString(ConstantsIm.MSG, desc);
                    iTimCallback.failure(map);
                }

                @Override
                public void onSuccess(TIMMessage msg) {//发送消息成功
                    WrapperBean bean = new WrapperBean();
                    bean.code = ConstantsIm.SUCCESS_CODE;
                    bean.msg = "SendMsg succ";
                    iTimCallback.success(gson.toJson(bean));
                }
            });
        }
    }

    public static void sendText(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();

        //添加文本内容
        TIMTextElem elem = new TIMTextElem();
        elem.setText(msgMap.getString("data"));
        send(msg, elem, conversation, iTimCallback, isOnlineMsg);

    }

    public static void sendImage(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();

        //添加图片
        TIMImageElem elem = new TIMImageElem();

        //elem.setPath(PathConvert.getRealPathFromUri(context, Uri.parse(msgMap.getString("path"))));

        //手动过滤"file://"开头
        String imagePath = msgMap.getString("path");
        if (imagePath.startsWith("file://"))
            imagePath = imagePath.substring(7);
        elem.setPath(imagePath);
        
        send(msg, elem, conversation, iTimCallback, isOnlineMsg);
    }

    public static void sendAudio(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();
        //手动过滤"file://"开头
        String audioPath = msgMap.getString("path");
        if (audioPath.startsWith("file://"))
            audioPath = audioPath.substring(7);
        //添加语音
        TIMSoundElem elem = new TIMSoundElem();
        elem.setPath(audioPath); //填写语音文件路径
        elem.setDuration(msgMap.getInt("duration"));  //填写语音时长

        send(msg, elem, conversation, iTimCallback, isOnlineMsg);
    }

    public static void sendLocation(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();

        //添加位置信息
        TIMLocationElem elem = new TIMLocationElem();
        elem.setLatitude(msgMap.getDouble("lat"));   //设置纬度
        elem.setLongitude(msgMap.getDouble("log"));   //设置经度
        elem.setDesc(msgMap.getString("desc"));

        send(msg, elem, conversation, iTimCallback, isOnlineMsg);
    }

    public static void sendFile(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();
        //手动过滤"file://"开头
        String path = msgMap.getString("path");
        if (path.startsWith("file://"))
            path = path.substring(7);
        //添加文件内容
        TIMFileElem elem = new TIMFileElem();
        elem.setPath(path); //设置文件路径
        elem.setFileName(msgMap.getString("filename")); //设置消息展示用的文件名称

        send(msg, elem, conversation, iTimCallback, isOnlineMsg);
    }

    public static void sendCustom(ReadableMap msgMap, TIMConversation conversation, final ITimCallback iTimCallback, boolean isOnlineMsg) {
        //构造一条消息
        TIMMessage msg = new TIMMessage();

        //向 TIMMessage 中添加自定义内容
        TIMCustomElem elem = new TIMCustomElem();
        elem.setData(msgMap.getString("data").getBytes());      //自定义 byte[]
        elem.setDesc(""); //自定义描述信息

        send(msg, elem, conversation, iTimCallback, isOnlineMsg);
    }


    public static void sendOnlineMsg(ReadableMap param, ITimCallback iTimCallback) {
        TIMConversation conversation;
        String receiver = param.getString("receiver");
        switch (param.getInt("type")) {
            case ConstantsIm.TYPE_SINGLE:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.C2C,    //会话类型：单聊
                        receiver);
                break;
            case ConstantsIm.TYPE_GROUP:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.Group,    //会话类型：群聊
                        receiver);
                break;
            case ConstantsIm.TYPE_SYSTEM:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.System,    //会话类型：系统
                        receiver);
                break;
            default:
                conversation = TIMManager.getInstance().getConversation(
                        TIMConversationType.Invalid,    //会话类型：
                        receiver);
        }
        ReadableMap msgMap = param.getMap("msg");
//        MsgBean msgBean = gson.fromJson(param.getString("msg"), MsgBean.class);
        try {
            switch (msgMap.getString("type")) {
                case ConstantsIm.MSG_TYPE_TEXT:
                    sendText(msgMap, conversation, iTimCallback, true);
                    break;
                case ConstantsIm.MSG_TYPE_IMAGE:
                    sendImage(msgMap, conversation, iTimCallback, true);
                    break;
                case ConstantsIm.MSG_TYPE_AUDIO:
                    sendAudio(msgMap, conversation, iTimCallback, true);
                    break;
                case ConstantsIm.MSG_TYPE_LOCATION:
                    sendLocation(msgMap, conversation, iTimCallback, true);
                    break;
                case ConstantsIm.MSG_TYPE_FILE:
                    sendFile(msgMap, conversation, iTimCallback, true);
                    break;
                case ConstantsIm.MSG_TYPE_CUSTOM:
                    sendCustom(msgMap, conversation, iTimCallback, true);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            WritableMap map = Arguments.createMap();
            map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
            map.putString(ConstantsIm.MSG, "addElement failed");
            iTimCallback.failure(map);
        }
    }

    /**
     * 消息撤回（仅 C2C 和 GROUP 会话有效，其中 onlineMessage、AVChatRoom 和 BChatRoom 无效）
     *
     * @since 3.1.0
     */
    public static void revokeMessage(ReadableMap param, final ITimCallback iTimCallback) {
        TIMConversation con = null;
        switch (param.getInt("type")) {
            case ConstantsIm.TYPE_SINGLE:
                //获取会话扩展实例
                con = TIMManager.getInstance().getConversation(TIMConversationType.C2C, param.getString("receiver"));
                break;
            case ConstantsIm.TYPE_GROUP:
                con = TIMManager.getInstance().getConversation(TIMConversationType.Group, param.getString("receiver"));
                break;
            default:
                WritableMap map = Arguments.createMap();
                map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
                map.putString(ConstantsIm.MSG, "不支持该类型");
                iTimCallback.failure(map);
                return;
        }
        TIMConversationExt conExt = new TIMConversationExt(con);
        TIMMessage msgBean = gson.fromJson(param.getString("msg"), TIMMessage.class);
        conExt.revokeMessage(msgBean, new TIMCallBack() {
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
                bean.msg = "revokeMsg succ";
                iTimCallback.success(gson.toJson(bean));
            }
        });
    }
}
