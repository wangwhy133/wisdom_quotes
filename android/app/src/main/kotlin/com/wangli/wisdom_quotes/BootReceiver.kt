package com.wangli.wisdom_quotes

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {

            rescheduleNotifications(context)
        }
    }

    private fun rescheduleNotifications(context: Context) {
        try {
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )

            // Reschedule daily notification
            val notifEnabled = prefs.getBoolean("fd_notif_enabled", false)
            if (notifEnabled) {
                val hour = prefs.getInt("fd_notif_hour", 8)
                val minute = prefs.getInt("fd_notif_minute", 0)
                rescheduleDailyNotification(context, hour, minute)
            }

            // Reschedule alarm
            val alarmEnabled = prefs.getBoolean("fd_alarm_enabled", false)
            if (alarmEnabled) {
                val hour = prefs.getInt("fd_alarm_hour", 7)
                val minute = prefs.getInt("fd_alarm_minute", 0)
                // Alarm needs content, so we can't fully reschedule from here without the quote data
                // Just log it - the app will reschedule on next launch
            }
        } catch (e: Exception) {
            android.util.Log.e("BootReceiver", "rescheduleNotifications failed: $e")
        }
    }

    private fun rescheduleDailyNotification(context: Context, hour: Int, minute: Int) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(context, AlarmNotificationReceiver::class.java).apply {
                putExtra(AlarmNotificationReceiver.KEY_NOTIFICATION_ID, 0)
                putExtra(AlarmNotificationReceiver.KEY_TITLE, "今日名言")
                putExtra(AlarmNotificationReceiver.KEY_BODY, "正在加载...")
                putExtra(AlarmNotificationReceiver.KEY_CHANNEL, "daily_quote")
                putExtra(AlarmNotificationReceiver.KEY_CHANNEL_NAME, "每日名言")
                putExtra(AlarmNotificationReceiver.KEY_IS_DAILY, true)
                putExtra(AlarmNotificationReceiver.KEY_HOUR, hour)
                putExtra(AlarmNotificationReceiver.KEY_MINUTE, minute)
            }

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(context, 1, intent, flags)

            // Calculate next trigger time
            val calendar = java.util.Calendar.getInstance().apply {
                if (get(java.util.Calendar.HOUR_OF_DAY) > hour ||
                    (get(java.util.Calendar.HOUR_OF_DAY) == hour && get(java.util.Calendar.MINUTE) > minute)) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
                set(java.util.Calendar.HOUR_OF_DAY, hour)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }

            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(calendar.timeInMillis, pendingIntent),
                pendingIntent
            )
            android.util.Log.i("BootReceiver", "Daily notification rescheduled for $hour:$minute")
        } catch (e: Exception) {
            android.util.Log.e("BootReceiver", "rescheduleDailyNotification failed: $e")
        }
    }
}
