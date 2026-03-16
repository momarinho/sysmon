import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../collectors/metrics_snapshot.dart';
import '../logging/logger.dart';

class WebSocketHandler {
  static final _log = Logger('WebSocketHandler');

  final MetricsSnapshot? Function()? _latestSnapshot;
  final _clients = <WebSocket>{};
  StreamSubscription<MetricsSnapshot>? _subscription;

  WebSocketHandler({MetricsSnapshot? Function()? latestSnapshot})
      : _latestSnapshot = latestSnapshot;

  void attach(Stream<MetricsSnapshot> stream) {
    _subscription = stream.listen((snapshot) {
      _broadcast(jsonEncode(snapshot.toJson()));
    });
  }

  Future<void> handleUpgrade(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response
        ..statusCode = HttpStatus.badRequest
        ..write('WebSocket upgrade required')
        ..close();
      return;
    }

    final ws = await WebSocketTransformer.upgrade(req);
    _clients.add(ws);
    _log.info('Client connected', {'clientCount': _clients.length});

    final latest = _latestSnapshot?.call();
    if (latest != null) {
      ws.add(jsonEncode(latest.toJson()));
    }

    ws.done.then((_) {
      _clients.remove(ws);
      _log.info('Client disconnected', {'clientCount': _clients.length});
    });
  }

  void _broadcast(String message) {
    if (_clients.isEmpty) return;

    final dead = <WebSocket>{};
    for (final client in _clients) {
      try {
        client.add(message);
      } catch (_) {
        dead.add(
            client); // Mark clients that failed to receive the message for removal
      }
    }
    _clients.removeAll(dead);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
  }
}
