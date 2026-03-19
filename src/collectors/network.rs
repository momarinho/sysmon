use crate::models::NetMetrics;

pub struct NetCollector;

impl NetCollector {
    pub fn new() -> Self {
        Self
    }

    pub fn collect(&self) -> NetMetrics {
        // TODO: Implementar coleta de rede
        // Usar /proc/net/dev ou netlink para obter informações
        NetMetrics::new()
    }
}
