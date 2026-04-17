package com.wangli.wisdom_quotes

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
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

        fun scheduleNextDay(context: Context, id: Int, hour: Int, minute: Int,
                            title: String, body: String, channelId: String, channelName: String) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

                val intent = Intent(context, AlarmNotificationReceiver::class.java).apply {
                    putExtra(KEY_NOTIFICATION_ID, id)
                    putExtra(KEY_TITLE, title)
                    putExtra(KEY_BODY, body)
                    putExtra(KEY_CHANNEL, channelId)
                    putExtra(KEY_CHANNEL_NAME, channelName)
                    putExtra(KEY_HOUR, hour)
                    putExtra(KEY_MINUTE, minute)
                    putExtra(KEY_IS_DAILY, true)
                }

                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)

                // Calculate next trigger time (tomorrow at hour:minute)
                val calendar = java.util.Calendar.getInstance().apply {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                    set(java.util.Calendar.HOUR_OF_DAY, hour)
                    set(java.util.Calendar.MINUTE, minute)
                    set(java.util.Calendar.SECOND, 0)
                    set(java.util.Calendar.MILLISECOND, 0)
                }

                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(calendar.timeInMillis, pendingIntent),
                    pendingIntent
                )
            } catch (e: Exception) {
                android.util.Log.e("AlarmNotificationReceiver", "scheduleNextDay failed: $e")
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(KEY_NOTIFICATION_ID, 1)
        val title = intent.getStringExtra(KEY_TITLE) ?: "今日名言"
        val body = intent.getStringExtra(KEY_BODY) ?: ""
        val channelId = intent.getStringExtra(KEY_CHANNEL) ?: "daily_quote"
        val channelName = intent.getStringExtra(KEY_CHANNEL_NAME) ?: "每日名言"
        val isDaily = intent.getBooleanExtra(KEY_IS_DAILY, false)
        val hour = intent.getIntExtra(KEY_HOUR, 8)
        val minute = intent.getIntExtra(KEY_MINUTE, 0)

        // Show the notification
        createNotificationChannel(context, channelId, channelName)

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
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(openAppPendingIntent)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (e: SecurityException) {
            android.util.Log.e("AlarmNotificationReceiver", "No notification permission: $e")
        }

        // Reschedule for next day if this is a daily repeating alarm
        if (isDaily) {
            scheduleNextDay(context, id, hour, minute, title, body, channelId, channelName)
        }
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
            }
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
