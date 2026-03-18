use std::collections::HashMap;
use std::fmt::Write;

use crate::models::MetricsSnapshot;

pub struct PrometheusFormatter;

impl PrometheusFormatter {
    pub fn format(snapshot: &MetricsSnapshot) -> String {
        let mut output = String::new();

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
            Self::write_metric(&mut output, name, help, "gauge", value, None);
        }

        output
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
    use crate::models::{CpuMetrics, MemMetrics};

    #[test]
    fn test_formatter() {
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
        };

        let output = PrometheusFormatter::format(&snapshot);
        assert!(output.contains("sysmon_cpu_usage_percent"));
        assert!(output.contains("# TYPE sysmon_memory_total_bytes gauge"));
        assert!(output.contains("sysmon_cpu_cores_total 8"));
        assert!(output.contains("sysmon_memory_swap_total_bytes 102400"));
    }
}
