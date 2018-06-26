package com.dk.tim.bean;

import com.tencent.imsdk.TIMElem;

import java.io.Serializable;
import java.util.ArrayList;

public class MsgRecBean implements Serializable {
    public Object conversation;
    public ArrayList<TIMElem> msg;
}
