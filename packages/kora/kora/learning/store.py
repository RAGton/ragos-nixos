from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_BASE = Path("/var/lib/kryonix/kora/learning")
FALLBACK_BASE = Path.home() / ".local/share/kryonix/kora/learning"


def canonical_user_id(user_id: str | None) -> str:
    user = (user_id or "unknown").strip().lower()
    if user in {"rocha", "ragton", "gabriel"}:
        return "ragton"
    if user in {"nina", "nicoly"}:
        return "nicoly"
    return user or "unknown"


def resolve_learning_dir(base_dir: str | None = None) -> Path:
    if base_dir:
        base = Path(base_dir)
    elif os.getenv("KORA_LEARNING_DIR"):
        base = Path(os.environ["KORA_LEARNING_DIR"])
    else:
        base = DEFAULT_BASE

    try:
        base.mkdir(parents=True, exist_ok=True)
        return base
    except OSError:
        FALLBACK_BASE.mkdir(parents=True, exist_ok=True)
        return FALLBACK_BASE


class JsonStore:
    def __init__(self, base_dir: str | None = None):
        self.base_dir = resolve_learning_dir(base_dir)

    def user_dir(self, user_id: str | None) -> Path:
        path = self.base_dir / canonical_user_id(user_id)
        path.mkdir(parents=True, exist_ok=True)
        return path

    def path(self, user_id: str | None, filename: str) -> Path:
        return self.user_dir(user_id) / filename

    def load(self, user_id: str | None, filename: str, default: Any) -> Any:
        path = self.path(user_id, filename)
        if not path.exists():
            return default
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return default

    def save(self, user_id: str | None, filename: str, data: Any) -> Path:
        path = self.path(user_id, filename)
        if isinstance(data, dict):
            data["last_updated"] = datetime.now(timezone.utc).isoformat()
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        tmp.replace(path)
        return path
