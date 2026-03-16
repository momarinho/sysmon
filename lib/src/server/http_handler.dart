import 'dart:convert';
import 'dart:io';

import 'collector_loop.dart';
import 'prometheus_formatter.dart';
import 'websocket_handler.dart';
import '../logging/logger.dart';

class HttpHandler {
  static final _log = Logger('HttpHandler');

  final CollectorLoop _loop;
  final WebSocketHandler _ws;
  final DateTime _startTime = DateTime.now();

  HttpHandler(this._loop, this._ws);

  Future<void> handle(HttpRequest req) async {
    _log.debug('Request', {
      'method': req.method,
      'path': req.uri.path,
      'remote': req.connectionInfo?.remoteAddress.address,
    });

    req.response.headers.set('Access-Control-Allow-Origin', '*');

    switch (req.uri.path) {
      case '/health':
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({
          'status': 'ok',
          'uptime_seconds': DateTime.now().difference(_startTime).inSeconds,
          'version': '0.2.0',
        }));
        await req.response.close();
        return;

      case '/metrics':
        final snapshot = _loop.latest;
        req.response.headers.contentType = ContentType.json;
        if (snapshot == null) {
          req.response
            ..statusCode = HttpStatus.serviceUnavailable
            ..write(jsonEncode({'error': 'collecting, try again'}));
        } else {
          req.response.write(jsonEncode(snapshot.toJson()));
        }
        await req.response.close();
        return;

      case '/metrics/prometheus':
        final snapshot = _loop.latest;
        if (snapshot == null) {
          req.response
            ..statusCode = HttpStatus.serviceUnavailable
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'collecting, try again'}));
        } else {
          req.response.headers.set(
            HttpHeaders.contentTypeHeader,
            'text/plain; version=0.0.4; charset=utf-8',
          );
          req.response.write(PrometheusFormatter.format(snapshot));
        }
        await req.response.close();
        return;

      case '/ws':
        await _ws.handleUpgrade(req);
        return;

      default:
        req.response.headers.contentType = ContentType.json;
        req.response
          ..statusCode = HttpStatus.notFound
          ..write(jsonEncode({'error': 'not found'}));
        await req.response.close();
        return;
    }
  }
}
