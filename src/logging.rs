use std::fmt::{Display, Formatter};
use std::str::FromStr;
use std::sync::atomic::{AtomicU8, Ordering};

use chrono::Utc;
use serde_json::{Map, Value, json};

static MINIMUM_LEVEL: AtomicU8 = AtomicU8::new(LogLevel::Info as u8);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogLevel {
    Debug = 0,
    Info = 1,
    Warn = 2,
    Error = 3,
}

impl Display for LogLevel {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let value = match self {
            LogLevel::Debug => "debug",
            LogLevel::Info => "info",
            LogLevel::Warn => "warn",
            LogLevel::Error => "error",
        };
        write!(f, "{value}")
    }
}

impl FromStr for LogLevel {
    type Err = String;

    fn from_str(value: &str) -> Result<Self, Self::Err> {
        match value.trim().to_lowercase().as_str() {
            "debug" => Ok(Self::Debug),
            "info" => Ok(Self::Info),
            "warn" => Ok(Self::Warn),
            "error" => Ok(Self::Error),
            _ => Err(format!(
                "SYSMON_LOG_LEVEL must be one of: debug, info, warn, error, got \"{value}\""
            )),
        }
    }
}

pub struct Logger {
    component: &'static str,
}

impl Logger {
    pub fn new(component: &'static str) -> Self {
        Self { component }
    }

    pub fn configure(minimum_level: LogLevel) {
        MINIMUM_LEVEL.store(minimum_level as u8, Ordering::Relaxed);
    }

    pub fn debug(&self, message: &str, extra: Value) {
        self.log(LogLevel::Debug, message, extra);
    }

    pub fn info(&self, message: &str, extra: Value) {
        self.log(LogLevel::Info, message, extra);
    }

    #[allow(dead_code)]
    pub fn warn(&self, message: &str, extra: Value) {
        self.log(LogLevel::Warn, message, extra);
    }

    pub fn error(&self, message: &str, extra: Value) {
        self.log(LogLevel::Error, message, extra);
    }

    fn log(&self, level: LogLevel, message: &str, extra: Value) {
        if (level as u8) < MINIMUM_LEVEL.load(Ordering::Relaxed) {
            return;
        }

        let mut entry = Map::new();
        entry.insert(
            "timestamp".into(),
            Value::String(Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)),
        );
        entry.insert("level".into(), Value::String(level.to_string()));
        entry.insert("component".into(), Value::String(self.component.to_owned()));
        entry.insert("message".into(), Value::String(message.to_owned()));

        if let Value::Object(extra_map) = extra {
            for (key, value) in extra_map {
                entry.insert(key, value);
            }
        }

        println!("{}", Value::Object(entry));
    }
}

pub fn empty() -> Value {
    json!({})
}
