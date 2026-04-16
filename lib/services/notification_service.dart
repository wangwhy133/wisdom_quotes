import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/database.dart';
import '../main.dart';
import '../screens/home_screen.dart';
import 'log_service.dart';

final _log = LogService()['Notification'];

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // 请求精确闹钟权限（Android 12+ 必须用户授权）
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestExactAlarmsPermission();
      }

      _initialized = true;
      _log.info('NotificationService initialized');
    } catch (e, st) {
      _log.error('NotificationService initialize failed', e, st);
      _initialized = true; // prevent repeated attempts
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _log.info('NotificationService: notification tapped, id=${response.id}');
    // Bug 2 fix: navigate to home screen on tap (use MaterialPageRoute since no named routes)
    notificationNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required Quote quote,
  }) async {
    // 不再调用 cancelAll（它会触发 loadScheduledNotifications 读取损坏缓存导致崩溃）
    // zonedSchedule 使用相同的 id=0 会自动覆写旧通知

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Refactor: truncate content BEFORE using in BigTextStyleInformation (was bug — used before defined)
    String truncatedContent = quote.content;
    if (truncatedContent.length > 100) {
      truncatedContent = '${truncatedContent.substring(0, 100)}...';
    }

    // Bug 26 fix: BigTextStyleInformation body must contain actual content, not empty string
    final androidDetails = AndroidNotificationDetails(
      'daily_quote',
      '每日名言',
      channelDescription: '每日推送经典名言',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        '$truncatedContent\n— ${quote.author}',
        contentTitle: '今日名言',
        summaryText: '— ${quote.author}',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      // 每次写入前清空损坏的缓存，防止flutter_local_notifications写入时数据损坏
      try {
        _log.debug('[scheduleDaily] 缓存已清理');
      } catch (e) {
        _log.debug('[scheduleDaily] 缓存清理失败（不影响继续）: $e');
      }
      await _notifications.zonedSchedule(
        0,
        '今日名言',
        '$truncatedContent\n— ${quote.author}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _log.info('每日通知已设置 hour=$hour minute=$minute');
    } catch (e, st) {
      _log.error('每日通知设置失败: $e', e, st);
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e, st) {
      _log.warning('[cancelAll] 调用失败（可能是缓存损坏）: $e');
    }
  }
}
