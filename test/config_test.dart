import 'package:sysmon/src/config/config.dart';
import 'package:sysmon/src/logging/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Config.fromEnv', () {
    test('loads validated values from environment', () {
      final config = Config.fromEnv({
        'SYSMON_PORT': '9090',
        'SYSMON_INTERVAL_MS': '1500',
        'SYSMON_SERVICES': 'postgresql, redis',
        'SYSMON_LOG_LEVEL': 'debug',
      });

      expect(config.port, 9090);
      expect(config.intervalMs, 1500);
      expect(config.services, ['postgresql', 'redis']);
      expect(config.logLevel, LogLevel.debug);
    });

    test('uses defaults when values are omitted', () {
      final config = Config.fromEnv({});

      expect(config.port, 8080);
      expect(config.intervalMs, 2000);
      expect(config.services, ['postgresql', 'redis']);
      expect(config.logLevel, LogLevel.info);
    });

    test('rejects invalid port', () {
      expect(
        () => Config.fromEnv({'SYSMON_PORT': '70000'}),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects invalid log level', () {
      expect(
        () => Config.fromEnv({'SYSMON_LOG_LEVEL': 'trace'}),
        throwsA(isA<ConfigException>()),
      );
    });
  });
}
