from __future__ import annotations

import json
import os
from datetime import date, datetime, timezone
from pathlib import Path

from .privacy import sanitize_text
from .store import canonical_user_id, resolve_learning_dir


def daily_dir(user_id: str | None, base_dir: str | None = None) -> Path:
    path = resolve_learning_dir(base_dir) / canonical_user_id(user_id) / "daily"
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_daily_event(user_id: str | None, event: dict, base_dir: str | None = None) -> Path:
    path = daily_dir(user_id, base_dir) / f"{date.today().isoformat()}.jsonl"
    clean_event = {
        key: sanitize_text(value) if isinstance(value, str) else value
        for key, value in event.items()
    }
    clean_event.setdefault("timestamp", datetime.now(timezone.utc).isoformat())
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(clean_event, ensure_ascii=False) + "\n")
    return path


def build_daily_summary(user_id: str | None, base_dir: str | None = None) -> str:
    user = canonical_user_id(user_id)
    path = daily_dir(user, base_dir) / f"{date.today().isoformat()}.jsonl"
    if not path.exists():
        summary = f"# Kora Learning Daily - {date.today().isoformat()}\n\nNenhum evento de aprendizado registrado hoje.\n"
    else:
        lines = [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
        summary = (
            f"# Kora Learning Daily - {date.today().isoformat()}\n\n"
            f"Usuario: {user}\n\n"
            f"Eventos registrados: {len(lines)}\n\n"
            "Resumo: revisar correcoes, aliases e feedbacks antes de qualquer treino.\n"
        )

    vault_base = Path(os.getenv("KORA_VAULT_DIR") or os.getenv("LIGHTRAG_VAULT_DIR") or "/var/lib/kryonix/vault")
    vault_dir = vault_base / "Kora" / "Learning" / "Daily"
    try:
        vault_dir.mkdir(parents=True, exist_ok=True)
        (vault_dir / f"{date.today().isoformat()}.md").write_text(summary, encoding="utf-8")
    except OSError:
        pass
    return summary
