package com.wangli.wisdom_quotes

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmNotificationReceiver : BroadcastReceiver() {

    companion object {
        const val KEY_NOTIFICATION_ID = "notification_id"
        const val KEY_TITLE = "notification_title"
        const val KEY_BODY = "notification_body"
        const val KEY_CHANNEL = "notification_channel"
        const val KEY_CHANNEL_NAME = "notification_channel_name"
        const val KEY_HOUR = "notification_hour"
        const val KEY_MINUTE = "notification_minute"
        const val KEY_IS_DAILY = "is_daily"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.e("AlarmNotificationReceiver", "=== onReceive START ===")

        val id = intent.getIntExtra(KEY_NOTIFICATION_ID, 1)
        val title = intent.getStringExtra(KEY_TITLE) ?: "今日名言"
        val body = intent.getStringExtra(KEY_BODY) ?: ""
        val channelId = intent.getStringExtra(KEY_CHANNEL) ?: "daily_quote_v2"
        val channelName = intent.getStringExtra(KEY_CHANNEL_NAME) ?: "每日名言"
        val isDaily = intent.getBooleanExtra(KEY_IS_DAILY, false)
        val hour = intent.getIntExtra(KEY_HOUR, 8)
        val minute = intent.getIntExtra(KEY_MINUTE, 0)

        Log.e("AlarmNotificationReceiver", "notification id=$id title=$title body_len=${body.length} isDaily=$isDaily")

        // Create notification channel
        createNotificationChannel(context, channelId, channelName)

        // Intent to open app when notification is tapped
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            id + 10000,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(openAppPendingIntent)
            .setFullScreenIntent(openAppPendingIntent, true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(id, notification)
            Log.e("AlarmNotificationReceiver", "notify SUCCESS id=$id")
        } catch (e: SecurityException) {
            Log.e("AlarmNotificationReceiver", "notify FAILED - no permission: $e")
        }

        // Reschedule for next day if this is a daily repeating alarm
        if (isDaily) {
            Log.e("AlarmNotificationReceiver", "Rescheduling for next day $hour:$minute")
            scheduleNextDay(context, id, hour, minute, title, body, channelId, channelName)
        }

        Log.e("AlarmNotificationReceiver", "=== onReceive END ===")
    }

    private fun createNotificationChannel(context: Context, channelId: String, channelName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "名言通知"
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun scheduleNextDay(context: Context, id: Int, hour: Int, minute: Int,
                                title: String, body: String, channelId: String, channelName: String) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(context, AlarmNotificationReceiver::class.java).apply {
                putExtra(KEY_NOTIFICATION_ID, id)
                putExtra(KEY_TITLE, title)
                putExtra(KEY_BODY, body)
                putExtra(KEY_CHANNEL, channelId)
                putExtra(KEY_CHANNEL_NAME, channelName)
                putExtra(KEY_IS_DAILY, true)
                putExtra(KEY_HOUR, hour)
                putExtra(KEY_MINUTE, minute)
            }

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)

            val calendar = java.util.Calendar.getInstance().apply {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
                set(java.util.Calendar.HOUR_OF_DAY, hour)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
            }
        } catch (e: Exception) {
            Log.e("AlarmNotificationReceiver", "scheduleNextDay failed: $e")
        }
    }
}
