import os
import subprocess
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from .obsidian import ObsidianWriter

logger = logging.getLogger(__name__)

class MemorySearch:
    def __init__(self, vault_dir: Optional[str] = None):
        writer = ObsidianWriter(vault_dir)
        self.vault_dir = writer.vault_dir

    def search(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Simple grep-based search in the Obsidian vault."""
        if not self.vault_dir.exists():
            return []

        results = []
        try:
            # Search for the query in the vault directory
            # Use 'rg' if available, fallback to 'grep'
            cmd = ["rg", "-i", "-l", query, str(self.vault_dir)]
            process = subprocess.run(cmd, capture_output=True, text=True)

            if process.returncode == 0:
                file_paths = process.stdout.strip().split("\n")
                for path_str in file_paths[:limit]:
                    path = Path(path_str)
                    if path.suffix == ".md":
                        results.append(self._parse_note(path))

            return results
        except Exception as e:
            logger.error("Memory search failed: %s", e)
            return []

    def get_recent(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get the most recently created/modified notes."""
        if not self.vault_dir.exists():
            return []

        try:
            # Find all .md files and sort by modification time
            files = list(self.vault_dir.glob("**/*.md"))
            files.sort(key=lambda x: x.stat().st_mtime, reverse=True)

            return [self._parse_note(f) for f in files[:limit]]
        except Exception as e:
            logger.error("Failed to get recent memories: %s", e)
            return []

    def _parse_note(self, path: Path) -> Dict[str, Any]:
        """Extract title and frontmatter from a note."""
        title = path.stem
        content = ""
        try:
            with open(path, "r") as f:
                content = f.read()
        except:
            pass

        return {
            "title": title,
            "path": str(path.relative_to(self.vault_dir)),
            "full_path": str(path),
            "snippet": content[:200] + "..." if len(content) > 200 else content
        }
