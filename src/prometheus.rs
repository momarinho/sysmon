use std::collections::HashMap;
use std::fmt::Write;

use crate::models::MetricsSnapshot;

pub struct PrometheusFormatter;

impl PrometheusFormatter {
    pub fn format(snapshot: &MetricsSnapshot) -> String {
        let mut output = String::new();

        Self::write_cpu_metrics(&mut output, snapshot);
        Self::write_memory_metrics(&mut output, snapshot);
        Self::write_disk_metrics(&mut output, snapshot);
        Self::write_network_metrics(&mut output, snapshot);
        Self::write_service_metrics(&mut output, snapshot);

        output
    }

    fn write_cpu_metrics(output: &mut String, snapshot: &MetricsSnapshot) {
        let metrics = [
            (
                "sysmon_cpu_usage_percent",
                "CPU usage percentage (0-100)",
                snapshot.cpu.usage_percent,
            ),
            (
                "sysmon_cpu_cores_total",
                "Number of CPU cores",
                snapshot.cpu.cores as f64,
            ),
        ];

        for (name, help, value) in metrics {
            Self::write_metric(output, name, help, "gauge", value, None);
        }
    }

    fn write_memory_metrics(output: &mut String, snapshot: &MetricsSnapshot) {
        let metrics = [
            (
                "sysmon_memory_total_bytes",
                "Total physical memory in bytes",
                (snapshot.memory.total_kb * 1024) as f64,
            ),
            (
                "sysmon_memory_available_bytes",
                "Available memory in bytes",
                (snapshot.memory.available_kb * 1024) as f64,
            ),
            (
                "sysmon_memory_used_percent",
                "Memory used percentage (0-100)",
                snapshot.memory.used_percent,
            ),
            (
                "sysmon_memory_swap_total_bytes",
                "Total swap in bytes",
                (snapshot.memory.swap_total_kb * 1024) as f64,
            ),
        ];

        for (name, help, value) in metrics {
            Self::write_metric(output, name, help, "gauge", value, None);
        }
    }

    fn write_disk_metrics(output: &mut String, snapshot: &MetricsSnapshot) {
        let disk = &snapshot.disk;

        let metrics = [
            (
                "sysmon_disk_total_bytes",
                "Total disk space in bytes",
                disk.total_bytes as f64,
            ),
            (
                "sysmon_disk_used_bytes",
                "Used disk space in bytes",
                disk.used_bytes as f64,
            ),
            (
                "sysmon_disk_available_bytes",
                "Available disk space in bytes",
                disk.available_bytes as f64,
            ),
            (
                "sysmon_disk_used_percent",
                "Disk usage percentage (0-100)",
                disk.used_percent,
            ),
            (
                "sysmon_disk_read_bytes_per_second",
                "Disk read throughput in bytes per second",
                disk.bytes_read_per_sec,
            ),
            (
                "sysmon_disk_write_bytes_per_second",
                "Disk write throughput in bytes per second",
                disk.bytes_written_per_sec,
            ),
        ];

        for (name, help, value) in metrics {
            Self::write_metric(output, name, help, "gauge", value, None);
        }

        for filesystem in &disk.filesystems {
            let labels = HashMap::from([
                ("device".to_string(), filesystem.device.clone()),
                ("mount_point".to_string(), filesystem.mount_point.clone()),
            ]);

            Self::write_metric(
                output,
                "sysmon_disk_filesystem_total_bytes",
                "Filesystem total space in bytes",
                "gauge",
                filesystem.total_bytes as f64,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_disk_filesystem_used_bytes",
                "Filesystem used space in bytes",
                "gauge",
                filesystem.used_bytes as f64,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_disk_filesystem_used_percent",
                "Filesystem usage percentage (0-100)",
                "gauge",
                filesystem.used_percent,
                Some(&labels),
            );
        }
    }

    fn write_network_metrics(output: &mut String, snapshot: &MetricsSnapshot) {
        let network = &snapshot.network;

        let metrics = [
            (
                "sysmon_network_receive_bytes_per_second",
                "Network receive throughput in bytes per second",
                network.bytes_recv as f64,
            ),
            (
                "sysmon_network_transmit_bytes_per_second",
                "Network transmit throughput in bytes per second",
                network.bytes_sent as f64,
            ),
            (
                "sysmon_network_packets_received_total",
                "Total received packets across all interfaces",
                network.packets_recv as f64,
            ),
            (
                "sysmon_network_packets_sent_total",
                "Total sent packets across all interfaces",
                network.packets_sent as f64,
            ),
            (
                "sysmon_network_errors_in_total",
                "Total incoming network errors across all interfaces",
                network.errors_in as f64,
            ),
            (
                "sysmon_network_errors_out_total",
                "Total outgoing network errors across all interfaces",
                network.errors_out as f64,
            ),
            (
                "sysmon_network_dropped_in_total",
                "Total incoming dropped packets across all interfaces",
                network.dropped_in as f64,
            ),
            (
                "sysmon_network_dropped_out_total",
                "Total outgoing dropped packets across all interfaces",
                network.dropped_out as f64,
            ),
        ];

        for (name, help, value) in metrics {
            Self::write_metric(output, name, help, "gauge", value, None);
        }

        for interface in &network.interfaces {
            let labels = HashMap::from([("interface".to_string(), interface.name.clone())]);

            Self::write_metric(
                output,
                "sysmon_network_interface_receive_bytes_per_second",
                "Per-interface receive throughput in bytes per second",
                "gauge",
                interface.bytes_recv as f64,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_network_interface_transmit_bytes_per_second",
                "Per-interface transmit throughput in bytes per second",
                "gauge",
                interface.bytes_sent as f64,
                Some(&labels),
            );

            let mut status_labels = labels.clone();
            status_labels.insert("status".to_string(), interface.status.clone());

            Self::write_metric(
                output,
                "sysmon_network_interface_status_info",
                "Network interface status information",
                "gauge",
                1.0,
                Some(&status_labels),
            );
        }
    }

