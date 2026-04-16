import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// ============== Levels ==============
enum _LogLevel { debug, info, warning, error }

// ============== Structured LogRecord ==============
class _StructuredRecord {
  final DateTime ts;
  final _LogLevel level;
  final String loggerName;
  final String message;
  final String traceId;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic> fields;

  _StructuredRecord({
    required this.ts,
    required this.level,
    required this.loggerName,
    required this.message,
    required this.traceId,
    this.error,
    this.stackTrace,
    this.fields = const {},
  });

  String get _levelStr {
    switch (level) {
      case _LogLevel.debug:   return 'DEBUG   ';
      case _LogLevel.info:    return 'INFO    ';
      case _LogLevel.warning: return 'WARNING ';
      case _LogLevel.error:   return 'ERROR   ';
    }
  }

  Map<String, dynamic> toJson() => {
    'ts': ts.toIso8601String(),
    'level': level.name.toUpperCase(),
    'logger': loggerName,
    'traceId': traceId,
    'msg': message,
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stack': stackTrace.toString().split('\n').take(5).join('\n'),
    if (fields.isNotEmpty) ...fields,
  };

  String toDisplay() {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final buf = StringBuffer('${fmt.format(ts)} ${_levelStr} [$loggerName] $message');
    if (traceId.isNotEmpty) buf.write(' tid=$traceId');
    if (error != null) buf.write('\n  err: $error');
    if (stackTrace != null) {
      final frames = stackTrace.toString().split('\n').take(3).join('\n  ');
      buf.write('\n  st: $frames');
    }
    return buf.toString();
  }
}

// ============== Handlers ==============
class _MemoryHandler {
  final List<_StructuredRecord> _records = [];
  final int maxRecords;

  _MemoryHandler({this.maxRecords = 3000});

  void emit(_StructuredRecord r) {
    _records.add(r);
    if (_records.length > maxRecords) _records.removeAt(0);
  }

  List<String> getDisplayLogs({_LogLevel? minLevel}) {
    final minVal = minLevel?.index ?? 0;
    return _records
        .where((r) => r.level.index >= minVal)
        .map((r) => r.toDisplay())
        .toList()
        .reversed
        .toList();
  }

  String exportJson() => _records.map((r) => jsonEncode(r.toJson())).join('\n');
  void clear() => _records.clear();
}

class _FileHandler {
  final String path;
  IOSink? _sink;
  File? _file;
  final String? _crashPath; // crash-safe synchronous error log

  _FileHandler(this.path, [this._crashPath]);

