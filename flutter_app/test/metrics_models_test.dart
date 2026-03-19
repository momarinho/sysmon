import 'package:flutter_test/flutter_test.dart';
import 'package:sysmon_dashboard/models/metrics_models.dart';

void main() {
  test('parses snapshot with disk, network and services payloads', () {
    final snapshot = MetricsSnapshot.fromJson({
      'timestamp': '2026-03-19T12:00:00Z',
      'cpu': {
        'model_name': 'Test CPU',
        'usage_percent': 42.5,
        'cores': 8,
        'per_core': [40.0, 41.0],
      },
      'memory': {
        'total_kb': 1000,
        'free_kb': 200,
        'available_kb': 600,
        'cached_kb': 100,
        'swap_total_kb': 300,
        'swap_free_kb': 200,
        'buffers_kb': 50,
      },
      'disk': {
        'total_bytes': 1000,
        'used_bytes': 400,
        'available_bytes': 600,
        'used_percent': 40.0,
        'filesystems': [
          {
            'mount_point': '/',
            'device': '/dev/sda1',
            'total_bytes': 1000,
            'used_bytes': 400,
            'used_percent': 40.0,
          },
        ],
        'bytes_read_per_sec': 12.5,
        'bytes_written_per_sec': 8.5,
      },
      'network': {
        'bytes_recv': 1024,
        'bytes_sent': 2048,
        'packets_recv': 10,
        'packets_sent': 20,
        'errors_in': 1,
        'errors_out': 2,
        'dropped_in': 3,
        'dropped_out': 4,
        'interfaces': [
          {
            'name': 'eth0',
            'bytes_recv': 1024,
            'bytes_sent': 2048,
            'status': 'up',
          },
        ],
      },
      'services': {
        'services': [
          {
            'name': 'postgresql',
            'status': 'running',
            'memory_kb': 8192,
            'cpu_percent': 1.5,
            'pid': 1234,
          },
        ],
      },
    });

    expect(snapshot.disk.bytesReadPerSec, 12.5);
    expect(snapshot.network.interfaces.single.name, 'eth0');
    expect(snapshot.services.services.single.status, 'running');
  });
}
