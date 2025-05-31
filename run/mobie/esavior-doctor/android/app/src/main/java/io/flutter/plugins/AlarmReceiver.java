package io.flutter.plugins;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class AlarmReceiver extends BroadcastReceiver {
    private static final String TAG = "AlarmReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "Alarm received: " + intent.getAction());
        // Chuyển tiếp đến ScheduledNotificationReceiver của flutter_local_notifications
        Intent forwardIntent = new Intent(context, com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver.class);
        forwardIntent.putExtras(intent);
        context.sendBroadcast(forwardIntent);
    }
}