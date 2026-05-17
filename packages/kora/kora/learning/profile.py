from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from .corrections import DEFAULT_CORRECTIONS
from .store import JsonStore, canonical_user_id


def default_profile(user_id: str | None) -> dict[str, Any]:
    canonical = canonical_user_id(user_id)
    return {
        "user_id": canonical,
        "spelling_mappings": dict(DEFAULT_CORRECTIONS),
        "technical_vocabulary": [
            "NixOS",
            "flakes",
            "derivations",
            "Neo4j",
            "LightRAG",
            "Caelestia",
            "Glacier",
            "Inspiron",
            "Kora",
            "Kryonix",
        ],
        "active_projects": ["Kryonix", "Kora"],
        "user_preferences": [
            "Prefere respostas tecnicas, diretas e sem firula",
            "Prefere abordagem local-first e auditavel",
        ],
        "conversational_style": "tecnico, calmo, direto",
        "corrections_history": [],
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }


class LearningProfileStore:
    def __init__(self, base_dir: str | None = None):
        self.store = JsonStore(base_dir)

    def get_profile(self, user_id: str | None) -> dict[str, Any]:
        profile = self.store.load(user_id, "profile.json", default_profile(user_id))
        merged = default_profile(user_id)
        if isinstance(profile, dict):
            for key, value in profile.items():
                if key == "last_updated":
                    continue
                if isinstance(value, dict) and isinstance(merged.get(key), dict):
                    merged[key].update(value)
                elif isinstance(value, list) and isinstance(merged.get(key), list):
                    seen = set(merged[key])
                    merged[key].extend(item for item in value if item not in seen)
                else:
                    merged[key] = value
        return merged

    def save_profile(self, user_id: str | None, profile: dict[str, Any]) -> None:
        self.store.save(user_id, "profile.json", profile)
