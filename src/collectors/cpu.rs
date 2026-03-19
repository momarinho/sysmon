use std::fs;

use crate::logging::Logger;
use crate::models::{CpuMetrics, round_one_decimal};

#[derive(Default)]
pub struct CpuCollector {
    model_name: String,
    prev_total: Option<Vec<u64>>,
    prev_idle: Option<Vec<u64>>,
}

impl CpuCollector {
    pub fn new() -> Self {
        Self {
            model_name: Self::read_model_name(),
            ..Self::default()
        }
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
                    model_name: self.model_name.clone(),
                    usage_percent: 0.0,
                    cores: 0,
                    per_core: Vec::new(),
                }
            }
        }
    }

    fn read_model_name() -> String {
        fs::read_to_string("/proc/cpuinfo")
            .ok()
            .and_then(|content| Self::parse_model_name(&content))
            .unwrap_or_else(|| "Unknown CPU".to_owned())
    }

    fn parse_model_name(content: &str) -> Option<String> {
        content.lines().find_map(|line| {
            let (key, value) = line.split_once(':')?;
            if key.trim() == "model name" {
                let model = value.trim();
                if model.is_empty() {
                    None
                } else {
                    Some(model.to_owned())
                }
            } else {
                None
            }
        })
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
            model_name: self.model_name.clone(),
            usage_percent: overall_usage,
            cores: per_core.len(),
            per_core,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::CpuCollector;

    #[test]
    fn cpu_parser_uses_deltas() {
        let mut collector = CpuCollector::new();
        collector.model_name = "Test CPU".into();
        let first = "cpu  10 0 10 80 0 0 0 0\ncpu0 5 0 5 40 0 0 0 0\ncpu1 5 0 5 40 0 0 0 0\n";
        let second = "cpu  20 0 20 100 0 0 0 0\ncpu0 10 0 10 50 0 0 0 0\ncpu1 10 0 10 50 0 0 0 0\n";

        let cold = collector.parse(first);
        let hot = collector.parse(second);

        assert_eq!(hot.model_name, "Test CPU");
        assert_eq!(cold.usage_percent, 0.0);
        assert_eq!(hot.usage_percent, 50.0);
        assert_eq!(hot.cores, 2);
        assert_eq!(hot.per_core, vec![50.0, 50.0]);
    }

    #[test]
    fn cpu_model_name_parser_reads_first_model_name() {
        let content = "processor : 0\nmodel name : AMD Ryzen 7 7840HS\ncpu MHz : 3800.000\n";

        let model_name = CpuCollector::parse_model_name(content);

        assert_eq!(model_name.as_deref(), Some("AMD Ryzen 7 7840HS"));
    }
}
