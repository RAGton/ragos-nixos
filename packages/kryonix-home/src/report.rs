use std::collections::HashMap;

use crate::hashing::DuplicateGroup;
use crate::metadata::FileStatus;
use crate::planner::Plan;
use crate::scanner::ScanResult;

/// Formata tamanho em bytes para formato legível.
fn format_size(bytes: u64) -> String {
    const KIB: u64 = 1024;
    const MIB: u64 = 1024 * KIB;
    const GIB: u64 = 1024 * MIB;
    const TIB: u64 = 1024 * GIB;

    if bytes >= TIB {
        format!("{:.1} TiB", bytes as f64 / TIB as f64)
    } else if bytes >= GIB {
        format!("{:.1} GiB", bytes as f64 / GIB as f64)
    } else if bytes >= MIB {
        format!("{:.1} MiB", bytes as f64 / MIB as f64)
    } else if bytes >= KIB {
        format!("{:.1} KiB", bytes as f64 / KIB as f64)
    } else {
        format!("{bytes} B")
    }
}

/// Imprime resumo rápido do scan.
pub fn print_scan_summary(scan: &ScanResult) {
    println!("Kryonix Home Scan");
    println!();
    println!("  Run ID:             {}", scan.run_id);
    println!("  Root:               {}", scan.home_dir);
    println!("  Diretórios:         {}", scan.dirs_scanned.join(", "));
    println!("  Arquivos analisados: {}", scan.files_analyzed);
    println!("  Arquivos ignorados:  {}", scan.files_ignored);
    println!("  Erros:              {}", scan.files_error);
    println!(
        "  Tamanho total:      {}",
        format_size(scan.total_size_bytes)
    );
}

/// Imprime relatório completo.
pub fn print_full_report(scan: &ScanResult) {
    print_scan_summary(scan);

    // Extensões mais comuns
    let mut ext_counts: HashMap<String, usize> = HashMap::new();
    for file in &scan.files {
        if file.status == FileStatus::Analyzed {
            let ext = if file.extension.is_empty() {
                "(sem extensão)".to_string()
            } else {
                file.extension.clone()
            };
            *ext_counts.entry(ext).or_default() += 1;
        }
    }

    let mut ext_sorted: Vec<_> = ext_counts.into_iter().collect();
    ext_sorted.sort_by(|a, b| b.1.cmp(&a.1));

    println!();
    println!("Tipos de arquivo (top 15):");
    for (ext, count) in ext_sorted.iter().take(15) {
        println!("  {ext:>15}: {count}");
    }

    // Maiores arquivos
    let mut analyzed: Vec<_> = scan
        .files
        .iter()
        .filter(|f| f.status == FileStatus::Analyzed)
        .collect();
    analyzed.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));

    println!();
    println!("Maiores arquivos (top 10):");
    for file in analyzed.iter().take(10) {
        println!("  {} — {}", format_size(file.size_bytes), file.path);
    }

    // Tamanho por MIME
    let mut mime_sizes: HashMap<String, u64> = HashMap::new();
    for file in &scan.files {
        if file.status == FileStatus::Analyzed {
            *mime_sizes.entry(mime_category(&file.mime)).or_default() += file.size_bytes;
        }
    }
    let mut mime_sorted: Vec<_> = mime_sizes.into_iter().collect();
    mime_sorted.sort_by(|a, b| b.1.cmp(&a.1));

    println!();
    println!("Tamanho por categoria:");
    for (cat, size) in &mime_sorted {
        println!("  {cat:>15}: {}", format_size(*size));
    }
}

/// Categoria MIME simplificada.
fn mime_category(mime: &str) -> String {
    if mime.starts_with("image/") {
        "Imagens".to_string()
    } else if mime.starts_with("video/") {
        "Vídeos".to_string()
    } else if mime.starts_with("audio/") {
        "Áudio".to_string()
    } else if mime.starts_with("text/") {
        "Texto".to_string()
    } else if mime == "application/pdf" {
        "PDF".to_string()
    } else if mime.contains("zip")
        || mime.contains("tar")
        || mime.contains("compressed")
        || mime.contains("gzip")
    {
        "Compactados".to_string()
    } else {
        "Outros".to_string()
    }
}

/// Imprime lista de grupos de duplicatas.
pub fn print_duplicates(groups: &[DuplicateGroup]) {
    if groups.is_empty() {
        println!("Nenhuma duplicata exata encontrada.");
        return;
    }

    println!("Duplicatas exatas (SHA256 idêntico):");
    println!();
    println!("{} grupo(s) encontrado(s):", groups.len());
    println!();

    for (i, group) in groups.iter().enumerate() {
        println!(
            "  Grupo {} — {} ({} arquivos):",
            i + 1,
            format_size(group.size_bytes),
            group.files.len()
        );
        println!("  SHA256: {}", group.hash);
        for file in &group.files {
            println!("    • {file}");
        }
        println!();
    }

    let total_waste: u64 = groups
        .iter()
        .map(|g| g.size_bytes * (g.files.len() as u64 - 1))
        .sum();
    println!(
        "Espaço desperdiçado por duplicatas: {}",
        format_size(total_waste)
    );
}

/// Imprime o plano em formato legível.
pub fn print_plan(plan: &Plan) {
    println!("Kryonix Home Plan (dry-run)");
    println!();
    println!("  Run ID:        {}", plan.run_id);
    println!("  Root:          {}", plan.home_dir);
    println!("  Arquivos:      {}", plan.files_seen);
    println!("  Propostas:     {}", plan.proposals.len());
    println!();

    if plan.proposals.is_empty() {
        println!("Nenhuma proposta de organização.");
        return;
    }

    // Agrupar por destino
    let mut by_dest: HashMap<String, Vec<&crate::planner::PlanProposal>> = HashMap::new();
    for p in &plan.proposals {
        by_dest.entry(p.new_dir.clone()).or_default().push(p);
    }

    let mut dest_sorted: Vec<_> = by_dest.into_iter().collect();
    dest_sorted.sort_by(|a, b| b.1.len().cmp(&a.1.len()));

    for (dest, proposals) in &dest_sorted {
        println!("  {} ({} arquivo(s)):", dest, proposals.len());
        for p in proposals.iter().take(5) {
            let review = if p.needs_review { " [REVISAR]" } else { "" };
            println!("    [{:>6}] {} — {}{review}", p.risk, p.old_path, p.reason);
        }
        if proposals.len() > 5 {
            println!("    ... e mais {} arquivo(s)", proposals.len() - 5);
        }
        println!();
    }
}
