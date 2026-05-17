from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from kora.learning.privacy import sanitize_text
from kora.learning.store import canonical_user_id

DEFAULT_TRAINING_DIR = Path("/var/lib/kryonix/kora/training")
FALLBACK_TRAINING_DIR = Path.home() / ".local/share/kryonix/kora/training"


def resolve_training_dir(base_dir: str | None = None) -> Path:
    if base_dir:
        base = Path(base_dir)
    elif os.getenv("KORA_TRAINING_DIR"):
        base = Path(os.environ["KORA_TRAINING_DIR"])
    else:
        base = DEFAULT_TRAINING_DIR
    try:
        base.mkdir(parents=True, exist_ok=True)
        (base / "exports").mkdir(parents=True, exist_ok=True)
        return base
    except OSError:
        FALLBACK_TRAINING_DIR.mkdir(parents=True, exist_ok=True)
        (FALLBACK_TRAINING_DIR / "exports").mkdir(parents=True, exist_ok=True)
        return FALLBACK_TRAINING_DIR


class TrainingStore:
    def __init__(self, base_dir: str | None = None):
        self.base_dir = resolve_training_dir(base_dir)
        self.events_path = self.base_dir / "events.jsonl"

    def append_event(self, event: dict[str, Any]) -> Path:
        clean_event = self._sanitize_event(event)
        clean_event.setdefault("timestamp", datetime.now(timezone.utc).isoformat())
        with self.events_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(clean_event, ensure_ascii=False) + "\n")
        return self.events_path

    def list_events(self) -> list[dict[str, Any]]:
        if not self.events_path.exists():
            return []
        events = []
        for line in self.events_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        return events

    def set_feedback(self, feedback: str, reason: str | None = None) -> dict[str, Any] | None:
        events = self.list_events()
        if not events:
            return None
        events[-1]["user_feedback"] = feedback
        if reason:
            events[-1]["feedback_reason"] = sanitize_text(reason)
        self._rewrite_events(events)
        return events[-1]

    def export_sft(self) -> Path:
        path = self.base_dir / "exports" / "sft.jsonl"
        with path.open("w", encoding="utf-8") as handle:
            for event in self.list_events():
                if not event.get("answer"):
                    continue
                row = {
                    "instruction": event.get("normalized_text") or event.get("original_text"),
                    "response": event.get("answer"),
                    "metadata": {
                        "user_id": event.get("user_id"),
                        "source": event.get("source"),
                        "intent": event.get("intent"),
                        "feedback": event.get("user_feedback"),
                    },
                }
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")
        return path

    def export_dpo(self) -> Path:
        path = self.base_dir / "exports" / "dpo.jsonl"
        with path.open("w", encoding="utf-8") as handle:
            for event in self.list_events():
                feedback = event.get("user_feedback")
                if feedback not in {"good", "bad"}:
                    continue
                answer = event.get("answer", "")
                if feedback == "good":
                    chosen = answer
                    rejected = ""
                else:
                    chosen = ""
                    rejected = answer
                row = {
                    "prompt": event.get("normalized_text") or event.get("original_text"),
                    "chosen": chosen,
                    "rejected": rejected,
                    "metadata": {
                        "reason": event.get("feedback_reason"),
                        "intent": event.get("intent"),
                    },
                }
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")
        return path

    def status(self) -> dict[str, Any]:
        events = self.list_events()
        return {
            "events_path": str(self.events_path),
            "events": len(events),
            "exports_dir": str(self.base_dir / "exports"),
        }

    def _rewrite_events(self, events: list[dict[str, Any]]) -> None:
        tmp = self.events_path.with_suffix(".jsonl.tmp")
        with tmp.open("w", encoding="utf-8") as handle:
            for event in events:
                handle.write(json.dumps(self._sanitize_event(event), ensure_ascii=False) + "\n")
        tmp.replace(self.events_path)

    def _sanitize_event(self, event: dict[str, Any]) -> dict[str, Any]:
        clean = {}
        for key, value in event.items():
            if isinstance(value, str):
                clean[key] = sanitize_text(value)
            else:
                clean[key] = value
        if "user_id" in clean:
            clean["user_id"] = canonical_user_id(str(clean["user_id"]))
        return clean


def record_interaction(
    *,
    user_id: str,
    source: str,
    original_text: str,
    normalized_text: str,
    intent: str,
    answer: str,
    quality_score: float | None = None,
    used_rag: bool = False,
    used_tool: bool = False,
) -> None:
    store = TrainingStore()
    store.append_event(
        {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "user_id": canonical_user_id(user_id),
            "source": source,
            "original_text": original_text,
            "normalized_text": normalized_text,
            "intent": intent,
            "answer": answer,
            "user_feedback": None,
            "quality_score": quality_score,
            "used_rag": used_rag,
            "used_tool": used_tool,
        }
    )
