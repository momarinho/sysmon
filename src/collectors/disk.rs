use std::collections::HashMap;
use std::fs;
use std::time::Instant;

use crate::models::DiskMetrics;

// INTERN STRUCTS
#[derive(Clone, Debug)]
struct DiskSnapshot {
    timestamp: Instant,
    devices: HashMap<String, DeviceStats>,
}

#[derive(Clone, Debug)]
struct DeviceStats {
    sectors_read: u64,
    sectors_written: u64,
    reads_completed: u64,
    writes_completed: u64,
}

// PUBLIC STRUCT
pub struct DiskCollector {
    prev_snapshot: Option<DiskSnapshot>,
}

// IMPLEMENTATION
impl DiskCollector {
    pub fn new() -> Self {
        Self {
            prev_snapshot: None,
        }
    }

    pub fn collect(&mut self) -> DiskMetrics {
        // PASSO 1: Ler arquivo
        let diskstats = match fs::read_to_string("/proc/diskstats") {
            Ok(content) => content,
            Err(_) => {
                // Se falhar (arquivo vazio, sem permissão, etc)
                return DiskMetrics::new(0, 0);
            }
        };

        let mut current_devices = HashMap::new();

        for line in diskstats.lines() {
            if let Some((device_name, major, stats)) = parse_diskstats_line(line) {
                if is_relevant_device(&device_name, major) {
                    current_devices.insert(device_name, stats);
                }
            }
        }

        let current_snapshot = DiskSnapshot {
            timestamp: Instant::now(),
            devices: current_devices,
        };

        let (bytes_read_per_sec, bytes_written_per_sec) = if let Some(prev) = &self.prev_snapshot {
            calculate_rates(&prev, &current_snapshot)
        } else {
            (0.0, 0.0)
        };

        self.prev_snapshot = Some(current_snapshot);

        DiskMetrics {
            total_bytes: 0,
            used_bytes: 0,
            available_bytes: 0,
            used_percent: 0.0,
            filesystems: vec![],
            bytes_read_per_sec,
            bytes_written_per_sec,
        }
    }
}

// AUXILIAR FUNCTIONS
fn parse_diskstats_line(line: &str) -> Option<(String, u32, DeviceStats)> {
    let fields: Vec<&str> = line.split_whitespace().collect();

    if fields.len() < 14 {
        return None;
    }

    let major = fields[0].parse::<u32>().ok()?;
    let device_name = fields[2].to_string();

    let reads_completed = fields[3].parse::<u64>().ok()?;
    let sectors_read = fields[5].parse::<u64>().ok()?;
    let writes_completed = fields[7].parse::<u64>().ok()?;
    let sectors_written = fields[9].parse::<u64>().ok()?;

    let stats = DeviceStats {
        sectors_read,
        sectors_written,
        reads_completed,
        writes_completed,
    };

    Some((device_name, major, stats))
}

fn is_relevant_device(device_name: &str, major: u32) -> bool {
    // Aceitar SCSI (8) e NVMe (259)
    if major != 8 && major != 259 {
        return false;
    }

    // Rejeitar partições SCSI: sda1, sdb2, etc (últimos chars são números)
    if major == 8 && device_name.chars().last().map_or(false, |c| c.is_numeric()) {
        return false;
    }

    // Rejeitar partições NVMe: nvme0n1p1, etc (contém 'p' seguido de números)
    if major == 259 {
        if let Some(p_index) = device_name.rfind('p') {
            if device_name[p_index + 1..].chars().all(|c| c.is_numeric()) {
                return false;
            }
        }
    }

    // Rejeitar pseudo-dispositivos
    if device_name.starts_with("loop")
        || device_name.starts_with("zram")
        || device_name.starts_with("dm-")
        || device_name.starts_with("md")
    {
        return false;
    }

    true
}

fn calculate_rates(prev: &DiskSnapshot, current: &DiskSnapshot) -> (f64, f64) {
    let elapsed_secs = (current.timestamp - prev.timestamp).as_secs_f64();

    if elapsed_secs == 0.0 {
        return (0.0, 0.0);
    }

    let mut total_bytes_read = 0.0;
    let mut total_bytes_written = 0.0;

    for (device_name, current_stats) in &current.devices {
        if let Some(prev_stats) = prev.devices.get(device_name) {
            let delta_sectors_read = current_stats
                .sectors_read
                .saturating_sub(prev_stats.sectors_read);
            let delta_sectors_written = current_stats.sectors_written.saturating_sub(prev_stats.sectors_written);

            total_bytes_read += (delta_sectors_read as f64 * 512.0) / elapsed_secs;
            total_bytes_written += (delta_sectors_written as f64 * 512.0) / elapsed_secs;
        }
    }

    (total_bytes_read, total_bytes_written)
}

// TESTS
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_line_basic() {
        let line = "259 0 nvme0n1 1000 0 2000 0 3000 0 6000 0 0 0 0 0 0 0 0";
        let result = parse_diskstats_line(line);

        assert!(result.is_some());
        let (device, major, stats) = result.unwrap();
        assert_eq!(device, "nvme0n1");
        assert_eq!(major, 259);
        assert_eq!(stats.sectors_read, 2000);
        assert_eq!(stats.sectors_written, 6000);
    }

    #[test]
    fn test_parse_line_too_few_fields() {
        let line = "259 0 nvme0n1";
        assert!(parse_diskstats_line(line).is_none());
    }

    #[test]
    fn test_filter_accepts_nvme() {
        assert!(is_relevant_device("nvme0n1", 259));
    }

    #[test]
    fn test_filter_accepts_sda() {
        assert!(is_relevant_device("sda", 8));
    }

    #[test]
    fn test_filter_rejects_partition_nvme() {
        assert!(!is_relevant_device("nvme0n1p1", 259));
    }

    #[test]
    fn test_filter_rejects_partition_sda() {
        assert!(!is_relevant_device("sda1", 8));
    }

    #[test]
    fn test_filter_rejects_zram() {
        assert!(!is_relevant_device("zram0", 251));
    }

    #[test]
    fn test_filter_rejects_loop() {
        assert!(!is_relevant_device("loop0", 7));
    }

    #[test]
    fn test_filter_rejects_dm() {
        assert!(!is_relevant_device("dm-0", 253));
    }

    #[test]
    fn test_first_collect_returns_zero_rates() {
        let mut collector = DiskCollector::new();
        let metrics = collector.collect();

        assert_eq!(metrics.bytes_read_per_sec, 0.0);
        assert_eq!(metrics.bytes_written_per_sec, 0.0);
    }

    #[test]
    fn test_calculate_rates_with_deltas() {
        let mut prev_devices = HashMap::new();
        prev_devices.insert("nvme0n1".to_string(), DeviceStats {
            sectors_read: 1000,
            sectors_written: 1000,
            reads_completed: 100,
            writes_completed: 100,
        });

        let prev = DiskSnapshot {
            timestamp: Instant::now(),
            devices: prev_devices,
        };

        std::thread::sleep(std::time::Duration::from_millis(50));

        let mut current_devices = HashMap::new();
        current_devices.insert("nvme0n1".to_string(), DeviceStats {
            sectors_read: 3000,
            sectors_written: 3000,
            reads_completed: 200,
            writes_completed: 200,
        });

        let current = DiskSnapshot {
            timestamp: Instant::now(),
            devices: current_devices,
        };

        let (read_rate, write_rate) = calculate_rates(&prev, &current);
        assert!(read_rate > 0.0);
        assert!(write_rate > 0.0);
    }
}

