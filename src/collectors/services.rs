use std::process::Command;
use crate::models::{ServiceInfo, ServiceMetrics};

// STATUS ENUM
#[derive(Clone, Debug, PartialEq)]
enum ServiceStatus {
    Active,
    Inactive,
    Failed,
    Unknown,
}

impl ServiceStatus {
    fn from_systemctl_string(output: &str) -> Self {
        let trimmed = output.trim().to_lowercase();
        match trimmed.as_str() {
            "active" => Self::Active,
            "inactive" => Self::Inactive,
            "failed" => Self::Failed,
            _ => Self::Unknown,
        }
    }

    fn as_string(&self) -> String {
        match self {
            Self::Active => "running".to_string(),
            Self::Inactive => "stopped".to_string(),
            Self::Failed => "failed".to_string(),
            Self::Unknown => "unknown".to_string(),
        }
    }
}

// AUXILIARY FUNCTIONS
fn get_service_status(service_name: &str) -> ServiceStatus {
    match Command::new("systemctl")
        .args(&["show", "-p", "ActiveState", "--value", service_name])
        .output()
    {
        Ok(output) => {
            let status_str = String::from_utf8_lossy(&output.stdout);
            ServiceStatus::from_systemctl_string(&status_str)
        }
        Err(_) => ServiceStatus::Unknown,
    }
}

// PUBLIC STRUCT
pub struct ServiceCollector {
    services: Vec<String>,
}

// IMPLEMENTATION
impl ServiceCollector {
    pub fn new(services: Vec<String>) -> Self {
        Self { services }
    }

    pub fn collect(&self) -> ServiceMetrics {
        let mut metrics = ServiceMetrics::new();

        for service_name in &self.services {
            let status = get_service_status(service_name);
            let service_info = ServiceInfo {
                name: service_name.clone(),
                status: status.as_string(),
                memory_kb: 0,
                cpu_percent: 0.0,
                pid: 0,
            };

            metrics.add_service(service_info);
        }

        metrics
    }
}

// TESTS
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_from_active() {
        let status = ServiceStatus::from_systemctl_string("active");
        assert_eq!(status, ServiceStatus::Active);
    }

    #[test]
    fn test_status_from_inactive() {
        let status = ServiceStatus::from_systemctl_string("inactive");
        assert_eq!(status, ServiceStatus::Inactive);
    }

    #[test]
    fn test_status_from_failed() {
        let status = ServiceStatus::from_systemctl_string("failed");
        assert_eq!(status, ServiceStatus::Failed);
    }

    #[test]
    fn test_status_from_unknown() {
        let status = ServiceStatus::from_systemctl_string("activating");
        assert_eq!(status, ServiceStatus::Unknown);
    }

    #[test]
    fn test_status_as_string_active() {
        assert_eq!(ServiceStatus::Active.as_string(), "running");
    }

    #[test]
    fn test_status_as_string_inactive() {
        assert_eq!(ServiceStatus::Inactive.as_string(), "stopped");
    }

    #[test]
    fn test_status_as_string_failed() {
        assert_eq!(ServiceStatus::Failed.as_string(), "failed");
    }

    #[test]
    fn test_status_as_string_unknown() {
        assert_eq!(ServiceStatus::Unknown.as_string(), "unknown");
    }

    #[test]
    fn test_collector_new() {
        let services = vec!["postgresql".to_string(), "redis".to_string()];
        let collector = ServiceCollector::new(services.clone());
        assert_eq!(collector.services, services);
    }

    #[test]
    fn test_collector_collect_returns_metrics() {
        let services = vec!["postgresql".to_string()];
        let collector = ServiceCollector::new(services);
        let metrics = collector.collect();

        assert!(!metrics.services.is_empty());
        assert_eq!(metrics.services[0].name, "postgresql");
    }
}