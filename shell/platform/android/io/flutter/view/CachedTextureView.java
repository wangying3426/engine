package io.flutter.view;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Created by niuwei on 16/7/21.
 */
class CachedTextureView extends TextureView {

    private SurfaceTextureListener mSurfaceTextureListener;
    private boolean reuseSurfaceTexture = true;
    private boolean mTextureValid;
    private Surface mCachedSurface;
    private SurfaceTexture mSurfaceTexture;

    public CachedTextureView(Context context) {
        this(context, null);
    }

    public CachedTextureView(Context context, AttributeSet attr) {
        super(context, attr);
        initListener();
    }

    public void setReuseSurfaceTexture(boolean reuse) {
        reuseSurfaceTexture = reuse;
    }

    public boolean isReuseSurfaceTexture() {
        return reuseSurfaceTexture;
    }

    @Override
    protected void onVisibilityChanged(View changedView, int visibility) {
        //fix mi tv 上的空指针异常
        try {
            super.onVisibilityChanged(changedView, visibility);
        } catch (Exception ignore) {}
        if (changedView == this && visibility == View.VISIBLE) {
            setSurfaceTextureIfAvailable();
        }
    }

    @Override
    public void setKeepScreenOn(boolean keepScreenOn) {
        super.setKeepScreenOn(keepScreenOn);
    }

    private void initListener() {
        super.setSurfaceTextureListener(new SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
                if (reuseSurfaceTexture) {
                    if (mCachedSurface != null) {
                        if (!mTextureValid || !mCachedSurface.isValid()) {
                            mCachedSurface.release();
                            mCachedSurface = null;
                            mSurfaceTexture = null;
                        }
                    }
                    if (mCachedSurface == null) {
                        mCachedSurface = new Surface(surface);
                        mSurfaceTexture = surface;
                    } else {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                                if (mSurfaceTexture == null || isSurfaceTextureReleased(mSurfaceTexture)) {
                                    mSurfaceTexture = surface;
                                    mCachedSurface = new Surface(surface);
                                } else if (mSurfaceTexture == getSurfaceTexture()) {
                                    // Log.e(TAG, "onSurfaceTextureAvailable surface equal.");
                                } else {
                                    setSurfaceTexture(mSurfaceTexture);
                                }
                            } else {
                                if (mSurfaceTexture != null) {
                                    mCachedSurface = new Surface(surface);
                                }

                            }
                        } catch (Exception e) {
                            mSurfaceTexture = surface;
                            mCachedSurface = new Surface(surface);
                        }
                    }
                    mTextureValid = true;
                } else {
                    mCachedSurface = new Surface(surface);
                    mSurfaceTexture = surface;
                }
                if (mSurfaceTextureListener != null) {
                    mSurfaceTextureListener.onSurfaceTextureAvailable(mSurfaceTexture, width, height);
                }
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
                if (mSurfaceTextureListener != null) {
                    mSurfaceTextureListener.onSurfaceTextureSizeChanged(surface, width, height);
                }
            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                if (reuseSurfaceTexture) {
                    if (!mTextureValid) {
                        if (mCachedSurface != null) {
                            mCachedSurface.release();
                            mCachedSurface = null;
                            mSurfaceTexture = null;
                        }
                    }
                }

                if (mSurfaceTextureListener != null) {
                    mSurfaceTextureListener.onSurfaceTextureDestroyed(surface);
                }

                if (!reuseSurfaceTexture) {
                    releaseSurface(false);
                }
                return !reuseSurfaceTexture;
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surface) {
                if (mSurfaceTextureListener != null) {
                    mSurfaceTextureListener.onSurfaceTextureUpdated(surface);
                }
            }
        });
    }


    private boolean isSurfaceTextureReleased(SurfaceTexture surfaceTexture) {
        if (surfaceTexture == null) {
            return true;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return surfaceTexture.isReleased();
        } else {
            boolean result = false;
            Method method = getMethod(SurfaceTexture.class, "isReleased", null);
            if (method != null) {
                try {
                    Object o = method.invoke(surfaceTexture);
                    if (o instanceof Boolean) {
                        result = (boolean) o;
                    }
                } catch (IllegalAccessException | InvocationTargetException e) {
                    e.printStackTrace();
                }
            }
            return result;
        }
    }

    @Override
    public void setSurfaceTextureListener(SurfaceTextureListener listener) {
        mSurfaceTextureListener = listener;
    }

    @Override
    protected void onWindowVisibilityChanged(int visibility) {
        super.onWindowVisibilityChanged(visibility);
        if (getVisibility() == View.VISIBLE && visibility == View.VISIBLE) {
            setSurfaceTextureIfAvailable();
        }
    }

    private void setSurfaceTextureIfAvailable() {
        if (reuseSurfaceTexture && Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            if (mSurfaceTexture != null && mTextureValid && mCachedSurface != null
                    && mCachedSurface.isValid() && mSurfaceTexture != getSurfaceTexture()) {
                if (!isSurfaceTextureReleased(mSurfaceTexture)) {
                    setSurfaceTexture(mSurfaceTexture);
                    if (mSurfaceTextureListener != null) {
                        mSurfaceTextureListener.onSurfaceTextureAvailable(mSurfaceTexture, 0, 0);
                    }
                }
            }
        }
    }

    private void releaseSurface(boolean force) {
        if (force && reuseSurfaceTexture) {
            if (mSurfaceTexture != null) {
                mSurfaceTexture.release();
                mSurfaceTexture = null;
            }

            if (mCachedSurface != null) {
                mCachedSurface.release();
                mCachedSurface = null;
            }
        }
        mTextureValid = false;
        mCachedSurface = null;
        mSurfaceTexture = null;
    }

    public Surface getSurface() {
        return mCachedSurface;
    }

    private static Method getMethod(Class<?> owner, String func, Class<?>[] params) {
        if (owner == null || TextUtils.isEmpty(func)) {
            return null;
        }
        Method method = null;
        try {
            method = owner.getMethod(func, params);
        } catch (Throwable e) {
            try {
                method = owner.getDeclaredMethod(func, params);
            } catch (Throwable t) {
                // ignore
            }
        }
        return method;
    }

}
