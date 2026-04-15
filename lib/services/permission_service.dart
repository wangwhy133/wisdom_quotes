import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// 请求所有必要权限
  static Future<void> requestAllPermissions() async {
    // 通知权限
    await _requestPermission(
      Permission.notification,
      '通知权限',
      '用于每日名言推送和闹钟提醒',
    );

    // 闹钟权限
    await _requestPermission(
      Permission.scheduleExactAlarm,
      '闹钟权限',
      '用于精确的闹钟提醒功能',
    );

    // 存储权限（用于导入导出）
    await _requestPermission(
      Permission.storage,
      '存储权限',
      '用于导入导出名言文件',
    );
  }

  static Future<void> _requestPermission(
    Permission permission,
    String name,
    String description,
  ) async {
    final status = await permission.status;
    
    if (status.isDenied) {
      // 首次请求
      await permission.request();
    } else if (status.isPermanentlyDenied) {
      // 被永久拒绝，跳转到设置
      // 注意：实际应该提供设置引导
    }
  }

  /// 检查权限状态
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.notification: await Permission.notification.status,
      Permission.scheduleExactAlarm: await Permission.scheduleExactAlarm.status,
      Permission.storage: await Permission.storage.status,
    };
  }
}
