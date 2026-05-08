use std::path::Path;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Metadados coletados de um arquivo durante o scan.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileMetadata {
    pub path: String,
    pub filename: String,
    pub extension: String,
    pub mime: String,
    pub size_bytes: u64,
    pub modified_at: Option<DateTime<Utc>>,
    pub is_symlink: bool,
    pub status: FileStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum FileStatus {
    Analyzed,
    Ignored,
    Error,
}

/// Coleta metadados de um arquivo.
/// Nota: symlinks são identificados mas nunca seguidos pelo scanner.
pub fn collect(path: &Path, is_symlink: bool) -> FileMetadata {
    let filename = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string();

    let extension = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    let mime = mime_guess::from_path(path)
        .first_or_octet_stream()
        .to_string();

    let (size_bytes, modified_at) = match std::fs::metadata(path) {
        Ok(meta) => {
            let mtime = meta.modified().ok().map(DateTime::<Utc>::from);
            (meta.len(), mtime)
        }
        Err(_) => (0, None),
    };

    FileMetadata {
        path: path.to_string_lossy().to_string(),
        filename,
        extension,
        mime,
        size_bytes,
        modified_at,
        is_symlink,
        status: if is_symlink {
            FileStatus::Ignored
        } else {
            FileStatus::Analyzed
        },
    }
}
