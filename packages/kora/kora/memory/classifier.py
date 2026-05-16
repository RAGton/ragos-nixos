import logging
import json
import re
from typing import List, Optional
from .models import MemoryCandidate, MemoryType

logger = logging.getLogger(__name__)

class MemoryClassifier:
    def __init__(self, llm_provider=None):
        self.llm_provider = llm_provider

    # Patterns that MUST NOT be saved to memory
    SECRET_PATTERNS = [
        r"KORA_API_KEY\s*[:=]",
        r"N8N_ENCRYPTION_KEY\s*[:=]",
        r"KORA_N8N_WEBHOOK_TOKEN\s*[:=]",
        r"KRYONIX_BRAIN_API_KEY\s*[:=]",
        r"KRYONIX_BRAIN_KEY\s*[:=]",
        r"TOKEN\s*[:=]",
        r"PASSWORD\s*[:=]",
        r"PASSWD\s*[:=]",
        r"BEGIN\s+OPENSSH\s+PRIVATE\s+KEY",
        r"BEGIN\s+.*PRIVATE\s+KEY",
        r"id_ed25519",
        r"minha\s+senha.*é",
        r"senha\s+é\s*",
        r"minha\s+key.*é",
        r"my\s+password.*is",
        r"my\s+key.*is",
        r"/etc/kryonix/.*\.env",
        r"\.env\s+file",
        r"private\s+key",
        r"secret\s*[:=]",
        r"access_key",
        r"auth_key",
    ]

    def _contains_secrets(self, text: str) -> bool:
        """Check if text contains sensitive patterns."""
        for pattern in self.SECRET_PATTERNS:
            if re.search(pattern, text, re.IGNORECASE):
                return True
        return False

    async def classify(self, user_msg: str, assistant_resp: str, user: str = "unknown") -> List[MemoryCandidate]:
        """
        Analyze conversation to find items worth remembering using LLM.
        """
        # ── Deterministic Guard ──────────────────────────────────────
        if self._contains_secrets(user_msg) or self._contains_secrets(assistant_resp):
            logger.warning("Secret pattern detected in conversation. Blocking memory extraction.")
            return []

        if not self.llm_provider:
            return []

        try:
            prompt = self.get_extraction_prompt(user_msg, assistant_resp)
            response = await self.llm_provider.generate(
                prompt=prompt,
                system_prompt="Você é um classificador de memória para a Kora. Retorne apenas JSON.",
            )

            # Clean possible markdown blocks
            clean_resp = response.strip()
            if clean_resp.startswith("```"):
                clean_resp = re.sub(r"```json\s*", "", clean_resp)
                clean_resp = re.sub(r"```\s*", "", clean_resp)

            data = json.loads(clean_resp)
            candidates = []
            if isinstance(data, list):
                for item in data:
                    candidates.append(MemoryCandidate(
                        type=MemoryType(item.get("type", "idea")),
                        title=item.get("title", "Sem título"),
                        summary=item.get("summary", ""),
                        content=item.get("content", ""),
                        tags=item.get("tags", []),
                        confidence=item.get("confidence", 0.5),
                        sensitivity=item.get("sensitivity", "low"),
                        source_msg=user_msg,
                        user=user
                    ))
            return candidates
        except Exception as e:
            logger.error("Failed to extract memories: %s", e)
            return []

    def get_extraction_prompt(self, user_msg: str, assistant_resp: str) -> str:
        """Prompt to extract memories from a conversation exchange."""
        return f"""Analise a seguinte troca de mensagens entre um usuário e a assistente Kora e identifique informações que devem ser salvas na memória persistente (Obsidian Vault).

Usuário: {user_msg}
Kora: {assistant_resp}

Tipos de memória:
- idea: ideias novas, projetos futuros, insights.
- decision: decisões técnicas, arquitetura aprovada, escolhas de design.
- preference: preferências do usuário, estilo de escrita, ferramentas favoritas.
- task: tarefas pendentes ou planos de ação.
- user_profile: informações sobre quem é o usuário.

Regras:
1. NÃO salve segredos, senhas, tokens ou chaves API.
2. Identifique apenas informações de ALTA confiança e utilidade futura.
3. Se não houver nada relevante, retorne uma lista vazia.
4. Retorne APENAS um JSON válido no formato:
[
  {{
    "type": "idea|decision|preference|task|user_profile",
    "title": "Título curto e descritivo",
    "summary": "Resumo executivo",
    "content": "Conteúdo detalhado",
    "tags": ["tag1", "tag2"],
    "confidence": 0.0-1.0,
    "sensitivity": "low|medium|high"
  }}
]
"""
