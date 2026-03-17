import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String _defaultWsUrl = String.fromEnvironment(
  'SYSMON_WS_URL',
  defaultValue: 'ws://127.0.0.1:8080/ws',
);

class WebSocketService {
  WebSocketChannel? _channel;

  bool get isConnected => _channel != null;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      // Aguardar a conexão estabelecer
      await _channel!.ready;
    } catch (e) {
      print('WebSocket connection error: $e');
      _channel = null;
      rethrow;
    }
  }

  Stream<dynamic> get stream {
    final channel = _channel;
    if (channel == null) {
      return const Stream.empty();
    }
    return channel.stream;
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
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
      await service.connect(_defaultWsUrl);
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
