import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;

  bool get isConnected => _channel != null;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      // Aguardar a conexão estabelecer
      await _channel.ready;
    } catch (e) {
      print('WebSocket connection error: $e');
      rethrow;
    }
  }

  Stream<dynamic> get stream => _channel.stream;

  void disconnect() {
    _channel.sink.close();
  }
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, AsyncValue<WebSocketService>>(
        (ref) {
  return WebSocketNotifier();
});

class WebSocketNotifier extends StateNotifier<AsyncValue<WebSocketService>> {
  WebSocketNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final service = WebSocketService();
      await service.connect('ws://localhost:8080/ws');
      state = AsyncValue.data(service);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reconnect() async {
    state = const AsyncValue.loading();
    await _init();
  }
}
