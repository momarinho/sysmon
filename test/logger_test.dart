import 'dart:convert';

import 'package:sysmon/src/logging/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    test('emits JSON with stable field names', () {
      final lines = <String>[];
      Logger.configure(minimumLevel: LogLevel.debug, sink: lines.add);

      final logger = Logger('TestComponent');
      logger.info('hello', {'request_id': 'req-1'});

      expect(lines, hasLength(1));

      final json = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(json['level'], 'info');
      expect(json['component'], 'TestComponent');
      expect(json['message'], 'hello');
      expect(json['request_id'], 'req-1');
      expect(json['timestamp'], isA<String>());
    });

    test('filters entries below minimum level', () {
      final lines = <String>[];
      Logger.configure(minimumLevel: LogLevel.warn, sink: lines.add);

      final logger = Logger('TestComponent');
      logger.debug('ignore me');
      logger.error('keep me');

      expect(lines, hasLength(1));
      final json = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(json['level'], 'error');
      expect(json['message'], 'keep me');
    });
  });
}
