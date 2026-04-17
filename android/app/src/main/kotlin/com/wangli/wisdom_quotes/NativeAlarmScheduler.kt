package com.wangli.wisdom_quotes

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class NativeAlarmSchedulerPlugin(private val context: Context) {

    private val alarmManager: AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun configure(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.wangli.wisdom_quotes/alarm_scheduler"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val isDaily = call.argument<Boolean>("isDaily") ?: false
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val channelId = call.argument<String>("channelId") ?: "daily_quote"
                    val channelName = call.argument<String>("channelName") ?: "每日名言"

                    val success = scheduleAlarm(
                        id, triggerAtMillis, title, body,
                        isDaily, hour, minute, channelId, channelName
                    )
                    result.success(success)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarm(id)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm(
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        isDaily: Boolean,
        hour: Int,
        minute: Int,
        channelId: String,
        channelName: String
    ): Boolean {
        return try {
            val intent = Intent(context, AlarmNotificationReceiver::class.java).apply {
                putExtra(AlarmNotificationReceiver.KEY_NOTIFICATION_ID, id)
                putExtra(AlarmNotificationReceiver.KEY_TITLE, title)
                putExtra(AlarmNotificationReceiver.KEY_BODY, body)
                putExtra(AlarmNotificationReceiver.KEY_CHANNEL, channelId)
                putExtra(AlarmNotificationReceiver.KEY_CHANNEL_NAME, channelName)
                if (isDaily) {
                    putExtra(AlarmNotificationReceiver.KEY_IS_DAILY, true)
                    putExtra(AlarmNotificationReceiver.KEY_HOUR, hour)
                    putExtra(AlarmNotificationReceiver.KEY_MINUTE, minute)
                }
            }

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                flags
            )

            // Cancel any existing alarm with same ID first
            alarmManager.cancel(pendingIntent)

            // Use setExactAndAllowWhileIdle for reliable delivery
            // (setAlarmClock shows icon but may not work well when app is in foreground)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("NativeAlarmScheduler", "scheduleAlarm failed: $e")
            false
        }
    }

    private fun cancelAlarm(id: Int) {
        try {
            val intent = Intent(context, AlarmNotificationReceiver::class.java)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (e: Exception) {
            android.util.Log.e("NativeAlarmScheduler", "cancelAlarm failed: $e")
        }
    }
}