    fn write_service_metrics(output: &mut String, snapshot: &MetricsSnapshot) {
        for service in &snapshot.services.services {
            let labels = HashMap::from([("service".to_string(), service.name.clone())]);

            let up_value = if service.status == "running" {
                1.0
            } else {
                0.0
            };

            Self::write_metric(
                output,
                "sysmon_service_up",
                "Service running state (1=running, 0=not running)",
                "gauge",
                up_value,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_service_memory_kb",
                "Service memory usage in kilobytes",
                "gauge",
                service.memory_kb as f64,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_service_cpu_percent",
                "Service CPU usage percentage (0-100)",
                "gauge",
                service.cpu_percent,
                Some(&labels),
            );

            Self::write_metric(
                output,
                "sysmon_service_pid",
                "Service PID or 0 when not running",
                "gauge",
                service.pid as f64,
                Some(&labels),
            );

            let mut status_labels = labels.clone();
            status_labels.insert("status".to_string(), service.status.clone());

            Self::write_metric(
                output,
                "sysmon_service_status_info",
                "Service status information",
                "gauge",
                1.0,
                Some(&status_labels),
            );
        }
    }

    fn write_metric(
        output: &mut String,
        name: &str,
        help: &str,
        metric_type: &str,
        value: f64,
        labels: Option<&HashMap<String, String>>,
    ) {
        let _ = writeln!(output, "# HELP {} {}", name, help);
        let _ = writeln!(output, "# TYPE {} {}", name, metric_type);

        match labels {
            Some(label_map) if !label_map.is_empty() => {
                let labels_str = label_map
                    .iter()
                    .map(|(k, v)| format!(r#"{}="{}""#, k, v))
                    .collect::<Vec<_>>()
                    .join(",");
                let _ = writeln!(output, "{}{{{}}} {}", name, labels_str, value);
            }
            _ => {
                let _ = writeln!(output, "{} {}", name, value);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use chrono::Utc;

    use super::*;
    use crate::models::{
        CpuMetrics, DiskMetrics, FilesystemInfo, InterfaceInfo, MemMetrics, NetMetrics,
        ServiceInfo, ServiceMetrics,
    };

    #[test]
    fn test_formatter() {
        let mut disk = DiskMetrics::new(1_000_000, 400_000);
        disk.bytes_read_per_sec = 120.0;
        disk.bytes_written_per_sec = 80.0;
        disk.add_filesystem(FilesystemInfo {
            mount_point: "/".into(),
            device: "/dev/sda1".into(),
            total_bytes: 1_000_000,
            used_bytes: 400_000,
            used_percent: 40.0,
        });

        let mut network = NetMetrics::new();
        network.bytes_recv = 1024;
        network.bytes_sent = 2048;
        network.packets_recv = 10;
        network.packets_sent = 20;
        network.errors_in = 1;
        network.errors_out = 2;
        network.dropped_in = 3;
        network.dropped_out = 4;
        network.add_interface(InterfaceInfo {
            name: "eth0".into(),
            bytes_recv: 1024,
            bytes_sent: 2048,
            status: "up".into(),
        });

        let mut services = ServiceMetrics::new();
        services.add_service(ServiceInfo {
            name: "postgresql".into(),
            status: "running".into(),
            memory_kb: 8192,
            cpu_percent: 1.5,
            pid: 1234,
        });

        let snapshot = MetricsSnapshot {
            timestamp: Utc::now(),
            cpu: CpuMetrics {
                model_name: "Test CPU".into(),
                usage_percent: 45.5,
                cores: 8,
                per_core: vec![45.5; 8],
            },
            memory: MemMetrics {
                total_kb: 1000,
                free_kb: 300,
                available_kb: 500,
                cached_kb: 100,
                swap_total_kb: 100,
                swap_free_kb: 50,
                buffers_kb: 25,
                used_percent: 50.0,
            },
            disk,
            network,
            services,
        };

        let output = PrometheusFormatter::format(&snapshot);

        assert!(output.contains("sysmon_cpu_usage_percent"));
        assert!(output.contains("# TYPE sysmon_memory_total_bytes gauge"));
        assert!(output.contains("sysmon_disk_total_bytes"));
        assert!(output.contains("sysmon_disk_filesystem_used_percent"));
        assert!(output.contains(r#"device="/dev/sda1""#));
        assert!(output.contains(r#"mount_point="/""#));
        assert!(output.contains("sysmon_network_receive_bytes_per_second"));
        assert!(output.contains("sysmon_network_interface_receive_bytes_per_second"));
        assert!(output.contains(r#"interface="eth0""#));
        assert!(output.contains("sysmon_service_up"));
        assert!(output.contains(r#"service="postgresql""#));
    }
}