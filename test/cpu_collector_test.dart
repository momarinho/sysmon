import 'package:test/test.dart';
import 'package:sysmon/src/collectors/cpu_collector.dart';

void main() {
  group('CpuCollector', () {
    test('first collection should return 0% usage', () async {
      final collector = CpuCollector();
      final result = await collector.collect();
      expect(result.usagePercent, equals(0.0));
    });

    test('second collection return 0 -> 100', () async {
      final collector = CpuCollector();
      await collector.collect();
      await Future.delayed(Duration(milliseconds: 500));
      final result = await collector.collect();
      expect(result.usagePercent, inInclusiveRange(0.0, 100.0));
    });

    test('second collection reports per-core metrics consistently', () async {
      final collector = CpuCollector();
      await collector.collect();
      await Future.delayed(Duration(milliseconds: 500));
      final result = await collector.collect();

      expect(result.cores, equals(result.perCore.length));
      expect(result.perCore, everyElement(inInclusiveRange(0.0, 100.0)));
    });
  });
}
