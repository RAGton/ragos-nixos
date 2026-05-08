use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, Read};
use std::path::Path;

use anyhow::Result;
use sha2::{Digest, Sha256};

use crate::metadata::{FileMetadata, FileStatus};
use crate::scanner::ScanResult;

/// Tamanho do buffer de leitura para hash (64 KiB).
const HASH_BUF_SIZE: usize = 64 * 1024;

/// Resultado de detecção de duplicatas.
#[derive(Debug)]
pub struct DuplicateGroup {
    pub hash: String,
    pub size_bytes: u64,
    pub files: Vec<String>,
}

/// Calcula o SHA256 de um arquivo.
fn sha256_of(path: &Path) -> Result<String> {
    let file = File::open(path)?;
    let mut reader = BufReader::with_capacity(HASH_BUF_SIZE, file);
    let mut hasher = Sha256::new();
    let mut buf = vec![0u8; HASH_BUF_SIZE];

    loop {
        let n = reader.read(&mut buf)?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }

    Ok(hex::encode(hasher.finalize()))
}

/// Encontra duplicatas exatas usando SHA256 lazy/incremental:
///
/// 1. Agrupa arquivos por tamanho.
/// 2. Só calcula SHA256 em grupos com 2+ arquivos de mesmo tamanho.
/// 3. Retorna apenas grupos com hash idêntico e 2+ arquivos.
pub fn find_duplicates(scan: &ScanResult) -> Result<Vec<DuplicateGroup>> {
    // Passo 1: agrupar por tamanho
    let mut by_size: HashMap<u64, Vec<&FileMetadata>> = HashMap::new();
    for file in &scan.files {
        if file.status != FileStatus::Analyzed {
            continue;
        }
        if file.size_bytes == 0 {
            continue; // ignorar arquivos vazios
        }
        by_size.entry(file.size_bytes).or_default().push(file);
    }

    // Passo 2: hash apenas candidatos (2+ arquivos com mesmo tamanho)
    let mut groups: Vec<DuplicateGroup> = Vec::new();

    for candidates in by_size.values() {
        if candidates.len() < 2 {
            continue;
        }

        let mut by_hash: HashMap<String, Vec<String>> = HashMap::new();
        for file in candidates {
            match sha256_of(Path::new(&file.path)) {
                Ok(hash) => {
                    by_hash.entry(hash).or_default().push(file.path.clone());
                }
                Err(_) => continue,
            }
        }

        for (hash, files) in by_hash {
            if files.len() >= 2 {
                groups.push(DuplicateGroup {
                    hash,
                    size_bytes: candidates[0].size_bytes,
                    files,
                });
            }
        }
    }

    groups.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
    Ok(groups)
}
