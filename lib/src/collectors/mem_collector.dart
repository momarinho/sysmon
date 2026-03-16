import 'dart:io';
import '../logging/logger.dart';
import 'metrics_snapshot.dart';

class MemCollector {
  static final _log = Logger('MemCollector');

  Future<MemMetrics> collect() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      final mem = <String, int>{};

      for (final line in lines) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final key = parts[0].replaceAll(':', '');
          mem[key] = int.tryParse(parts[1]) ?? 0;
        }
      }

      return MemMetrics(
        totalKb: mem['MemTotal'] ?? 0,
        freeKb: mem['MemFree'] ?? 0,
        availableKb: mem['MemAvailable'] ?? 0,
        cachedKb: mem['Cached'] ?? 0,
        swapTotalKb: mem['SwapTotal'] ?? 0,
        swapFreeKb: mem['SwapFree'] ?? 0,
        buffersKb: mem['Buffers'] ?? 0,
      );
    } catch (e) {
      _log.error('Falha ao coletar memória', {'error': e.toString()});
      return MemMetrics(
        totalKb: 0,
        freeKb: 0,
        availableKb: 0,
        cachedKb: 0,
        swapTotalKb: 0,
        swapFreeKb: 0,
        buffersKb: 0,
      );
    }
  }
}
