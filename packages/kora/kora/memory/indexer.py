import os
import json
import hashlib
import logging
import asyncio
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional
from ..core.config import BRAIN_URL, BRAIN_API_KEY
from ..integrations import brain as brain_adapter

logger = logging.getLogger(__name__)

class MemoryIndexer:
    def __init__(self, 
                 vault_dir: str = "/var/lib/kryonix/vault/Kora",
                 manifest_path: str = "/var/lib/kryonix/kora/memory/index_manifest.json"):
        self.vault_dir = Path(vault_dir)
        self.manifest_path = Path(manifest_path)
        self.manifest: Dict[str, dict] = {}
        self._load_manifest()

    def _load_manifest(self):
        """Load the index manifest from disk."""
        if self.manifest_path.exists():
            try:
                with open(self.manifest_path, "r", encoding="utf-8") as f:
                    self.manifest = json.load(f)
            except Exception as e:
                logger.error(f"Failed to load manifest: {e}")
                self.manifest = {}

    def _save_manifest(self):
        """Save the index manifest to disk."""
        try:
            self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.manifest_path, "w", encoding="utf-8") as f:
                json.dump(self.manifest, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save manifest: {e}")

    def _get_file_hash(self, path: Path) -> str:
        """Compute SHA256 hash of a file."""
        hasher = hashlib.sha256()
        try:
            with open(path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hasher.update(chunk)
            return hasher.hexdigest()
        except Exception as e:
            logger.error(f"Hash failed for {path}: {e}")
            return ""

    def scan(self) -> List[Path]:
        """Scan the vault for markdown files and identify pending items."""
        if not self.vault_dir.exists():
            logger.warning(f"Vault directory not found: {self.vault_dir}")
            return []

        pending = []
        for root, _, files in os.walk(self.vault_dir):
            for file in files:
                if file.endswith(".md"):
                    path = Path(root) / file
                    rel_path = str(path.relative_to(self.vault_dir))
                    
                    mtime = os.path.getmtime(path)
                    current_hash = self._get_file_hash(path)
                    
                    entry = self.manifest.get(rel_path)
                    
                    if not entry or entry.get("sha256") != current_hash:
                        pending.append(path)
        
        return pending

    async def index_all(self, auto_approve: bool = True):
        """Index all pending files."""
        pending = self.scan()
        if not pending:
            logger.info("Nothing to index (Kora memory is up to date).")
            return 0

        logger.info(f"Indexing {len(pending)} Kora memories...")
        count = 0
        for path in pending:
            rel_path = str(path.relative_to(self.vault_dir))
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()

                # Call Brain API to propose ingestion
                # We use 'source' as the relative path to identify it in the vault
                res = await brain_adapter.propose_ingest(
                    content=content,
                    source=f"vault/Kora/{rel_path}",
                    reason="Kora Memory Ingestion"
                )

                if res.get("status") == "queued":
                    item_id = res.get("id")
                    logger.info(f"Memory {rel_path} queued for ingestion (ID: {item_id})")
                    
                    # Update manifest
                    self.manifest[rel_path] = {
                        "file": str(path),
                        "sha256": self._get_file_hash(path),
                        "mtime": os.path.getmtime(path),
                        "indexed_at": datetime.now(timezone.utc).isoformat(),
                        "item_id": item_id,
                        "status": "pending_approval"
                    }
                    count += 1
                else:
                    logger.error(f"Failed to queue memory {rel_path}: {res}")

            except Exception as e:
                logger.error(f"Error indexing {rel_path}: {e}")

        self._save_manifest()
        return count

    def get_status(self) -> dict:
        """Return indexing statistics."""
        indexed_count = len([k for k, v in self.manifest.items() if v.get("status") == "indexed" or v.get("status") == "pending_approval"])
        pending_approval = len([k for k, v in self.manifest.items() if v.get("status") == "pending_approval"])
        
        return {
            "vault_dir": str(self.vault_dir),
            "manifest_path": str(self.manifest_path),
            "total_files_in_manifest": len(self.manifest),
            "indexed_files": indexed_count,
            "pending_approval": pending_approval,
            "status": "ok" if self.vault_dir.exists() else "missing_vault"
        }

    def get_pending(self) -> List[str]:
        """Return list of relative paths for pending files."""
        return [str(p.relative_to(self.vault_dir)) for p in self.scan()]
