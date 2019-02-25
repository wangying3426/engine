package io.flutter.view;

import java.nio.ByteBuffer;

import io.flutter.plugin.common.BinaryMessenger;

/**
 * Created by Xie Ran on 2019/2/25.
 * Email:xieran.sai@bytedance.com
 */
public interface IFlutterView extends TextureRegistry, BinaryMessenger {
    void updateSemantics(ByteBuffer buffer, String[] strings);
    void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings);
    void onFirstFrame();
    void resetAccessibilityTree();
}
