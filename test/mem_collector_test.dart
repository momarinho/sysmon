import 'package:sysmon/src/collectors/mem_collector.dart';
import 'package:test/test.dart';

void main() {
  group('MemCollector', () {
    test('collect returns non-negative memory fields', () async {
      final collector = MemCollector();

      final result = await collector.collect();

      expect(result.totalKb, greaterThanOrEqualTo(0));
      expect(result.freeKb, greaterThanOrEqualTo(0));
      expect(result.availableKb, greaterThanOrEqualTo(0));
      expect(result.cachedKb, greaterThanOrEqualTo(0));
      expect(result.swapTotalKb, greaterThanOrEqualTo(0));
      expect(result.swapFreeKb, greaterThanOrEqualTo(0));
      expect(result.buffersKb, greaterThanOrEqualTo(0));
    });

    test('usedPercent stays within range when total memory is available',
        () async {
      final collector = MemCollector();

      final result = await collector.collect();

      if (result.totalKb == 0) {
        expect(result.usedPercent.isFinite, isFalse);
        return;
      }

      expect(result.availableKb, inInclusiveRange(0, result.totalKb));
      expect(result.usedPercent, inInclusiveRange(0.0, 100.0));
    });
  });
}
