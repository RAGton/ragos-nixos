use anyhow::Result;
use clap::{Parser, Subcommand};

use crate::{hashing, planner, report, scanner};

/// Kryonix Home Brain — scanner determinístico e organizador seguro da Home
#[derive(Parser)]
#[command(name = "kryonix-home", version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Escaneia a Home e salva resultado em JSON
    Scan,
    /// Mostra relatório do último scan
    Report,
    /// Lista duplicatas exatas (SHA256 idêntico)
    Duplicates,
    /// Gera plano de organização (dry-run por padrão)
    Plan {
        /// Emitir saída em JSON ao invés de texto
        #[arg(long)]
        json: bool,

        /// Modo dry-run (padrão; existe para documentação)
        #[arg(long, default_value_t = true)]
        dry_run: bool,
    },
}

pub fn run() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Scan => {
            let scan = scanner::run_scan()?;
            scanner::save_scan(&scan)?;
            report::print_scan_summary(&scan);
            println!("\nNenhuma alteração foi feita.");
        }
        Commands::Report => {
            let scan = scanner::load_latest_scan()?;
            report::print_full_report(&scan);
            println!("\nNenhuma alteração foi feita.");
        }
        Commands::Duplicates => {
            let scan = scanner::load_latest_scan()?;
            let groups = hashing::find_duplicates(&scan)?;
            report::print_duplicates(&groups);
            println!("\nNenhuma alteração foi feita.");
        }
        Commands::Plan { json, .. } => {
            let scan = scanner::load_latest_scan()?;
            let plan = planner::generate_plan(&scan);
            if json {
                println!("{}", serde_json::to_string_pretty(&plan)?);
            } else {
                report::print_plan(&plan);
            }
            println!("\nNenhuma alteração foi feita. Modo: dry-run.");
        }
    }

    Ok(())
}
