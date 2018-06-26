package com.dk.tim.bean;

import java.io.Serializable;

public class MsgBean implements Serializable {
    public OfflinePushBean offlinePushBean;
    public String type;
    public String data;
    public String path;
    /**
     * image 类型 图片格式  1 jpg  2 gif  3 png  4 bmp  5 未知
     */
    public String format;
    public int duration;
    public String desc;
    public String lat;
    public String log;
    public String filename;
}
