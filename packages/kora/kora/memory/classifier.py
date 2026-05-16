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
        r"KORA_API_KEY\s*=",
        r"N8N_ENCRYPTION_KEY\s*=",
        r"KORA_N8N_WEBHOOK_TOKEN\s*=",
        r"KRYONIX_BRAIN_API_KEY\s*=",
        r"KRYONIX_BRAIN_KEY\s*=",
        r"TOKEN\s*=",
        r"PASSWORD\s*=",
        r"PASSWD\s*=",
        r"BEGIN\s+OPENSSH\s+PRIVATE\s+KEY",
        r"BEGIN\s+.*PRIVATE\s+KEY",
        r"id_ed25519",
        r"minha\s+senha\s+é",
        r"senha\s+é\s*",
        r"/etc/kryonix/.*\.env",
        r"\.env\s+file",
        r"private\s+key",
        r"secret\s*=",
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
        Analyze conversation to find items worth remembering.
        """
        # ── Deterministic Guard ──────────────────────────────────────
        if self._contains_secrets(user_msg) or self._contains_secrets(assistant_resp):
            logger.warning("Secret pattern detected in conversation. Blocking memory extraction.")
            return []

        # This is a placeholder for the logic that will be executed.
        # The orchestrator will likely handle the LLM call and pass the results here
        # or this module will define the prompt for the orchestrator to use.
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
