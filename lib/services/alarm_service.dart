import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/database.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle alarm tap
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

    const notificationDetails = NotificationDetails(android: androidDetails);

    String truncatedBody = body;
    if (truncatedBody.length > 200) {
      truncatedBody = '${truncatedBody.substring(0, 200)}...';
    }

    await _notifications.zonedSchedule(
      id,
      '☀️ 今日名言',
      truncatedBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }
}
