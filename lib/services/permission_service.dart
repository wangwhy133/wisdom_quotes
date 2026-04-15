import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all required permissions and check result.
  /// Returns true only if all critical permissions are granted.
  static Future<bool> requestAllPermissions() async {
    // Notification permission (critical for both alarm and daily notification)
    final notifStatus = await Permission.notification.request();

    // Exact alarm permission (critical for alarm)
    final alarmStatus = await Permission.scheduleExactAlarm.request();

    // Storage permission (for import/export)
    final storageStatus = await Permission.storage.request();

    return notifStatus.isGranted || alarmStatus.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if exact alarm permission is granted
  static Future<bool> hasExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  /// Show settings dialog when permission is permanently denied
  static Future<void> showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('权限不足'),
        content: const Text(
          '通知/闹钟权限被拒绝，请在系统设置中开启，否则相关功能将无法使用。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// Check all permissions and return their status
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.notification: await Permission.notification.status,
      Permission.scheduleExactAlarm: await Permission.scheduleExactAlarm.status,
      Permission.storage: await Permission.storage.status,
    };
  }
}
