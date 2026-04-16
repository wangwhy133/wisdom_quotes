import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// ============== Log Levels ==============
class Level {
  final String name;
  final int value;
  const Level(this.name, this.value);

  @override String toString() => name;

  static const DEBUG   = Level('DEBUG',   10);
  static const INFO    = Level('INFO',    20);
  static const WARNING = Level('WARNING', 30);
  static const ERROR   = Level('ERROR',   40);
  static const CRITICAL= Level('CRITICAL',50);

  static Level from(int value) {
    if (value <= 10)  return DEBUG;
    if (value <= 20)  return INFO;
    if (value <= 30)  return WARNING;
    if (value <= 40)  return ERROR;
    return CRITICAL;
  }
}

// ============== Log Record ==============
class LogRecord {
  final String loggerName;
  final Level level;
  final String message;
  final DateTime timestamp;
  final String traceId;
  final int? lineNumber;
  final String? source;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic> fields;

  LogRecord({
    required this.loggerName,
    required this.level,
    required this.message,
    required this.timestamp,
    required this.traceId,
    this.lineNumber,
    this.source,
    this.error,
    this.stackTrace,
    Map<String, dynamic>? fields,
  }) : fields = fields ?? {};

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'level': level.name,
    'logger': loggerName,
    'traceId': traceId,
    'msg': message,
    if (lineNumber != null) 'line': lineNumber,
    if (source != null) 'source': source,
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stack': stackTrace.toString(),
    ...fields,
  };

  String toDisplay() {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final buf = StringBuffer('${fmt.format(timestamp)} ${level.name.padRight(8)} [${loggerName}] $message');
    if (traceId.isNotEmpty && traceId != 'root') {
      buf.write(' traceId=$traceId');
    }
    if (error != null) {
      buf.write('\n  error: $error');
    }
    if (stackTrace != null) {
      buf.write('\n  stack: $stackTrace');
    }
    return buf.toString();
  }
}

// ============== Handler ==============
abstract class Handler {
  void emit(LogRecord record);
  void flush();
}

class FileHandler extends Handler {
  final String path;
  IOSink? _sink;
  File? _file;

  FileHandler(this.path);

  Future<void> _ensureOpen() async {
    if (_sink != null) return;
    _file = File(path);
    _sink = _file!.openWrite(mode: FileMode.append);
  }

  @override
  void emit(LogRecord record) {
    // ignore errors silently to prevent loops
  }

  Future<void> emitAsync(LogRecord record) async {
    try {
      await _ensureOpen();
      _sink!.writeln(jsonEncode(record.toJson()));
      _sink!.flush();
    } catch (_) {}
  }

  @override
  void flush() {
    try { _sink?.flush(); } catch (_) {}
  }

  Future<void> close() async {
    try { await _sink?.flush(); await _sink?.close(); } catch (_) {}
    _sink = null;
  }
}

class MemoryHandler extends Handler {
  final List<LogRecord> records = [];
  final int maxRecords;

  MemoryHandler({this.maxRecords = 1000});

  @override
  void emit(LogRecord record) {
    records.add(record);
    if (records.length > maxRecords) {
      records.removeAt(0);
    }
  }

  @override
  void flush() {}

  void clear() => records.clear();

  List<String> getDisplayLogs({Level? minLevel}) {
    final filtered = minLevel != null
        ? records.where((r) => r.level.value >= minLevel.value).toList()
        : records;
    return filtered.map((r) => r.toDisplay()).toList().reversed.toList();
  }

  String exportJson() {
    return records.map((r) => jsonEncode(r.toJson())).join('\n');
  }
}

// ============== Logger ==============
class Logger {
  final String name;
  Level _level;
  final List<Handler> _handlers = [];

  Logger(this.name, {Level level = Level.DEBUG}) : _level = level;

  bool get _isRoot => name.isEmpty;

  void addHandler(Handler h) => _handlers.add(h);

  void setLevel(Level level) => _level = level;

