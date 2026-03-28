import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class Metrics {
  final double cpu, ram, disk;
  final double ramUsed, ramTotal, diskUsed, diskTotal;
  final String uptime;
  final Map<String, dynamic> temp;

  const Metrics({
    required this.cpu, required this.ram, required this.disk,
    required this.ramUsed, required this.ramTotal,
    required this.diskUsed, required this.diskTotal,
    required this.uptime, required this.temp,
  });

  factory Metrics.fromJson(Map<String, dynamic> j) => Metrics(
    cpu:       (j['cpu']        as num).toDouble(),
    ram:       (j['ram']        as num).toDouble(),
    disk:      (j['disk']       as num).toDouble(),
    ramUsed:   (j['ram_used']   as num).toDouble(),
    ramTotal:  (j['ram_total']  as num).toDouble(),
    diskUsed:  (j['disk_used']  as num).toDouble(),
    diskTotal: (j['disk_total'] as num).toDouble(),
    uptime:    j['uptime'] as String,
    temp:      Map<String, dynamic>.from(j['temp'] as Map? ?? {}),
  );
}

class MetricsService {
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://127.0.0.1:8000/ws/metrics'),
  );

  Stream<Metrics> get stream => _channel.stream.map(
    (raw) => Metrics.fromJson(jsonDecode(raw as String)),
  );

  void dispose() => _channel.sink.close();
}