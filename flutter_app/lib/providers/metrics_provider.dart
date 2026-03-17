import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';

import 'websocket_provider.dart';

final metricsStreamProvider = StreamProvider<MetricsSnapshot>((ref) {
  final wsAsync = ref.watch(webSocketProvider);

  return wsAsync.when(
    data: (ws) {
      return ws.stream.map((event) {
        try {
          final json = jsonDecode(event as String) as Map<String, dynamic>;
          return MetricsSnapshot.fromJson(json);
        } catch (e) {
          print('Error parsing metrics: $e');
          rethrow;
        }
      });
    },
    loading: () => Stream.error('WebSocket connecting...'),
    error: (err, st) => Stream.error(err),
  );
});

final latestMetricsProvider = Provider<AsyncValue<MetricsSnapshot>>((ref) {
  return ref.watch(metricsStreamProvider);
});
