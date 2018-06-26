package com.dk.tim.im;

import com.facebook.react.bridge.WritableMap;

/**
 * Created by woo.lin on 2018/6/13.
 */

public interface ITimCallback {
    void success(Object map);

    void failure(WritableMap map);
}
