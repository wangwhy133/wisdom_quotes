import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error }

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const String _logFileName = 'wisdom_quotes.log';
  static const int _maxAgeDays = 7;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // debug: test file write
      final testPath = await _logFilePath;
      print('[LogService] log file path: $testPath');
      await _purgeOldLogs();
      _initialized = true;
      print('[LogService] initialized, writing first log');
      await _write(LogLevel.info, 'LogService initialized');
      print('[LogService] first log written');
    } catch (e, st) {
      print('[LogService] initialize FAILED: $e\n$st');
    }
  }

  Future<String> get _logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_logFileName';
  }

  Future<void> _write(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final levelStr = level.name.toUpperCase().padRight(7);
      final buf = StringBuffer('$timestamp $levelStr $message');
      if (error != null) {
        buf.write('\n  Error: $error');
      }
      if (stackTrace != null) {
        buf.write('\n  StackTrace: $stackTrace');
      }
      buf.writeln();

      final path = await _logFilePath;
      print('[LogService] writing to: $path');
      final file = File(path);
      await file.writeAsString(buf.toString(), mode: FileMode.append);
      print('[LogService] write success');
    } catch (e, st) {
      print('[LogService] _write FAILED: $e\n$st');
    }
  }

  Future<void> debug(String message) => _write(LogLevel.debug, message);
  Future<void> info(String message) => _write(LogLevel.info, message);
  Future<void> warning(String message) => _write(LogLevel.warning, message);

  Future<void> error(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(LogLevel.error, message, error, stackTrace);

  /// 读取所有日志（最新在前）
  Future<List<String>> getLogs() async {
    try {
      final path = await _logFilePath;
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      return content.split('\n').where((l) => l.trim().isNotEmpty).toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  /// 清理超过7天的日志
  Future<void> _purgeOldLogs() async {
    try {
      final path = await _logFilePath;
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      if (content.isEmpty) return;

      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final cutoff = DateTime.now().subtract(Duration(days: _maxAgeDays));
      final dateFormat = DateFormat('yyyy-MM-dd');

      final filtered = lines.where((line) {
        try {
          final dateStr = line.substring(0, 10);
          final date = dateFormat.parse(dateStr);
          return date.isAfter(cutoff);
        } catch (_) {
          return true;
        }
      }).toList();

      await file.writeAsString('${filtered.join('\n')}\n');
    } catch (_) {}
  }

  /// 导出日志（复制到剪贴板）
  Future<String> exportLogs() async {
    final logs = await getLogs();
    return logs.join('\n');
  }
}
