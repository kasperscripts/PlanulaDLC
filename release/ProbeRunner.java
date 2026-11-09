package com.iconcrack.probe;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.widget.EditText;
import android.widget.TextView;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

public final class ProbeRunner extends Instrumentation {
    public void onCreate(Bundle args) { super.onCreate(args); start(); }
    private void require(boolean ok, String message) {
        if (!ok) throw new AssertionError(message);
    }
    private boolean ok(Object result) throws Exception {
        return result.getClass().getField("ok").getBoolean(result);
    }
    private void heartbeat() throws Exception {
        final CountDownLatch done=new CountDownLatch(1);
        new Handler(Looper.getMainLooper()).post(new Runnable(){public void run(){done.countDown();}});
        require(done.await(3,TimeUnit.SECONDS),"Main thread stopped responding during screen startup");
    }
    private void ui(final Activity activity, final String text, final boolean enabled) throws Exception {
        final CountDownLatch done=new CountDownLatch(1);
        final AtomicReference<Throwable> error=new AtomicReference<>();
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            public void run() {
                try {
                    Field input=activity.getClass().getDeclaredField("input"); input.setAccessible(true);
                    Field button=activity.getClass().getDeclaredField("button"); button.setAccessible(true);
                    EditText field=(EditText)input.get(activity);
                    if (text != null) field.setText(text);
                    require(((TextView)button.get(activity)).isClickable()==enabled,"Unexpected activation clickability for "+text);
                } catch (Throwable t) { error.set(t); }
                finally { done.countDown(); }
            }
        });
        require(done.await(3,TimeUnit.SECONDS),"UI thread did not respond within 3 seconds");
        if(error.get()!=null) throw new AssertionError(error.get());
    }
    public void onStart() {
        Bundle result=new Bundle();
        try {
            Context context=getTargetContext();
            ClassLoader loader=context.getClassLoader();
            Class<?> gate=Class.forName("androidx.tyuuws.hnxoq.GateActivity",true,loader);
            Class<?> api=Class.forName("androidx.tyuuws.hnxoq.Loader",true,loader);
            Method check=api.getMethod("check",String.class);
            Method complete=gate.getDeclaredMethod("keyComplete",String.class); complete.setAccessible(true);
            String[] invalid={null,"","wrong","icon_crack","@ICON_CRACK"," @icon_crack","@icon_crack ","@icon_crack\n","@icon_crackx"};
            for(String value:invalid) {
                require(!ok(check.invoke(null,new Object[]{value})),"Invalid key accepted: "+value);
                require(!((Boolean)complete.invoke(null,new Object[]{value})),"Invalid key enabled UI: "+value);
            }
            require(ok(check.invoke(null,"@icon_crack")),"Fixed key rejected");
            require((Boolean)complete.invoke(null,"@icon_crack"),"Fixed key did not enable UI");
            context.getSharedPreferences("ldr",0).edit().putString("k","old-any-key").commit();
            require("".equals(api.getMethod("savedKey").invoke(null)),"Old arbitrary key was retained");
            context.getSharedPreferences("ldr",0).edit().clear().commit();
            context.getSharedPreferences("hnxoq_gate",0).edit().putBoolean("storage_asked",true).commit();
            long before=SystemClock.uptimeMillis();
            final Intent intent=new Intent();
            intent.setClassName(context.getPackageName(),"androidx.tyuuws.hnxoq.GateActivity");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            final AtomicReference<Activity> launched=new AtomicReference<>();
            final AtomicReference<Throwable> launchError=new AtomicReference<>();
            new Thread(new Runnable(){public void run(){
                try{launched.set(startActivitySync(intent));}catch(Throwable t){launchError.set(t);}
            }},"screen-start-probe").start();
            while(launched.get()==null && launchError.get()==null && SystemClock.uptimeMillis()-before<30000){
                heartbeat();SystemClock.sleep(250);
            }
            if(launchError.get()!=null)throw new AssertionError(launchError.get());
            Activity activity=launched.get();
            require(activity!=null,"Activation screen did not open within 30 seconds");
            long launchTime=SystemClock.uptimeMillis()-before;
            ui(activity,"wrong",false);
            ui(activity,"@ICON_CRACK",false);
            ui(activity,"@icon_crack",true);
            for(int i=0;i<15;i++){ui(activity,null,true);SystemClock.sleep(1000);}
            android.graphics.Bitmap screenshot=getUiAutomation().takeScreenshot();
            if(screenshot!=null) {
                java.io.File image=new java.io.File(context.getFilesDir(),"fixed-key-screen.png");
                java.io.FileOutputStream stream=new java.io.FileOutputStream(image);
                screenshot.compress(android.graphics.Bitmap.CompressFormat.PNG,100,stream);
                stream.close();screenshot.recycle();
            }
            result.putString("stream","PASS: only @icon_crack accepted; arbitrary cached key removed; activation UI responsive for 15 seconds; launch="+launchTime+"ms\n");
            finish(Activity.RESULT_OK,result);
        } catch(Throwable t) {
            result.putString("stream","FAIL: "+android.util.Log.getStackTraceString(t));
            finish(Activity.RESULT_CANCELED,result);
        }
    }
}
