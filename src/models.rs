use chrono::{DateTime, Utc};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct CpuMetrics {
    pub usage_percent: f64,
    pub cores: usize,
    pub per_core: Vec<f64>,
}

#[derive(Debug, Clone, Serialize)]
pub struct MemMetrics {
    pub total_kb: u64,
    pub free_kb: u64,
    pub available_kb: u64,
    pub cached_kb: u64,
    pub swap_total_kb: u64,
    pub swap_free_kb: u64,
    pub buffers_kb: u64,
    pub used_percent: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct MetricsSnapshot {
    pub timestamp: DateTime<Utc>,
    pub cpu: CpuMetrics,
    pub memory: MemMetrics,
}

impl MemMetrics {
    pub fn new(
        total_kb: u64,
        free_kb: u64,
        available_kb: u64,
        cached_kb: u64,
        swap_total_kb: u64,
        swap_free_kb: u64,
        buffers_kb: u64,
    ) -> Self {
        let used_percent = if total_kb == 0 {
            0.0
        } else {
            round_one_decimal(((total_kb - available_kb) as f64 / total_kb as f64) * 100.0)
        };

        Self {
            total_kb,
            free_kb,
            available_kb,
            cached_kb,
            swap_total_kb,
            swap_free_kb,
            buffers_kb,
            used_percent,
        }
    }
}

pub fn round_one_decimal(value: f64) -> f64 {
    (value * 10.0).round() / 10.0
}

