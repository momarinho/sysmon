import 'dart:async';
import 'dart:io';

import 'package:sysmon/src/config/config.dart';
import 'package:sysmon/src/logging/logger.dart';
import 'package:sysmon/src/server/http_handler.dart';
import 'package:sysmon/src/server/collector_loop.dart';
import 'package:sysmon/src/server/websocket_handler.dart';

final _log = Logger('Main');

Future<void> main() async {
  final loop = CollectorLoop();
  final ws = WebSocketHandler(latestSnapshot: () => loop.latest);
  final handler = HttpHandler(loop, ws);
  var shuttingDown = false;

  loop.start();

  ws.attach(loop.stream);

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    Config.port,
  );

  Future<void> shutdown() async {
    if (shuttingDown) {
      return;
    }

    shuttingDown = true;
    _log.info('SIGINT received, shutting down...');
    await server.close(force: true);
    await ws.dispose();
    await loop.stop();
  }

  final sigintSub = ProcessSignal.sigint.watch().listen((_) {
    unawaited(shutdown());
  });

  _log.info('Server started', {
    'port': Config.port,
    'endpoints': ['/health', '/metrics', '/metrics/prometheus', '/ws'],
  });

  try {
    await for (final req in server) {
      unawaited(
        handler.handle(req).catchError((Object error, StackTrace stackTrace) {
          _log.error('Failed to process request', {
            'error': error.toString(),
          });
        }),
      );
    }
  } finally {
    await sigintSub.cancel();
    await shutdown();
  }
}
