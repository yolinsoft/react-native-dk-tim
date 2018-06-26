package com.dk.tim.im;

import android.util.Log;

import com.dk.tim.bean.WrapperBean;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.tencent.imsdk.TIMConversation;
import com.tencent.imsdk.TIMConversationType;
import com.tencent.imsdk.TIMManager;
import com.tencent.imsdk.TIMMessage;
import com.tencent.imsdk.TIMTextElem;
import com.tencent.imsdk.TIMValueCallBack;
import com.tencent.imsdk.ext.message.TIMConversationExt;
import com.tencent.imsdk.ext.message.TIMManagerExt;
import com.tencent.imsdk.ext.message.TIMMessageDraft;

import java.util.List;

/**
 * Created by woo.lin on 2018/6/19.
 */

public class Conversation {
    private static final String tag = "CONVERSATION";
    private static Gson gson = new Gson();

    //获取所有会话
    public static List<TIMConversation> getList() {
        return TIMManagerExt.getInstance().getConversationList();
    }

    /**
     * 仅获取本地聊天记录
     */
    public static void getLocalMessage(final ReadableMap param, final ITimCallback iTimCallback) {
        TIMConversationExt conExt = getConversationExt(param);
        ;

        int msgCount = 1;
        try {
            msgCount = Integer.valueOf(param.getString("msgCount"));
        } catch (Exception e) {
            e.printStackTrace();
        }

        TIMMessage timMessage = gson.fromJson(param.getString("msg"), TIMMessage.class);
        //获取此会话的消息
        conExt.getLocalMessage(msgCount, //获取此会话最近的 10 条消息
                timMessage, //不指定从哪条消息开始获取 - 等同于从最新的消息开始往前
                new TIMValueCallBack<List<TIMMessage>>() {//回调接口
                    @Override
                    public void onError(int code, String desc) {//获取消息失败
                        //接口返回了错误码 code 和错误描述 desc，可用于定位请求失败原因
                        //错误码 code 含义请参见错误码表
                        Log.d(tag, "get message failed. code: " + code + " errmsg: " + desc);
                        WritableMap map = Arguments.createMap();
                        map.putInt(ConstantsIm.CODE, code);
                        map.putString(ConstantsIm.MSG, desc);
                        iTimCallback.failure(map);
                    }

                    @Override
                    public void onSuccess(List<TIMMessage> msgs) {//获取消息成功
//                        //遍历取得的消息
//                        for (TIMMessage msg : msgs) {
//                            //可以通过 timestamp()获得消息的时间戳, isSelf()是否为自己发送的消息
//                            Log.e(tag, "get msg: " + msg.timestamp() + " self: " + msg.isSelf() + " seq: " + msg.getMsg().seq());
//
//                        }
                        if (msgs == null) {
                            WritableMap map = Arguments.createMap();
                            map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
                            map.putString(ConstantsIm.MSG, "error");
                            iTimCallback.failure(map);
                        } else {
                            WrapperBean bean = new WrapperBean();
                            bean.code = ConstantsIm.SUCCESS_CODE;
                            bean.Data = msgs;
                            iTimCallback.success(gson.toJson(bean));
                        }
                    }
                });
    }

    /**
     * 删除会话
     *
     * @param param
     */
    public static void deleteConversation(ReadableMap param, ITimCallback iTimCallback) {
        boolean isDelete;
        TIMConversationType type = TIMConversationType.Invalid;
        switch (param.getInt("type")) {
            case ConstantsIm.TYPE_SINGLE:
                type = TIMConversationType.C2C;  //会话类型：单聊
                break;
            case ConstantsIm.TYPE_GROUP:
                type = TIMConversationType.Group;   //会话类型：群聊
                break;
            case ConstantsIm.TYPE_SYSTEM:
                type = TIMConversationType.System;   //会话类型：系统
                break;
        }
        //是否删除本地消息
        if (!param.getBoolean("isDeletMsg")) {
            isDelete = TIMManagerExt.getInstance().deleteConversation(type, param.getString("conversationId"));
        } else {
            //同时删除消息
            isDelete = TIMManagerExt.getInstance().deleteConversationAndLocalMsgs(type, param.getString("conversationId"));
        }
        if (isDelete) {
            WrapperBean bean = new WrapperBean();
            bean.code = ConstantsIm.SUCCESS_CODE;
            iTimCallback.success(gson.toJson(bean));
        } else {
            WritableMap map = Arguments.createMap();
            map.putInt(ConstantsIm.CODE, ConstantsIm.FAIL_CODE);
            map.putString(ConstantsIm.MSG, "error");
            iTimCallback.failure(map);
        }
    }

    /**
     * 从 cache 中获取最后几条消息
     *
     * @param param 需要获取的消息数，最多为 20
     * @return 消息列表，第一条为最新消息。会话非法时，返回 null。
     */
    public static String getLastMsg(ReadableMap param) {
        TIMConversationExt conExt = getConversationExt(param);
        ;

        int msgCount = 1;
        try {
            msgCount = Integer.valueOf(param.getString("MsgCount"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        List<TIMMessage> list = conExt.getLastMsgs(msgCount);
        if (list == null)
            return null;

        WrapperBean bean = new WrapperBean();
        bean.code = ConstantsIm.SUCCESS_CODE;
        bean.Data = list;
        return gson.toJson(bean);
    }

    public static TIMConversationExt getConversationExt(ReadableMap param) {
        TIMConversation con = null;
        switch (param.getInt("type")) {
            case ConstantsIm.TYPE_SINGLE:
                //获取会话扩展实例
                con = TIMManager.getInstance().getConversation(TIMConversationType.C2C, param.getString("conversationId"));
                break;
            case ConstantsIm.TYPE_GROUP:
                con = TIMManager.getInstance().getConversation(TIMConversationType.Group, param.getString("conversationId"));
                break;
            case ConstantsIm.TYPE_SYSTEM:
                con = TIMManager.getInstance().getConversation(TIMConversationType.System, param.getString("conversationId"));
                break;
        }

        return new TIMConversationExt(con);
    }

    public static int setDraft(ReadableMap param) {
        TIMConversationExt conExt = getConversationExt(param);

        TIMMessageDraft draft = new TIMMessageDraft();
        //添加文本内容
        TIMTextElem elem = new TIMTextElem();
        elem.setText(param.getString("draft"));
        draft.addElem(elem);
        conExt.setDraft(draft);
        if (conExt.hasDraft()) {
            return ConstantsIm.SUCCESS_CODE;
        } else {
            return ConstantsIm.FAIL_CODE;
        }
    }

    public static void getDraft(ReadableMap param, Promise promise) {
        TIMConversationExt conExt = getConversationExt(param);
        TIMMessageDraft data = conExt.getDraft();
        WrapperBean bean = new WrapperBean();
        if (data == null) {
            promise.reject(ConstantsIm.FAIL_CODE + "", "");
        } else {
            bean.code = ConstantsIm.SUCCESS_CODE;
            bean.Data = data;
            promise.resolve(gson.toJson(bean));
        }
    }
}
