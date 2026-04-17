import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/database.dart';
import 'log_service.dart';

final _log = LogService()['Notification'];

const _alarmChannel = MethodChannel('com.wangli.wisdom_quotes/alarm_scheduler');

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      _initialized = true;
      _log.info('NotificationService initialized (native alarm)');
    } catch (e, st) {
      _log.error('NotificationService initialize failed', e, st);
      _initialized = true;
    }
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required Quote quote,
  }) async {
    try {
      // Cancel any existing alarm first (native cancel is safe, no SharedPreferences reading)
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': 0});

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      // BUT: if we're testing (scheduling for current time +/- 5min), fire in 5 seconds instead
      final diff = scheduledDate.difference(now).inSeconds;
      if (diff < 5) {
        // Fire in 5 seconds (test scenario)
        scheduledDate = now.add(const Duration(seconds: 5));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      String truncatedContent = quote.content;
      if (truncatedContent.length > 200) {
        truncatedContent = '${truncatedContent.substring(0, 200)}...';
      }

      final body = '$truncatedContent\n— ${quote.author}';

      final result = await _alarmChannel.invokeMethod('scheduleAlarm', {
        'id': 1,  // Use 1 instead of 0 to avoid potential system ID conflicts
        'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
        'title': '今日名言',
        'body': body,
        'isDaily': true,
        'hour': hour,
        'minute': minute,
        'channelId': 'daily_quote_v2',
        'channelName': '每日名言',
      });

      if (result == true) {
        _log.info('每日通知已设置 hour=$hour minute=$minute (native, fire in ${diff < 5 ? 5 : diff}s)');
      } else {
        _log.error('每日通知设置失败: native返回false');
      }
    } catch (e, st) {
      _log.error('每日通知设置失败: $e', e, st);
    }
  }

  Future<void> cancelAll() async {
    try {
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': 1});
      _log.info('每日通知已取消 (native)');
    } catch (e, st) {
      _log.warning('[cancelAll] 调用失败: $e');
    }
  }
}
