use std::fs;

use crate::logging::Logger;
use crate::models::MemMetrics;

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
                mem.insert(
                    parts[0].trim_end_matches(':'),
                    parts[1].parse::<u64>().unwrap_or(0),
                );
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
    use super::MemCollector;

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
}
