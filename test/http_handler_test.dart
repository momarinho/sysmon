import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sysmon/src/config/config.dart';
import 'package:sysmon/src/server/collector_loop.dart';
import 'package:sysmon/src/server/http_handler.dart';
import 'package:sysmon/src/server/websocket_handler.dart';
import 'package:test/test.dart';

void main() {
  group('HttpHandler', () {
    test('GET /health returns liveness payload', () async {
      final config = Config.fromEnv({});
      final loop = CollectorLoop(config: config);
      final ws = WebSocketHandler(latestSnapshot: () => loop.latest);
      final handler = HttpHandler(loop, ws);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serving = () async {
        try {
          await for (final request in server) {
            unawaited(handler.handle(request));
          }
        } catch (_) {
          // The test closes the server explicitly.
        }
      }();

      final client = HttpClient();

      try {
        final request = await client.get(
          InternetAddress.loopbackIPv4.host,
          server.port,
          '/health',
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.ok);
        expect(json['status'], 'ok');
        expect(json['request_id'], startsWith('req-'));
        expect(response.headers.value('x-request-id'), json['request_id']);
      } finally {
        client.close(force: true);
        await server.close(force: true);
        await serving;
        await ws.dispose();
        await loop.stop();
      }
    });
  });
}
