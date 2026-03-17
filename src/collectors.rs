use std::fs;

use crate::logging::Logger;
use crate::models::{CpuMetrics, MemMetrics, round_one_decimal};

#[derive(Default)]
pub struct CpuCollector {
    prev_total: Option<Vec<u64>>,
    prev_idle: Option<Vec<u64>>,
}

impl CpuCollector {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn collect(&mut self) -> CpuMetrics {
        match fs::read_to_string("/proc/stat") {
            Ok(content) => self.parse(&content),
            Err(error) => {
                Logger::new("CpuCollector").error(
                    "Failed to collect CPU metrics",
                    serde_json::json!({ "error": error.to_string() }),
                );
                CpuMetrics {
                    usage_percent: 0.0,
                    cores: 0,
                    per_core: Vec::new(),
                }
            }
        }
    }

    fn parse(&mut self, content: &str) -> CpuMetrics {
        let cpu_lines = content
            .lines()
            .filter(|line| line.starts_with("cpu"))
            .collect::<Vec<_>>();

        let mut totals = Vec::with_capacity(cpu_lines.len());
        let mut idles = Vec::with_capacity(cpu_lines.len());

        for line in cpu_lines {
            let values = line
                .split_whitespace()
                .skip(1)
                .map(|value| value.parse::<u64>().unwrap_or(0))
                .collect::<Vec<_>>();

            let total = values.iter().sum::<u64>();
            let idle = values.get(3).copied().unwrap_or(0) + values.get(4).copied().unwrap_or(0);
            totals.push(total);
            idles.push(idle);
        }

        let mut overall_usage = 0.0;
        let mut per_core = Vec::new();

        if let (Some(prev_total), Some(prev_idle)) = (&self.prev_total, &self.prev_idle) {
            for index in 0..totals.len() {
                let delta_total = totals[index].saturating_sub(prev_total[index]);
                let delta_idle = idles[index].saturating_sub(prev_idle[index]);
                let usage = if delta_total > 0 {
                    (1.0 - (delta_idle as f64 / delta_total as f64)) * 100.0
                } else {
                    0.0
                };

                if index == 0 {
                    overall_usage = round_one_decimal(usage);
                } else {
                    per_core.push(round_one_decimal(usage));
                }
            }
        }

        self.prev_total = Some(totals);
        self.prev_idle = Some(idles);

        CpuMetrics {
            usage_percent: overall_usage,
            cores: per_core.len(),
            per_core,
        }
    }
}

pub struct MemCollector;

impl MemCollector {
    pub fn new() -> Self {
        Self
    }

    pub fn collect(&self) -> MemMetrics {
        match fs::read_to_string("/proc/meminfo") {
            Ok(content) => self.parse(&content),
            Err(error) => {
                Logger::new("MemCollector").error(
                    "Failed to collect memory metrics",
                    serde_json::json!({ "error": error.to_string() }),
                );
                MemMetrics::new(0, 0, 0, 0, 0, 0, 0)
            }
        }
    }

    fn parse(&self, content: &str) -> MemMetrics {
        let mut mem = std::collections::HashMap::<&str, u64>::new();

        for line in content.lines() {
            let parts = line.split_whitespace().collect::<Vec<_>>();
            if parts.len() >= 2 {
                mem.insert(parts[0].trim_end_matches(':'), parts[1].parse::<u64>().unwrap_or(0));
            }
        }

        MemMetrics::new(
            *mem.get("MemTotal").unwrap_or(&0),
            *mem.get("MemFree").unwrap_or(&0),
            *mem.get("MemAvailable").unwrap_or(&0),
            *mem.get("Cached").unwrap_or(&0),
            *mem.get("SwapTotal").unwrap_or(&0),
            *mem.get("SwapFree").unwrap_or(&0),
            *mem.get("Buffers").unwrap_or(&0),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::{CpuCollector, MemCollector};

    #[test]
    fn mem_parser_maps_fields() {
        let collector = MemCollector::new();
        let metrics = collector.parse(
            "MemTotal: 1000 kB\nMemFree: 300 kB\nMemAvailable: 400 kB\nCached: 100 kB\nSwapTotal: 200 kB\nSwapFree: 150 kB\nBuffers: 50 kB\n",
        );

        assert_eq!(metrics.total_kb, 1000);
        assert_eq!(metrics.available_kb, 400);
        assert_eq!(metrics.used_percent, 60.0);
    }

    #[test]
    fn cpu_parser_uses_deltas() {
        let mut collector = CpuCollector::new();
        let first = "cpu  10 0 10 80 0 0 0 0\ncpu0 5 0 5 40 0 0 0 0\ncpu1 5 0 5 40 0 0 0 0\n";
        let second = "cpu  20 0 20 100 0 0 0 0\ncpu0 10 0 10 50 0 0 0 0\ncpu1 10 0 10 50 0 0 0 0\n";

        let cold = collector.parse(first);
        let hot = collector.parse(second);

        assert_eq!(cold.usage_percent, 0.0);
        assert_eq!(hot.usage_percent, 50.0);
        assert_eq!(hot.cores, 2);
        assert_eq!(hot.per_core, vec![50.0, 50.0]);
    }
}
