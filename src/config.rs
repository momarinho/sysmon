use std::env;
use std::error::Error;
use std::fmt::{Display, Formatter};

use crate::logging::LogLevel;

#[derive(Debug, Clone)]
pub struct Config {
    pub port: u16,
    pub interval_ms: u64,
    pub services: Vec<String>,
    pub log_level: LogLevel,
}

#[derive(Debug, Clone)]
pub struct ConfigError {
    message: String,
}

impl ConfigError {
    fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
        }
    }
}

impl Display for ConfigError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "ConfigError: {}", self.message)
    }
}

impl Error for ConfigError {}

impl Config {
    pub fn from_env() -> Result<Self, ConfigError> {
        Self::from_map(env::vars().collect())
    }

    pub fn from_map(env: std::collections::HashMap<String, String>) -> Result<Self, ConfigError> {
        let port = parse_u16(&env, "SYSMON_PORT", 8080, 1, u16::MAX)?;
        let interval_ms = parse_u64(&env, "SYSMON_INTERVAL_MS", 2000, 1)?;
        let services = env
            .get("SYSMON_SERVICES")
            .map(String::as_str)
            .unwrap_or("postgresql,redis")
            .split(',')
            .map(str::trim)
            .filter(|service| !service.is_empty())
            .map(ToOwned::to_owned)
            .collect::<Vec<_>>();

        if services.is_empty() {
            return Err(ConfigError::new(
                "SYSMON_SERVICES must contain at least one service name",
            ));
        }

        let log_level = env
            .get("SYSMON_LOG_LEVEL")
            .map(String::as_str)
            .unwrap_or("info")
            .parse::<LogLevel>()
            .map_err(ConfigError::new)?;

        Ok(Self {
            port,
            interval_ms,
            services,
            log_level,
        })
    }
}

fn parse_u16(
    env: &std::collections::HashMap<String, String>,
    key: &str,
    fallback: u16,
    min: u16,
    max: u16,
) -> Result<u16, ConfigError> {
    let raw = env.get(key).map(String::as_str).unwrap_or_default().trim().to_owned();
    if raw.is_empty() {
        return Ok(fallback);
    }

    let value = raw
        .parse::<u16>()
        .map_err(|_| ConfigError::new(format!("{key} must be an integer, got \"{raw}\"")))?;

    if value < min {
        return Err(ConfigError::new(format!("{key} must be >= {min}, got {value}")));
    }
    if value > max {
        return Err(ConfigError::new(format!("{key} must be <= {max}, got {value}")));
    }

    Ok(value)
}

fn parse_u64(
    env: &std::collections::HashMap<String, String>,
    key: &str,
    fallback: u64,
    min: u64,
) -> Result<u64, ConfigError> {
    let raw = env.get(key).map(String::as_str).unwrap_or_default().trim().to_owned();
    if raw.is_empty() {
        return Ok(fallback);
    }

    let value = raw
        .parse::<u64>()
        .map_err(|_| ConfigError::new(format!("{key} must be an integer, got \"{raw}\"")))?;

    if value < min {
        return Err(ConfigError::new(format!("{key} must be >= {min}, got {value}")));
    }

    Ok(value)
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::Config;
    use crate::logging::LogLevel;

    #[test]
    fn loads_valid_values() {
        let mut env = HashMap::new();
        env.insert("SYSMON_PORT".into(), "9090".into());
        env.insert("SYSMON_INTERVAL_MS".into(), "1500".into());
        env.insert("SYSMON_SERVICES".into(), "postgresql, redis".into());
        env.insert("SYSMON_LOG_LEVEL".into(), "debug".into());

        let config = Config::from_map(env).unwrap();

        assert_eq!(config.port, 9090);
        assert_eq!(config.interval_ms, 1500);
        assert_eq!(config.services, vec!["postgresql", "redis"]);
        assert_eq!(config.log_level, LogLevel::Debug);
    }

    #[test]
    fn uses_defaults() {
        let config = Config::from_map(HashMap::new()).unwrap();

        assert_eq!(config.port, 8080);
        assert_eq!(config.interval_ms, 2000);
        assert_eq!(config.services, vec!["postgresql", "redis"]);
        assert_eq!(config.log_level, LogLevel::Info);
    }
}

