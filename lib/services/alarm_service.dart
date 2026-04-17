import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database.dart';
import '../screens/home_screen.dart';
import 'log_service.dart';

final _log = LogService()['Alarm'];

const _alarmChannel = MethodChannel('com.wangli.wisdom_quotes/alarm_scheduler');

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const int dailyAlarmId = 999;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _initialized = true;
      _log.info('AlarmService initialized');
    } catch (e, st) {
      _log.error('AlarmService initialize failed', e, st);
      _initialized = true;
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required int hour,
    required int minute,
    required Quote quote,
    String? translatedContent,
  }) async {
    try {
      // Cancel any existing alarm first (native cancel is safe)
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': id});

      final now = DateTime.now();
      var scheduledDate = DateTime(
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

      String truncatedBody = body;
      if (truncatedBody.length > 200) {
        truncatedBody = '${truncatedBody.substring(0, 200)}...';
      }

      // isDaily=true → receiver will auto-reschedule for next day
      final result = await _alarmChannel.invokeMethod('scheduleAlarm', {
        'id': id,
        'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
        'title': '☀️ 今日名言',
        'body': truncatedBody,
        'scheduleMode': 'exactAllowWhileIdle',
        'isDaily': true,
        'hour': hour,
        'minute': minute,
        'channelId': 'alarm_channel',
        'channelName': '闹钟名言',
      });

      if (result == true) {
        _log.info('闹钟已设置 id=$id hour=$hour minute=$minute (native)');
      } else {
        _log.error('闹钟设置失败 id=$id: native返回false');
      }
    } catch (e, st) {
      _log.error('闹钟设置失败 id=$id', e, st);
    }
  }

  Future<void> cancelAlarm(int id) async {
    try {
      await _alarmChannel.invokeMethod('cancelAlarm', {'id': id});
      _log.info('闹钟已取消 id=$id (native)');
    } catch (e, st) {
      _log.warning('[cancelAlarm id=$id] 调用失败: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    try {
      await _alarmChannel.invokeMethod('cancelAllAlarms');
      _log.info('所有闹钟已取消 (native)');
    } catch (e, st) {
      _log.warning('[cancelAllAlarms] 调用失败: $e');
    }
  }
}
