use serde::{Deserialize, Serialize};
use std::fs;
use std::process::Command;

#[derive(Serialize, Deserialize, Debug)]
struct HardwareReport {
    timestamp: String,
    firmware: FirmwareInfo,
    cpu: CpuInfo,
    memory: MemoryInfo,
    disks: serde_json::Value,
    network: Vec<String>,
    gpu: Vec<String>,
    warnings: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct FirmwareInfo {
    mode: String, // "uefi" or "bios"
}

#[derive(Serialize, Deserialize, Debug)]
struct CpuInfo {
    model: String,
    cores: usize,
}

#[derive(Serialize, Deserialize, Debug)]
struct MemoryInfo {
    total_kb: u64,
}

fn main() {
    let mut warnings = Vec::new();

    let firmware = FirmwareInfo {
        mode: if fs::metadata("/sys/firmware/efi").is_ok() {
            "uefi".to_string()
        } else {
            "bios".to_string()
        },
    };

    let cpu = detect_cpu();
    let memory = detect_memory();
    let disks = detect_disks(&mut warnings);
    let network = detect_network();
    let gpu = detect_gpu(&mut warnings);

    let report = HardwareReport {
        timestamp: chrono::Utc::now().to_rfc3339(),
        firmware,
        cpu,
        memory,
        disks,
        network,
        gpu,
        warnings,
    };

    println!("{}", serde_json::to_string_pretty(&report).unwrap());
}

fn detect_cpu() -> CpuInfo {
    let content = fs::read_to_string("/proc/cpuinfo").unwrap_or_default();
    let model = content
        .lines()
        .find(|l| l.starts_with("model name"))
        .map(|l| l.split(':').nth(1).unwrap_or("Unknown").trim().to_string())
        .unwrap_or_else(|| "Unknown CPU".to_string());

    let cores = content.lines().filter(|l| l.starts_with("processor")).count();

    CpuInfo { model, cores }
}

fn detect_memory() -> MemoryInfo {
    let content = fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let total_kb = content
        .lines()
        .find(|l| l.starts_with("MemTotal"))
        .map(|l| {
            l.split_whitespace()
                .nth(1)
                .and_then(|v| v.parse::<u64>().ok())
                .unwrap_or(0)
        })
        .unwrap_or(0);

    MemoryInfo { total_kb }
}

fn detect_disks(warnings: &mut Vec<String>) -> serde_json::Value {
    let output = Command::new("lsblk")
        .args(&["-J", "-o", "NAME,MODEL,SIZE,TYPE,MOUNTPOINT,TRAN,VENDOR,SERIAL"])
        .output();

    match output {
        Ok(o) if o.status.success() => {
            serde_json::from_slice(&o.stdout).unwrap_or(serde_json::json!({"error": "Failed to parse lsblk output"}))
        }
        _ => {
            warnings.push("lsblk command failed or not found".to_string());
            serde_json::json!({"blockdevices": []})
        }
    }
}

fn detect_network() -> Vec<String> {
    fs::read_dir("/sys/class/net")
        .map(|entries| {
            entries
                .filter_map(|e| e.ok().map(|e| e.file_name().to_string_lossy().into_owned()))
                .filter(|n| n != "lo")
                .collect()
        })
        .unwrap_or_default()
}

fn detect_gpu(warnings: &mut Vec<String>) -> Vec<String> {
    let output = Command::new("lspci").output();

    match output {
        Ok(o) if o.status.success() => {
            let stdout = String::from_utf8_lossy(&o.stdout);
            stdout
                .lines()
                .filter(|l| l.contains("VGA") || l.contains("3D controller"))
                .map(|l| l.to_string())
                .collect()
        }
        _ => {
            warnings.push("lspci command failed or not found. Cannot accurately detect GPU.".to_string());
            Vec::new()
        }
    }
}
