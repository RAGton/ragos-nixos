from __future__ import annotations

import re
from dataclasses import dataclass, field

from kora.learning import LearningEngine, canonical_user_id

ANSI_RE = re.compile(
    r"(?:\x1b|\\x1b|\\033|\\u001b)\[[0-9;?]*[A-Za-z]"
    r"|\[[0-9]+(?:;[0-9]+)*m"
    r"|(?:\b|;)[0-9]+;[0-9]+(?:;[0-9]+)*m"
)
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


@dataclass
class NormalizedText:
    original: str
    normalized: str
    corrections_applied: dict[str, str] = field(default_factory=dict)
    aliases_detected: dict[str, str] = field(default_factory=dict)
    user_id: str = "unknown"

    def to_dict(self) -> dict:
        return {
            "original": self.original,
            "normalized": self.normalized,
            "corrections_applied": self.corrections_applied,
            "aliases_detected": self.aliases_detected,
            "user_id": self.user_id,
        }


def clean_text(text: str) -> str:
    clean = ANSI_RE.sub("", text or "")
    clean = CONTROL_RE.sub("", clean)
    return " ".join(clean.split()).strip()


def _polish_kora_terms(text: str) -> str:
    replacements = {
        r"\bkora\b": "Kora",
        r"\bkryonix\b": "Kryonix",
        r"\bglacier\b": "Glacier",
        r"\binspiron\b": "Inspiron",
        r"\bnixos\b": "NixOS",
        r"\bobsidian\b": "Obsidian",
    }
    polished = text
    for pattern, replacement in replacements.items():
        polished = re.sub(pattern, replacement, polished, flags=re.IGNORECASE)
    return polished


def normalize_text(text: str, user_id: str | None = None) -> NormalizedText:
    original = text or ""
    clean = clean_text(original)
    canonical = canonical_user_id(user_id)

    engine = LearningEngine()
    corrections_store = engine.corrections_store
    correction_result = corrections_store.apply(clean, canonical)
    normalized = _polish_kora_terms(correction_result.text)

    aliases_detected: dict[str, str] = {}
    lowered = normalized.lower()
    for expression, meaning in corrections_store.get_aliases(canonical).items():
        if expression.lower() in lowered:
            aliases_detected[expression] = meaning

    return NormalizedText(
        original=original,
        normalized=normalized,
        corrections_applied=correction_result.corrections_applied,
        aliases_detected=aliases_detected,
        user_id=canonical,
    )
