use std::collections::HashMap;
use std::fs;
use std::time::Instant;

use crate::models::NetMetrics;

#[derive(Clone, Debug)]
struct NetworkSnapshot {
    timestamp: Instant,
    interfaces: HashMap<String, InterfaceStats>,
}

#[derive(Clone, Debug)]
struct InterfaceStats {
    bytes_recv: u64,
    packets_recv: u64,
    bytes_sent: u64,
    packets_sent: u64,
}

// PUBLIC STRUCT
pub struct NetCollector {
    prev_snapshot: Option<NetworkSnapshot>,
}

// IMPLEMENTATION
impl NetCollector {
    pub fn new() -> Self {
        Self {
            prev_snapshot: None,
        }
    }

    pub fn collect(&mut self) -> NetMetrics {
        let net_dev = match fs::read_to_string("/proc/net/dev") {
            Ok(content) => content,
            Err(_) => return NetMetrics::new(),
        };

        let mut current_interfaces = HashMap::new();

        for line in net_dev.lines().skip(2) {
            if let Some((iface_name, stats)) = parse_net_dev_line(line) {
                if is_relevant_interface(&iface_name) {
                    current_interfaces.insert(iface_name, stats);
                }
            }
        }

        let current_snapshot = NetworkSnapshot {
            timestamp: Instant::now(),
            interfaces: current_interfaces,
        };

        let (bytes_recv_per_sec, bytes_sent_per_sec) = if let Some(prev) = &self.prev_snapshot {
            calculate_rates(&prev, &current_snapshot)
        } else {
            (0.0, 0.0)
        };

        self.prev_snapshot = Some(current_snapshot);

        let mut metrics = NetMetrics::new();
        metrics.bytes_recv = (bytes_recv_per_sec * 1.0) as u64;
        metrics.bytes_sent = (bytes_sent_per_sec * 1.0) as u64;

        metrics
    }
}

fn parse_net_dev_line(line: &str) -> Option<(String, InterfaceStats)> {
    if !line.contains(':') {
        return None;
    }

    let parts: Vec<&str> = line.split(':').collect();
    if parts.len() != 2 {
        return None;
    }

    let iface_name = parts[0].trim().to_string();
    let fields: Vec<&str> = parts[1].split_whitespace().collect();

    if fields.len() < 16 {
        return None;
    }

    let bytes_recv = fields[0].parse::<u64>().ok()?;
    let packets_recv = fields[1].parse::<u64>().ok()?;
    let bytes_sent = fields[8].parse::<u64>().ok()?;
    let packets_sent = fields[9].parse::<u64>().ok()?;

    Some((
        iface_name,
        InterfaceStats {
            bytes_recv,
            packets_recv,
            bytes_sent,
            packets_sent,
        },
    ))
}

fn is_relevant_interface(iface_name: &str) -> bool {
    if iface_name == "lo" {
        return false;
    }

    if iface_name.starts_with("docker") || iface_name.starts_with("veth") {
        return false;
    }

    true
}

fn calculate_rates(prev: &NetworkSnapshot, current: &NetworkSnapshot) -> (f64, f64) {
    let mut total_bytes_recv_per_sec = 0.0;
    let mut total_bytes_sent_per_sec = 0.0;

    for (iface_name, current_stats) in &current.interfaces {
        if let Some(prev_stats) = prev.interfaces.get(iface_name) {
            let time_diff = current
                .timestamp
                .duration_since(prev.timestamp)
                .as_secs_f64();
            if time_diff > 0.0 {
                let bytes_recv_diff = current_stats
                    .bytes_recv
                    .saturating_sub(prev_stats.bytes_recv);
                let bytes_sent_diff = current_stats
                    .bytes_sent
                    .saturating_sub(prev_stats.bytes_sent);

                total_bytes_recv_per_sec += bytes_recv_diff as f64 / time_diff;
                total_bytes_sent_per_sec += bytes_sent_diff as f64 / time_diff;
            }
        }
    }

    (total_bytes_recv_per_sec, total_bytes_sent_per_sec)
}

// TESTS
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_line_basic() {
        let line = "  eth0: 1234567  12345    0    0    0     0          0         0  9876543  98765    0    0    0     0       0          0";
        let result = parse_net_dev_line(line);

        assert!(result.is_some());
        let (iface_name, stats) = result.unwrap();
        assert_eq!(iface_name, "eth0");
        assert_eq!(stats.bytes_recv, 1234567);
        assert_eq!(stats.bytes_sent, 9876543);
    }

    #[test]
    fn test_parse_line_loopback() {
        let line = "    lo: 1234567  12345    0    0    0     0          0         0  1234567  12345    0    0    0     0       0          0";
        let result = parse_net_dev_line(line);

        assert!(result.is_some());
        let (iface, _) = result.unwrap();
        assert_eq!(iface, "lo");
    }

    #[test]
    fn test_filter_accepts_eth0() {
        assert!(is_relevant_interface("eth0"));
    }

    #[test]
    fn test_filter_accepts_wlan0() {
        assert!(is_relevant_interface("wlan0"));
    }

    #[test]
    fn test_filter_rejects_loopback() {
        assert!(!is_relevant_interface("lo"));
    }

    #[test]
    fn test_filter_rejects_docker() {
        assert!(!is_relevant_interface("docker0"));
    }

    #[test]
    fn test_filter_rejects_veth() {
        assert!(!is_relevant_interface("veth123abc"));
    }

    #[test]
    fn test_first_collect_returns_zero_rates() {
        let mut collector = NetCollector::new();
        let metrics = collector.collect();

        assert_eq!(metrics.bytes_recv, 0);
        assert_eq!(metrics.bytes_sent, 0);
    }
}