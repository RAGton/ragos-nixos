# =============================================================================
# Kora — Audit Events
#
# Registra ações e eventos da Kora em log estruturado (JSONL).
# Essencial para rastreabilidade, debugging e memória de raciocínio futura.
#
# Não registrar secrets. Não registrar conteúdo sensível sem classificação.
# =============================================================================

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from ..core.config import KORA_AUDIT_DIR

logger = logging.getLogger("kora.audit")


def log_event(
    event_type: str,
    description: str,
    metadata: dict[str, Any] | None = None,
    risk: str = "read_only",
) -> None:
    """
    Log a structured event to the audit log.

    Args:
        event_type: Category (chat, search, action, error, system).
        description: Human-readable description.
        metadata: Additional context (never include secrets).
        risk: Risk level (read_only, low, medium, high, destructive).
    """
    try:
        KORA_AUDIT_DIR.mkdir(parents=True, exist_ok=True)
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "type": event_type,
            "description": description,
            "risk": risk,
            "metadata": metadata or {},
        }
        log_file = KORA_AUDIT_DIR / f"events-{datetime.now().strftime('%Y-%m')}.jsonl"
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception as e:
        logger.error("Failed to write audit event: %s", e)
