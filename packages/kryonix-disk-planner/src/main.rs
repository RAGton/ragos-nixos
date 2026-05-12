use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Serialize, Deserialize, Debug)]
struct InstallPlan {
    version: u32,
    profile: String,
    hostname: String,
    timezone: String,
    locale: String,
    keyboard: String,
    boot: BootConfig,
    disk: DiskConfig,
    user: UserConfig,
    features: FeaturesConfig,
}

#[derive(Serialize, Deserialize, Debug)]
struct BootConfig {
    mode: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct DiskConfig {
    mode: String,
    target: String,
    layout: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct UserConfig {
    name: String,
    admin: bool,
}

#[derive(Serialize, Deserialize, Debug)]
struct FeaturesConfig {
    desktop: String,
    nvidia: String,
    zram: bool,
    brain_client: bool,
}

fn main() {
    let mut buffer = String::new();
    let _ = io::stdin().read_to_string(&mut buffer);

    // Stub: Ignora input por enquanto e gera um plano padrão
    let plan = InstallPlan {
        version: 1,
        profile: "desktop".to_string(),
        hostname: "kryonix".to_string(),
        timezone: "America/Cuiaba".to_string(),
        locale: "pt_BR.UTF-8".to_string(),
        keyboard: "br-abnt2".to_string(),
        boot: BootConfig {
            mode: "uefi".to_string(),
        },
        disk: DiskConfig {
            mode: "dry-run".to_string(),
            target: "/dev/nvme0n1".to_string(),
            layout: "btrfs-simple".to_string(),
        },
        user: UserConfig {
            name: "rocha".to_string(),
            admin: true,
        },
        features: FeaturesConfig {
            desktop: "hyprland-caelestia".to_string(),
            nvidia: "auto".to_string(),
            zram: true,
            brain_client: true,
        },
    };

    println!("{}", serde_json::to_string_pretty(&plan).unwrap());
}
