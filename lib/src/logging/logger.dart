import 'dart:convert';
import 'dart:io';

enum LogLevel {
  debug,
  info,
  warn,
  error,
}

extension LogLevelX on LogLevel {
  static LogLevel parse(String value) {
    final normalized = value.trim().toLowerCase();

    for (final level in LogLevel.values) {
      if (level.name == normalized) {
        return level;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'must be one of: ${LogLevel.values.map((level) => level.name).join(', ')}',
    );
  }
}

class Logger {
  static LogLevel _minimumLevel = LogLevel.info;
  static void Function(String line) _sink = stdout.writeln;

  final String _context;
  final void Function(String line)? _overrideSink;

  const Logger(this._context, {void Function(String line)? sink})
      : _overrideSink = sink;

  static void configure({
    required LogLevel minimumLevel,
    void Function(String line)? sink,
  }) {
    _minimumLevel = minimumLevel;
    if (sink != null) {
      _sink = sink;
    }
  }

  void debug(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.debug, msg, extra);
  void info(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.info, msg, extra);
  void warn(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.warn, msg, extra);
  void error(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.error, msg, extra);

  void _log(LogLevel level, String msg, Map<String, dynamic>? extra) {
    if (level.index < _minimumLevel.index) {
      return;
    }

    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'component': _context,
      'message': msg,
      if (extra != null) ...extra,
    };

    final sink = _overrideSink ?? _sink;
    sink(jsonEncode(entry));
  }
}
