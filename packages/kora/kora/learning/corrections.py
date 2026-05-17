from __future__ import annotations

import re
from dataclasses import dataclass

from .store import JsonStore

DEFAULT_CORRECTIONS = {
    "niques": "NixOS",
    "hyperland": "Hyprland",
    "hiperland": "Hyprland",
    "celetial": "Caelestia",
    "celestial": "Caelestia",
    "glacie": "Glacier",
    "pentifino": "pente fino",
    "siwtch": "switch",
    "insopiron": "Inspiron",
    "obsiuabn": "Obsidian",
    "conmando": "comando",
    "assitente": "assistente",
    "n": "não",
    "ta": "está",
    "ne": "né",
}

DEFAULT_ALIASES = {
    "pente fino": "auditoria técnica detalhada e crítica",
    "no nosso cenario": "adaptar para Kryonix/NixOS/local-first",
    "tipo Jarvis": "assistente pessoal local com voz, memoria, ferramentas e seguranca",
}


@dataclass
class CorrectionResult:
    text: str
    corrections_applied: dict[str, str]


class CorrectionsStore:
    def __init__(self, base_dir: str | None = None):
        self.store = JsonStore(base_dir)

    def get_corrections(self, user_id: str | None) -> dict[str, str]:
        data = self.store.load(user_id, "corrections.json", {})
        merged = dict(DEFAULT_CORRECTIONS)
        merged.update({str(k): str(v) for k, v in data.items() if k != "last_updated"})
        return merged

    def save_corrections(self, user_id: str | None, corrections: dict[str, str]) -> None:
        self.store.save(user_id, "corrections.json", corrections)

    def add_correction(self, user_id: str | None, wrong: str, right: str) -> None:
        corrections = self.get_corrections(user_id)
        corrections[wrong.strip().lower()] = right.strip()
        self.save_corrections(user_id, corrections)

    def get_aliases(self, user_id: str | None) -> dict[str, str]:
        data = self.store.load(user_id, "aliases.json", {})
        merged = dict(DEFAULT_ALIASES)
        merged.update({str(k): str(v) for k, v in data.items() if k != "last_updated"})
        return merged

    def save_aliases(self, user_id: str | None, aliases: dict[str, str]) -> None:
        self.store.save(user_id, "aliases.json", aliases)

    def add_alias(self, user_id: str | None, expression: str, meaning: str) -> None:
        aliases = self.get_aliases(user_id)
        aliases[expression.strip()] = meaning.strip()
        self.save_aliases(user_id, aliases)

    def apply(self, text: str, user_id: str | None) -> CorrectionResult:
        corrected = text or ""
        applied: dict[str, str] = {}
        for wrong, right in self.get_corrections(user_id).items():
            if not wrong:
                continue
            pattern = re.compile(rf"\b{re.escape(wrong)}\b", re.IGNORECASE)
            if pattern.search(corrected):
                corrected = pattern.sub(right, corrected)
                applied[wrong] = right
        return CorrectionResult(text=corrected, corrections_applied=applied)
