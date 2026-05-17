from __future__ import annotations

import json
import logging
import re
from typing import Any

from kora.llm.ollama import OllamaAdapter

from .corrections import CorrectionsStore
from .daily import build_daily_summary, write_daily_event
from .privacy import contains_secret
from .profile import LearningProfileStore
from .store import canonical_user_id, resolve_learning_dir

logger = logging.getLogger("kora.learning")


class LearningEngine:
    def __init__(self, learning_dir: str | None = None):
        self.learning_dir = resolve_learning_dir(learning_dir)
        self.profile_store = LearningProfileStore(str(self.learning_dir))
        self.corrections_store = CorrectionsStore(str(self.learning_dir))
        self.llm = OllamaAdapter()

    def get_profile(self, user_id: str) -> dict[str, Any]:
        return self.profile_store.get_profile(user_id)

    def save_profile(self, user_id: str, profile: dict[str, Any]) -> None:
        self.profile_store.save_profile(user_id, profile)
        corrections = profile.get("spelling_mappings")
        if isinstance(corrections, dict):
            self.corrections_store.save_corrections(user_id, corrections)

    def correct_transcription(self, text: str, user_id: str) -> str:
        return self.corrections_store.apply(text, user_id).text

    def add_correction(self, user_id: str, wrong: str, right: str) -> None:
        self.corrections_store.add_correction(user_id, wrong, right)
        profile = self.get_profile(user_id)
        profile.setdefault("spelling_mappings", {})[wrong.strip().lower()] = right.strip()
        self.save_profile(user_id, profile)

    def add_alias(self, user_id: str, expression: str, meaning: str) -> None:
        self.corrections_store.add_alias(user_id, expression, meaning)

    def get_corrections(self, user_id: str) -> dict[str, str]:
        return self.corrections_store.get_corrections(user_id)

    def get_aliases(self, user_id: str) -> dict[str, str]:
        return self.corrections_store.get_aliases(user_id)

    def daily_summary(self, user_id: str) -> str:
        return build_daily_summary(user_id, str(self.learning_dir))

    def _should_trigger_learning(self, user_msg: str) -> bool:
        msg_lower = user_msg.lower()
        triggers = [
            "transcreveu errado",
            "digitou errado",
            "escreveu errado",
            "não é isso",
            "nao e isso",
            "eu disse",
            "o correto é",
            "o correto e",
            "quis dizer",
            "eu prefiro",
            "gosto de",
            "não gosto de",
            "nao gosto de",
            "deixe mais",
            "mude o tom",
            "responda de forma",
            "estou trabalhando",
            "estou configurando",
            "estou fazendo",
            "novo projeto",
            "meu projeto",
        ]
        return any(trigger in msg_lower for trigger in triggers)

    async def learn_from_turn(self, user_msg: str, assistant_resp: str, user_id: str) -> None:
        if not user_id or user_id == "unknown":
            return
        if contains_secret(user_msg) or contains_secret(assistant_resp):
            logger.warning("Secret pattern detected. Blocking Kora learning extraction.")
            return
        if not self._should_trigger_learning(user_msg):
            return

        prompt = f"""Analise a troca abaixo e extraia apenas aprendizado util para a Kora.

Usuario: {user_msg}
Kora: {assistant_resp}

Retorne somente JSON:
{{
  "spelling_mappings": {{}},
  "new_vocabulary": [],
  "active_projects": [],
  "preferences": []
}}
"""
        try:
            raw_response = await self.llm.generate(
                prompt="Extraia aprendizado em JSON.",
                system_prompt=prompt,
            )
            raw_response = raw_response.strip()
            match = re.search(r"```json\s*(\{.*?\})\s*```", raw_response, re.DOTALL)
            if match:
                raw_response = match.group(1)
            elif raw_response.startswith("```") and raw_response.endswith("```"):
                raw_response = raw_response.strip("`").strip()

            data = json.loads(raw_response)
            profile = self.get_profile(user_id)
            modified = False

            for wrong, right in data.get("spelling_mappings", {}).items():
                key = str(wrong).strip().lower()
                value = str(right).strip()
                if key and value and profile.setdefault("spelling_mappings", {}).get(key) != value:
                    profile["spelling_mappings"][key] = value
                    self.corrections_store.add_correction(user_id, key, value)
                    modified = True

            for source_key, target_key in [
                ("new_vocabulary", "technical_vocabulary"),
                ("active_projects", "active_projects"),
                ("preferences", "user_preferences"),
            ]:
                for item in data.get(source_key, []):
                    item = str(item).strip()
                    if item and item not in profile.setdefault(target_key, []):
                        profile[target_key].append(item)
                        modified = True

            if modified:
                self.save_profile(user_id, profile)
                write_daily_event(
                    user_id,
                    {
                        "type": "learning_update",
                        "user_id": canonical_user_id(user_id),
                        "source": "conversation",
                        "summary": "Perfil atualizado por gatilho de aprendizado.",
                    },
                    str(self.learning_dir),
                )
        except Exception as exc:
            logger.error("Erro ao processar aprendizado cognitivo: %s", exc)


__all__ = ["LearningEngine", "canonical_user_id"]
