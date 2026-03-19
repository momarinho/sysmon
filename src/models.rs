use chrono::{DateTime, Utc};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct CpuMetrics {
    pub model_name: String,
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
    pub disk: DiskMetrics,
    pub network: NetMetrics,
    pub services: ServiceMetrics,
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

#[derive(Debug, Clone, Serialize)]
pub struct DiskMetrics {
    /// Total de espaço em bytes
    pub total_bytes: u64,
    /// Espaço usado em bytes
    pub used_bytes: u64,
    /// Espaço disponível em bytes
    pub available_bytes: u64,
    /// Percentual de uso (0-100)
    pub used_percent: f64,
    /// Lista de mount points e seus espaços
    pub filesystems: Vec<FilesystemInfo>,
    /// Taxa de leitura em bytes/segundo
    pub bytes_read_per_sec: f64,
    /// Taxa de escrita em bytes/segundo
    pub bytes_written_per_sec: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct FilesystemInfo {
    /// Ex: "/", "/home", "/var"
    pub mount_point: String,
    /// Ex: "/dev/sda1"
    pub device: String,
    /// Espaço total em bytes
    pub total_bytes: u64,
    /// Espaço usado em bytes
    pub used_bytes: u64,
    /// Percentual de uso
    pub used_percent: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct NetMetrics {
    /// Total de bytes recebidos
    pub bytes_recv: u64,
    /// Total de bytes enviados
    pub bytes_sent: u64,
    /// Total de pacotes recebidos
    pub packets_recv: u64,
    /// Total de pacotes enviados
    pub packets_sent: u64,
    /// Erros recebidos
    pub errors_in: u64,
    /// Erros enviados
    pub errors_out: u64,
    /// Pacotes descartados (entrada)
    pub dropped_in: u64,
    /// Pacotes descartados (saída)
    pub dropped_out: u64,
    /// Detalhes por interface de rede
    pub interfaces: Vec<InterfaceInfo>,
}

#[derive(Debug, Clone, Serialize)]
pub struct InterfaceInfo {
    /// Ex: "eth0", "wlan0", "lo"
    pub name: String,
    /// Bytes recebidos nesta interface
    pub bytes_recv: u64,
    /// Bytes enviados nesta interface
    pub bytes_sent: u64,
    /// Estado da interface (up, down)
    pub status: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct ServiceMetrics {
    /// Lista de serviços e seus estados
    pub services: Vec<ServiceInfo>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ServiceInfo {
    /// Nome do serviço (ex: "nginx", "postgres")
    pub name: String,
    /// Estado: "running", "stopped", "failed", "inactive"
    pub status: String,
    /// Memória utilizada em KB
    pub memory_kb: u64,
    /// CPU em percentual
    pub cpu_percent: f64,
    /// PID (Process ID) ou 0 se não rodando
    pub pid: u32,
}

impl DiskMetrics {
    pub fn new(total_bytes: u64, used_bytes: u64) -> Self {
        let available_bytes = total_bytes.saturating_sub(used_bytes);
        let used_percent = if total_bytes == 0 {
            0.0
        } else {
            round_one_decimal((used_bytes as f64 / total_bytes as f64) * 100.0)
        };

        Self {
            total_bytes,
            used_bytes,
            available_bytes,
            used_percent,
            filesystems: Vec::new(),
            bytes_read_per_sec: 0.0,
            bytes_written_per_sec: 0.0,
        }
    }

    /// Adiciona um filesystem à lista
    pub fn add_filesystem(&mut self, info: FilesystemInfo) {
        self.filesystems.push(info);
    }
}

impl NetMetrics {
    pub fn new() -> Self {
        Self {
            bytes_recv: 0,
            bytes_sent: 0,
            packets_recv: 0,
            packets_sent: 0,
            errors_in: 0,
            errors_out: 0,
            dropped_in: 0,
            dropped_out: 0,
            interfaces: Vec::new(),
        }
    }

    /// Adiciona uma interface à lista
    pub fn add_interface(&mut self, info: InterfaceInfo) {
        self.interfaces.push(info);
    }
}

impl Default for NetMetrics {
    fn default() -> Self {
        Self::new()
    }
}

impl ServiceMetrics {
    pub fn new() -> Self {
        Self {
            services: Vec::new(),
        }
    }

    /// Adiciona um serviço à lista
    pub fn add_service(&mut self, info: ServiceInfo) {
        self.services.push(info);
    }
}

impl Default for ServiceMetrics {
    fn default() -> Self {
        Self::new()
    }
}

pub fn round_one_decimal(value: f64) -> f64 {
    (value * 10.0).round() / 10.0
}
