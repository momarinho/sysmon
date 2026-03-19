class CpuMetrics {
  final String modelName;
  final double usagePercent;
  final int cores;
  final List<double> perCore;

  const CpuMetrics({
    required this.modelName,
    required this.usagePercent,
    required this.cores,
    required this.perCore,
  });

  factory CpuMetrics.fromJson(Map<String, dynamic> json) {
    return CpuMetrics(
      modelName: (json['model_name'] as String?) ?? 'Unknown CPU',
      usagePercent: (json['usage_percent'] as num).toDouble(),
      cores: json['cores'] as int,
      perCore: List<double>.from(
        (json['per_core'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }
}

class MemMetrics {
  final int totalKb;
  final int freeKb;
  final int availableKb;
  final int cachedKb;
  final int swapTotalKb;
  final int swapFreeKb;
  final int buffersKb;

  const MemMetrics({
    required this.totalKb,
    required this.freeKb,
    required this.availableKb,
    required this.cachedKb,
    required this.swapTotalKb,
    required this.swapFreeKb,
    required this.buffersKb,
  });

  double get usedPercent {
    if (totalKb == 0) return 0;
    return ((totalKb - availableKb) / totalKb * 100);
  }

  factory MemMetrics.fromJson(Map<String, dynamic> json) {
    return MemMetrics(
      totalKb: json['total_kb'] as int,
      freeKb: json['free_kb'] as int,
      availableKb: json['available_kb'] as int,
      cachedKb: json['cached_kb'] as int,
      swapTotalKb: json['swap_total_kb'] as int,
      swapFreeKb: json['swap_free_kb'] as int,
      buffersKb: json['buffers_kb'] as int,
    );
  }
}

class DiskMetrics {
  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  final double usedPercent;
  final List<FilesystemInfo> filesystems;
  final double bytesReadPerSec;
  final double bytesWrittenPerSec;

  const DiskMetrics({
    required this.totalBytes,
    required this.usedBytes,
    required this.availableBytes,
    required this.usedPercent,
    required this.filesystems,
    required this.bytesReadPerSec,
    required this.bytesWrittenPerSec,
  });

  factory DiskMetrics.fromJson(Map<String, dynamic> json) {
    return DiskMetrics(
      totalBytes: json['total_bytes'] as int,
      usedBytes: json['used_bytes'] as int,
      availableBytes: json['available_bytes'] as int,
      usedPercent: (json['used_percent'] as num).toDouble(),
      filesystems: List<FilesystemInfo>.from(
        (json['filesystems'] as List<dynamic>).map(
          (entry) => FilesystemInfo.fromJson(entry as Map<String, dynamic>),
        ),
      ),
      bytesReadPerSec: (json['bytes_read_per_sec'] as num).toDouble(),
      bytesWrittenPerSec: (json['bytes_written_per_sec'] as num).toDouble(),
    );
  }
}

class FilesystemInfo {
  final String mountPoint;
  final String device;
  final int totalBytes;
  final int usedBytes;
  final double usedPercent;

  const FilesystemInfo({
    required this.mountPoint,
    required this.device,
    required this.totalBytes,
    required this.usedBytes,
    required this.usedPercent,
  });

  factory FilesystemInfo.fromJson(Map<String, dynamic> json) {
    return FilesystemInfo(
      mountPoint: json['mount_point'] as String,
      device: json['device'] as String,
      totalBytes: json['total_bytes'] as int,
      usedBytes: json['used_bytes'] as int,
      usedPercent: (json['used_percent'] as num).toDouble(),
    );
  }
}

class NetworkMetrics {
  final int bytesRecv;
  final int bytesSent;
  final int packetsRecv;
  final int packetsSent;
  final int errorsIn;
  final int errorsOut;
  final int droppedIn;
  final int droppedOut;
  final List<NetworkInterfaceInfo> interfaces;

  const NetworkMetrics({
    required this.bytesRecv,
    required this.bytesSent,
    required this.packetsRecv,
    required this.packetsSent,
    required this.errorsIn,
    required this.errorsOut,
    required this.droppedIn,
    required this.droppedOut,
    required this.interfaces,
  });

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      bytesRecv: json['bytes_recv'] as int,
      bytesSent: json['bytes_sent'] as int,
      packetsRecv: json['packets_recv'] as int,
      packetsSent: json['packets_sent'] as int,
      errorsIn: json['errors_in'] as int,
      errorsOut: json['errors_out'] as int,
      droppedIn: json['dropped_in'] as int,
      droppedOut: json['dropped_out'] as int,
      interfaces: List<NetworkInterfaceInfo>.from(
        (json['interfaces'] as List<dynamic>).map(
          (entry) =>
              NetworkInterfaceInfo.fromJson(entry as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class NetworkInterfaceInfo {
  final String name;
  final int bytesRecv;
  final int bytesSent;
  final String status;

  const NetworkInterfaceInfo({
    required this.name,
    required this.bytesRecv,
    required this.bytesSent,
    required this.status,
  });

  factory NetworkInterfaceInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInterfaceInfo(
      name: json['name'] as String,
      bytesRecv: json['bytes_recv'] as int,
      bytesSent: json['bytes_sent'] as int,
      status: json['status'] as String,
    );
  }
}

class ServiceMetrics {
  final List<ServiceInfo> services;

  const ServiceMetrics({required this.services});

  factory ServiceMetrics.fromJson(Map<String, dynamic> json) {
    return ServiceMetrics(
      services: List<ServiceInfo>.from(
        (json['services'] as List<dynamic>).map(
          (entry) => ServiceInfo.fromJson(entry as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class ServiceInfo {
  final String name;
  final String status;
  final int memoryKb;
  final double cpuPercent;
  final int pid;

  const ServiceInfo({
    required this.name,
    required this.status,
    required this.memoryKb,
    required this.cpuPercent,
    required this.pid,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      name: json['name'] as String,
      status: json['status'] as String,
      memoryKb: json['memory_kb'] as int,
      cpuPercent: (json['cpu_percent'] as num).toDouble(),
      pid: json['pid'] as int,
    );
  }
}

class MetricsSnapshot {
  final DateTime timestamp;
  final CpuMetrics cpu;
  final MemMetrics memory;
  final DiskMetrics disk;
  final NetworkMetrics network;
  final ServiceMetrics services;

  const MetricsSnapshot({
    required this.timestamp,
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.network,
    required this.services,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) {
    return MetricsSnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      cpu: CpuMetrics.fromJson(json['cpu'] as Map<String, dynamic>),
      memory: MemMetrics.fromJson(json['memory'] as Map<String, dynamic>),
      disk: DiskMetrics.fromJson(json['disk'] as Map<String, dynamic>),
      network: NetworkMetrics.fromJson(json['network'] as Map<String, dynamic>),
      services:
          ServiceMetrics.fromJson(json['services'] as Map<String, dynamic>),
    );
  }
}
