import 'dart:io';

import '../logging/logger.dart';

class ConfigException implements Exception {
  final String message;

  const ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}

class Config {
  final int port;
  final int intervalMs;
  final List<String> services;
  final LogLevel logLevel;

  const Config({
    required this.port,
    required this.intervalMs,
    required this.services,
    required this.logLevel,
  });

  factory Config.fromEnv([Map<String, String>? env]) {
    final source = env ?? Platform.environment;

    final port = _parseInt(
      source,
      key: 'SYSMON_PORT',
      fallback: 8080,
      min: 1,
      max: 65535,
    );
    final intervalMs = _parseInt(
      source,
      key: 'SYSMON_INTERVAL_MS',
      fallback: 2000,
      min: 1,
    );
    final services = (source['SYSMON_SERVICES'] ?? 'postgresql,redis')
        .split(',')
        .map((service) => service.trim())
        .where((service) => service.isNotEmpty)
        .toList(growable: false);
    final rawLogLevel = source['SYSMON_LOG_LEVEL'] ?? 'info';
    final logLevel = _parseLogLevel(rawLogLevel);

    if (services.isEmpty) {
      throw const ConfigException(
        'SYSMON_SERVICES must contain at least one service name',
      );
    }

    return Config(
      port: port,
      intervalMs: intervalMs,
      services: services,
      logLevel: logLevel,
    );
  }

  static int _parseInt(
    Map<String, String> env, {
    required String key,
    required int fallback,
    required int min,
    int? max,
  }) {
    final raw = env[key];
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }

    final value = int.tryParse(raw);
    if (value == null) {
      throw ConfigException('$key must be an integer, got "$raw"');
    }
    if (value < min) {
      throw ConfigException('$key must be >= $min, got $value');
    }
    if (max != null && value > max) {
      throw ConfigException('$key must be <= $max, got $value');
    }

    return value;
  }

  static LogLevel _parseLogLevel(String raw) {
    try {
      return LogLevelX.parse(raw);
    } on ArgumentError {
      throw ConfigException(
        'SYSMON_LOG_LEVEL must be one of: '
        '${LogLevel.values.map((level) => level.name).join(', ')}, got "$raw"',
      );
    }
  }
}
