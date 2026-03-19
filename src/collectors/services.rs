use crate::models::ServiceMetrics;

pub struct ServiceCollector;

impl ServiceCollector {
    pub fn new() -> Self {
        Self
    }

    pub fn collect(&self) -> ServiceMetrics {
        // TODO: Implementar coleta de serviços
        // Usar systemd D-Bus ou /etc/systemd/system para obter informações
        ServiceMetrics::new()
    }
}
