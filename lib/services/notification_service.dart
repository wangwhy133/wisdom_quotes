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

  /// Schedule a TEST notification that fires after `seconds` seconds
  Future<void> scheduleTestNotification({int seconds = 5}) async {
    try {
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': 2});

      final fireAt = DateTime.now().add(Duration(seconds: seconds));

      final result = await _alarmChannel.invokeMethod('scheduleAlarm', {
        'id': 2,
        'triggerAtMillis': fireAt.millisecondsSinceEpoch,
        'title': '🔔 推送测试',
        'body': '这是一条测试通知，如果看到说明推送正常',
        'isDaily': false,
        'hour': fireAt.hour,
        'minute': fireAt.minute,
        'channelId': 'daily_quote_v2',
        'channelName': '每日名言',
      });

      if (result == true) {
        _log.info('测试通知已设置 fire in ${seconds}s');
      } else {
        _log.error('测试通知设置失败: native返回false');
      }
    } catch (e, st) {
      _log.error('测试通知设置失败: $e', e, st);
    }
  }

  /// Schedule the real daily notification (tomorrow at the specified time)
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required Quote quote,
  }) async {
    try {
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': 1});

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

      String truncatedContent = quote.content;
      if (truncatedContent.length > 200) {
        truncatedContent = '${truncatedContent.substring(0, 200)}...';
      }

      final body = '$truncatedContent\n— ${quote.author}';

      final diff = scheduledDate.difference(now).inSeconds;

      final result = await _alarmChannel.invokeMethod('scheduleAlarm', {
        'id': 1,
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
        _log.info('每日通知已设置 hour=$hour minute=$minute (native, fire in ${diff}s)');
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