  void _log(Level level, String msg, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
    int? lineNumber,
    String? source,
  }) {
    if (level.value < _level.value) return;

    final traceId = _currentTraceId();

    final record = LogRecord(
      loggerName: _isRoot ? 'root' : name,
      level: level,
      message: msg,
      timestamp: DateTime.now(),
      traceId: traceId,
      lineNumber: lineNumber,
      source: source,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );

    for (final h in _handlers) {
      if (h is MemoryHandler) {
        h.emit(record);
      } else if (h is FileHandler) {
        h.emitAsync(record);
      }
    }
  }

  void debug(String msg, {Map<String, dynamic>? fields}) =>
      _log(Level.DEBUG, msg, fields: fields);

  void info(String msg, {Map<String, dynamic>? fields}) =>
      _log(Level.INFO, msg, fields: fields);

  void warning(String msg, {Map<String, dynamic>? fields}) =>
      _log(Level.WARNING, msg, fields: fields);

  void error(String msg, [Object? error, StackTrace? stackTrace]) =>
      _log(Level.ERROR, msg, error: error, stackTrace: stackTrace);

  void critical(String msg, [Object? error, StackTrace? stackTrace]) =>
      _log(Level.CRITICAL, msg, error: error, stackTrace: stackTrace);
}

// ============== Global Log Service ==============
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const String _logFileName = 'wisdom_quotesStructured.log';
  static const int _maxAgeDays = 7;

  late Logger _rootLogger;
  late FileHandler _fileHandler;
  late MemoryHandler _memoryHandler;
  bool _initialized = false;

  // Pre-created loggers per module
  final Map<String, Logger> _loggers = {};

  Logger get root => _rootLogger;

  Logger operator [](String name) {
    if (!_initialized) return _rootLogger;
    return _loggers.putIfAbsent(name, () => Logger(name));
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _rootLogger = Logger('');
    _memoryHandler = MemoryHandler(maxRecords: 2000);
    _rootLogger.addHandler(_memoryHandler);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final logPath = '${dir.path}/$_logFileName';
      _fileHandler = FileHandler(logPath);
      _rootLogger.addHandler(_fileHandler);
    } catch (_) {}

    _initialized = true;

    // Purge old logs
    _rootLogger.info('LogService initialized', fields: {'version': '1.0'});
    _purgeOldLogsAsync();
  }

  Future<void> _purgeOldLogsAsync() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logPath = '${dir.path}/$_logFileName';
      final file = File(logPath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.isEmpty) return;

      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final cutoff = DateTime.now().subtract(const Duration(days: _maxAgeDays));
      final dateFmt = DateFormat('yyyy-MM-dd');

      final filtered = lines.where((line) {
        try {
          final rec = jsonDecode(line) as Map<String, dynamic>;
          final ts = DateTime.parse(rec['ts'] as String);
          return ts.isAfter(cutoff);
        } catch (_) {
          return true;
        }
      }).toList();

      await file.writeAsString('${filtered.join('\n')}\n');
    } catch (_) {}
  }

  List<String> getLogs({Level? minLevel}) {
    return _memoryHandler.getDisplayLogs(minLevel: minLevel);
  }

  String exportLogs() {
    return _memoryHandler.exportJson();
  }

  Future<void> flush() async {
    _memoryHandler.flush();
    _fileHandler.flush();
  }
}

// ============== Trace ID helpers (Zone-based) ==============
String _currentTraceId() {
  try {
    final zone = Zone.current;
    final traceId = zone[#traceId];
    return traceId?.toString() ?? '';
  } catch (_) {
    return '';
  }
}

/// 运行一个代码块并注入 traceId
R runWithTrace<R>(String traceId, R Function() block) {
  return runZoned(block, zoneValues: {#traceId: traceId});
}

/// 生成一个简短 UUID
String generateTraceId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final rand = now.hashCode ^ (DateTime.now().microsecond);
  return '${now.toRadixString(16)}-${rand.toRadixString(16)}';
}