  Future<void> _ensureOpen() async {
    if (_sink != null) return;
    try {
      _file = File(path);
      _sink = _file!.openWrite(mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> writeAsync(_StructuredRecord r) async {
    try {
      await _ensureOpen();
      _sink!.writeln(jsonEncode(r.toJson()));
    } catch (_) {}
    // Also write errors synchronously to crash-safe file
    if (r.level.index >= _LogLevel.error.index && _crashPath != null) {
      _syncWriteCrash(r);
    }
  }

  void _syncWriteCrash(_StructuredRecord r) {
    try {
      final f = File(_crashPath!);
      f.writeAsStringSync('${jsonEncode(r.toJson())}\n', mode: FileMode.append);
    } catch (_) {}
  }

  void flush() { try { _sink?.flush(); } catch (_) {} }
  Future<void> close() async {
    try { await _sink?.flush(); await _sink?.close(); } catch (_) {}
    _sink = null;
  }
}

// ============== Logger ==============
class _Logger {
  final String name;
  _LogLevel _minLevel;
  final _MemoryHandler _mem;
  final _FileHandler? _file;
  final List<Future<void> Function(_StructuredRecord)> _asyncHandlers = [];

  _Logger(this.name, this._mem, this._file, [this._minLevel = _LogLevel.debug]);

  void _log(_LogLevel level, String msg, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? fields}) {
    if (level.index < _minLevel.index) return;
    final traceId = _getTraceId();
    final record = _StructuredRecord(
      ts: DateTime.now(),
      level: level,
      loggerName: name,
      message: msg,
      traceId: traceId,
      error: error,
      stackTrace: stackTrace,
      fields: fields ?? {},
    );
    _mem.emit(record);
    if (_file != null) {
      _file!.writeAsync(record);
    }
    for (final h in _asyncHandlers) {
      h(record);
    }
  }

  void debug(String msg, [Map<String, dynamic>? fields]) => _log(_LogLevel.debug, msg, fields: fields);
  void info(String msg, [Map<String, dynamic>? fields])  => _log(_LogLevel.info, msg, fields: fields);
  void warning(String msg, [Map<String, dynamic>? fields]) => _log(_LogLevel.warning, msg, fields: fields);
  void error(String msg, [Object? e, StackTrace? st, Map<String, dynamic>? fields]) =>
      _log(_LogLevel.error, msg, error: e, stackTrace: st, fields: fields);
}

// ============== Backward-compatible LogService ==============
typedef StructuredLogger = _Logger;

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const String _logFileName = 'wisdom_quotesStructured.log';
  static const int _maxAgeDays = 7;

  late _MemoryHandler _memHandler;
  late _FileHandler _fileHandler;
  bool _initialized = false;

  // Named loggers per module
  final Map<String, _Logger> _loggers = {};

  // 通用日志（无模块名）
  late _Logger _root;

  // 快捷访问：LogService()['QuoteGenerator'].info(...)
  _Logger operator [](String name) {
    final mem = _initialized ? _memHandler : _fallbackMem;
    final file = _initialized ? _fileHandler : _fallbackFile;
    return _loggers.putIfAbsent(name, () => _Logger(name, mem, file));
  }

  static final _fallbackMem = _MemoryHandler();
  static _FileHandler? _fallbackFile; // not used but declared

  // 全局快捷方法（兼容旧代码）
  void debug(String msg) => (_initialized ? _root : _noopLogger).debug(msg);
  void info(String msg)  => (_initialized ? _root : _noopLogger).info(msg);
  void warning(String msg) => (_initialized ? _root : _noopLogger).warning(msg);
  void error(String msg, [Object? e, StackTrace? st]) =>
      (_initialized ? _root : _noopLogger).error(msg, e, st);

  // Noop logger for use before initialization
  static final _noopLogger = _Logger('noop', _MemoryHandler(), null);

  Future<void> initialize() async {
    if (_initialized) return;

    _memHandler = _MemoryHandler(maxRecords: 3000);

    String? filePath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      filePath = '${dir.path}/$_logFileName';
      _fileHandler = _FileHandler(filePath, '${filePath}.crash');
    } catch (_) {
      _fileHandler = _FileHandler('/dev/null');
    }

    _root = _Logger('app', _memHandler, _fileHandler);
    _initialized = true;

    _root.info('LogService initialized');
    _purgeOldLogs(filePath);
  }

  void _purgeOldLogs(String? filePath) async {
    if (filePath == null) return;
    try {
      final file = File(filePath);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      if (content.isEmpty) return;

      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final cutoff = DateTime.now().subtract(const Duration(days: _maxAgeDays));

      final filtered = <String>[];
      for (final line in lines) {
        try {
          final rec = jsonDecode(line) as Map<String, dynamic>;
          final ts = DateTime.parse(rec['ts'] as String);
          if (ts.isAfter(cutoff)) filtered.add(line);
        } catch (_) {
          filtered.add(line);
        }
      }

      await file.writeAsString('${filtered.join('\n')}\n');
    } catch (_) {}
  }

  List<String> getLogs() => _memHandler.getDisplayLogs();
  String exportLogs() => _memHandler.exportJson();
}

// ============== Trace utilities ==============
String _getTraceId() {
  try {
    final zone = Zone.current;
    final id = zone[#_traceId];
    return id?.toString() ?? '';
  } catch (_) { return ''; }
}

R runWithTrace<R>(String traceId, R Function() block) {
  return runZoned(block, zoneValues: {#_traceId: traceId});
}

String generateTraceId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return '${now.toRadixString(16)}-${now.hashCode.toRadixString(16)}';
}
