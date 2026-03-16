import 'dart:convert';
import 'dart:io';

import 'package:sysmon/src/config/config.dart';
import 'package:sysmon/src/logging/logger.dart';
import 'package:sysmon/src/collectors/cpu_collector.dart';
import 'package:sysmon/src/collectors/mem_collector.dart';

final _log = Logger('Server');
final _cpu = CpuCollector();
final _mem = MemCollector();

void main() async {
  _log.info('Starting sysmon', {
    'port': Config.port,
    'interval_ms': Config.intervalMs,
  });

  final server = await HttpServer.bind('localhost', Config.port);
  _log.info('Server listening', {'port': Config.port});

  await for (final req in server) {
    await _handleRequest(req);
  }
}

Future<void> _handleRequest(HttpRequest req) async {
  req.response.headers.set('Access--Control-Allow-Origin', '*');
  req.response.headers.contentType = ContentType.json;

  switch (req.uri.path) {
    case '/health':
      req.response
        ..statusCode = 200
        ..write(jsonEncode({'status': 'ok'}));

    case '/metrics':
      final cpu = await _cpu.collect();
      final mem = await _mem.collect();
      req.response.write(jsonEncode({
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'cpu': cpu.toJson(),
        'memory': mem.toJson(),
      }));
    default:
      req.response
        ..statusCode = 404
        ..write(jsonEncode({'error': 'Not found'}));
  }
  await req.response.close();
}
