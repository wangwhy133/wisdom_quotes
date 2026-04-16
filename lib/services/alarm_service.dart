import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/database.dart';
import '../main.dart';
import '../screens/home_screen.dart';
import 'log_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  // Bug 24 fix: named constant instead of magic number
  static const int dailyAlarmId = 999;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
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
      LogService().info('AlarmService initialized');
    } catch (e, st) {
      LogService().error('AlarmService initialize failed', e, st);
      _initialized = true; // prevent repeated attempts
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    LogService().info('AlarmService: notification tapped, id=${response.id}, payload=${response.payload}');
    // Bug 2 fix: navigate to home screen on tap (use MaterialPageRoute since no named routes)
    notificationNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> scheduleAlarm({
    required int id,
    required int hour,
    required int minute,
    required Quote quote,
    String? translatedContent,
  }) async {
    await _notifications.cancel(id);

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

    String body = '"${quote.content}"\n— ${quote.author}';
    if (translatedContent != null && translatedContent.isNotEmpty) {
      body += '\n\n翻译: "$translatedContent"';
    }

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      '闹钟名言',
      channelDescription: '闹钟响起时显示双语名言',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    String truncatedBody = body;
    if (truncatedBody.length > 200) {
      truncatedBody = '${truncatedBody.substring(0, 200)}...';
    }

    try {
      await _notifications.zonedSchedule(
        id,
        '☀️ 今日名言',
        truncatedBody,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      LogService().info('闹钟已设置 id=$id hour=$hour minute=$minute');
    } catch (e, st) {
      LogService().error('闹钟设置失败 id=$id', e, st);
    }
  }

  Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
    LogService().info('闹钟已取消 id=$id');
  }

  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    LogService().info('所有闹钟已取消');
  }
}
