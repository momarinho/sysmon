import 'dart:io';

class Config {
  // The path to the configuration file.
  static int get port =>
      int.parse(Platform.environment['SYSMON_PORT'] ?? '8080');

  // Interval in miliseconds to check for updates
  static int get intervalMs =>
      int.parse(Platform.environment['SYSMON INTERVAL_MS'] ?? '2000');

  // Services to monitor via systemctl
  static List<String> get services =>
      (Platform.environment['SYSMON_SERVICES'] ?? 'postgresql,redis')
          .split(',')
          .map((s) => s.trim())
          .toList();

  // Log level for the application (e.g., 'info', 'debug', 'error')
  static String get logLevel =>
      Platform.environment['SYSMON_LOG_LEVEL'] ?? 'info';
}
