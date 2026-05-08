use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use walkdir::WalkDir;

use crate::ignore;
use crate::metadata::{self, FileMetadata, FileStatus};

/// Diretórios permitidos para scan na Home do usuário.
const SCAN_DIRS: &[&str] = &[
    "Downloads",
    "Documentos",
    "Imagens",
    "Vídeos",
    "Músicas",
    "Área de Trabalho",
    "Desktop",
    "Pictures",
    "Videos",
    "Music",
    "Documents",
];

/// Resultado completo de um scan.
#[derive(Debug, Serialize, Deserialize)]
pub struct ScanResult {
    pub run_id: String,
    pub timestamp: DateTime<Utc>,
    pub home_dir: String,
    pub dirs_scanned: Vec<String>,
    pub files: Vec<FileMetadata>,
    pub files_analyzed: usize,
    pub files_ignored: usize,
    pub files_error: usize,
    pub total_size_bytes: u64,
}

/// Retorna o diretório de estado do Kryonix Home Brain.
fn state_dir() -> Result<PathBuf> {
    let home = dirs::home_dir().context("Não foi possível determinar o diretório home")?;
    let dir = home.join(".local/state/kryonix/home-brain");
    fs::create_dir_all(&dir)?;
    Ok(dir)
}

/// Retorna o diretório de runs.
fn runs_dir(run_id: &str) -> Result<PathBuf> {
    let dir = state_dir()?.join("runs").join(run_id);
    fs::create_dir_all(&dir)?;
    Ok(dir)
}

/// Gera um run_id baseado no timestamp e hostname.
fn generate_run_id() -> String {
    let ts = Utc::now().format("%Y%m%d-%H%M%S");
    let host = hostname::get()
        .map(|h| h.to_string_lossy().to_string())
        .unwrap_or_else(|_| "unknown".to_string());
    format!("{ts}-{host}")
}

/// Executa o scan da Home do usuário.
pub fn run_scan() -> Result<ScanResult> {
    let home = dirs::home_dir().context("Não foi possível determinar o diretório home")?;
    let run_id = generate_run_id();
    let timestamp = Utc::now();

    let mut files: Vec<FileMetadata> = Vec::new();
    let mut dirs_scanned: Vec<String> = Vec::new();

    for dir_name in SCAN_DIRS {
        let scan_path = home.join(dir_name);
        if !scan_path.exists() || !scan_path.is_dir() {
            continue;
        }
        dirs_scanned.push(dir_name.to_string());

        walk_directory(&scan_path, &mut files);
    }

    let files_analyzed = files
        .iter()
        .filter(|f| f.status == FileStatus::Analyzed)
        .count();
    let files_ignored = files
        .iter()
        .filter(|f| f.status == FileStatus::Ignored)
        .count();
    let files_error = files
        .iter()
        .filter(|f| f.status == FileStatus::Error)
        .count();
    let total_size_bytes: u64 = files
        .iter()
        .filter(|f| f.status == FileStatus::Analyzed)
        .map(|f| f.size_bytes)
        .sum();

    Ok(ScanResult {
        run_id,
        timestamp,
        home_dir: home.to_string_lossy().to_string(),
        dirs_scanned,
        files,
        files_analyzed,
        files_ignored,
        files_error,
        total_size_bytes,
    })
}

/// Percorre um diretório recursivamente.
///
/// Regras de segurança:
/// - follow_links(false): nunca segue symlinks
/// - Ignora diretórios ocultos, config, cache, secrets
/// - Ignora diretórios de projetos (markers)
/// - Ignora arquivos secretos
fn walk_directory(root: &Path, files: &mut Vec<FileMetadata>) {
    let walker = WalkDir::new(root)
        .follow_links(false) // NUNCA seguir symlinks
        .same_file_system(true) // NÃO atravessar mounts externos
        .into_iter();

    for entry in walker.filter_entry(|e| {
        let path = e.path();
        // Se for diretório, checar se deve ser ignorado
        if e.file_type().is_dir() {
            if ignore::should_ignore_dir(path) {
                return false;
            }
            if ignore::is_project_dir(path) {
                return false;
            }
        }
        true
    }) {
        let entry = match entry {
            Ok(e) => e,
            Err(_) => continue,
        };

        // Só processar arquivos regulares
        if !entry.file_type().is_file() && !entry.file_type().is_symlink() {
            continue;
        }

        let path = entry.path();
        let is_symlink = entry.file_type().is_symlink();

        // Ignorar arquivos secretos
        if ignore::is_secret_file(path) {
            files.push(FileMetadata {
                path: path.to_string_lossy().to_string(),
                filename: path
                    .file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("")
                    .to_string(),
                extension: String::new(),
                mime: String::new(),
                size_bytes: 0,
                modified_at: None,
                is_symlink,
                status: FileStatus::Ignored,
            });
            continue;
        }

        // Symlinks são registrados mas marcados como Ignored
        if is_symlink {
            files.push(metadata::collect(path, true));
            continue;
        }

        files.push(metadata::collect(path, false));
    }
}

/// Salva o resultado do scan em disco.
pub fn save_scan(scan: &ScanResult) -> Result<()> {
    let state = state_dir()?;
    let run_dir = runs_dir(&scan.run_id)?;

    // Salvar no diretório do run
    let run_path = run_dir.join("scan.json");
    let json = serde_json::to_string_pretty(scan)?;
    fs::write(&run_path, &json)?;

    // Salvar como latest
    let latest_path = state.join("latest-scan.json");
    fs::write(&latest_path, &json)?;

    eprintln!("Scan salvo em: {}", run_path.display());
    eprintln!("Latest:        {}", latest_path.display());

    Ok(())
}

/// Carrega o último scan salvo.
pub fn load_latest_scan() -> Result<ScanResult> {
    let state = state_dir()?;
    let path = state.join("latest-scan.json");

    if !path.exists() {
        anyhow::bail!(
            "Nenhum scan encontrado. Execute 'kryonix home scan' primeiro.\n\
             Arquivo esperado: {}",
            path.display()
        );
    }

    let json = fs::read_to_string(&path)?;
    let scan: ScanResult = serde_json::from_str(&json)?;
    Ok(scan)
}
