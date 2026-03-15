import 'dart:convert';
import 'dart:io';

enum LogLevel {
  debug,
  info,
  warn,
  error,
}

class Logger {
  final String _context;

  const Logger(this._context);

  void debug(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.debug, msg, extra);
  void info(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.info, msg, extra);
  void warn(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.warn, msg, extra);
  void error(String msg, [Map<String, dynamic>? extra]) =>
      _log(LogLevel.error, msg, extra);

  void _log(LogLevel level, String msg, Map<String, dynamic>? extra) {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'context': _context,
      'msg': msg,
      if (extra != null) ...extra,
    };
    // Write the log entry as a JSON string to stdout.
    stdout.writeln(jsonEncode(entry));
  }
}
