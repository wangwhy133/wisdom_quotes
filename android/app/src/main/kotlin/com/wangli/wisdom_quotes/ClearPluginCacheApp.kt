package com.wangli.wisdom_quotes

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.engine.FlutterEngine

/**
 * 在 Flutter 引擎启动前清理 flutter_local_notifications 插件损坏的
 * SharedPreferences 缓存数据，防止 Missing type parameter 崩溃。
 *
 * flutter_local_notifications 18.0.1 的 loadScheduledNotifications()
 * 在读取损坏的 SCHEDULED_NOTIFICATIONS 数据时会抛异常。
 * 这里在应用启动时主动清理该缓存，让插件重建干净的状态。
 */
class ClearPluginCacheApp : Application() {

    override fun onCreate() {
        // 清理 flutter_local_notifications 的损坏缓存
        clearCorruptedNotificationCache(this)

        // 清理 wisdom_quotes 自身保存的通知/闹钟状态（与 flutter_local_notifications 配合的缓存）
        clearLocalNotificationPrefs(this)

        super.onCreate()
    }

    private fun clearCorruptedNotificationCache(context: Context) {
        try {
            // flutter_local_notifications 插件的 SharedPreferences 文件名和 key
            // 插件内部使用: context.getSharedPreferences("flutter_local_notifications", Context.MODE_PRIVATE)
            // 并存储在 "SCHEDULED_NOTIFICATIONS" 这个 key 下
            val prefs = context.getSharedPreferences("flutter_local_notifications", Context.MODE_PRIVATE)
            val corrupted = prefs.getString("SCHEDULED_NOTIFICATIONS", null)
            if (corrupted != null) {
                // 数据存在但已损坏——清空它让插件重建
                prefs.edit().remove("SCHEDULED_NOTIFICATIONS").apply()
                android.util.Log.i("ClearPluginCacheApp", "Cleared corrupted SCHEDULED_NOTIFICATIONS cache")
            }
        } catch (e: Exception) {
            android.util.Log.e("ClearPluginCacheApp", "Failed to clear notification cache: $e")
        }
    }

    private fun clearLocalNotificationPrefs(context: Context) {
        try {
            // 清理应用自身保存的通知/闹钟状态，重置为干净状态
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val keysToClean = listOf(
                "fd_notif_enabled",
                "fd_notif_hour",
                "fd_notif_minute",
                "fd_alarm_enabled",
                "fd_alarm_hour",
                "fd_alarm_minute"
            )
            val editor = prefs.edit()
            for (key in keysToClean) {
                if (prefs.contains(key)) {
                    editor.remove(key)
                }
            }
            editor.apply()
            android.util.Log.i("ClearPluginCacheApp", "Cleared local notification preference cache")
        } catch (e: Exception) {
            android.util.Log.e("ClearPluginCacheApp", "Failed to clear local prefs: $e")
        }
    }
}
