import re
from typing import List, Optional
from .tool_registry import find_tool

# Keywords that trigger RAG mode
RAG_KEYWORDS = [
    "kryonix", "glacier", "brain", "vault", "obsidian", "repo", "flake",
    "nixosconfigurations", "serviço", "systemd", "decidimos", "documentação",
    "arquitetura atual", "memória", "n8n", "home assistant", "neo4j",
    "lightrag", "graphrag", "configuração atual", "roadmap"
]

# Keywords that suggest direct mode
DIRECT_KEYWORDS = [
    "explique", "resuma", "o que é", "em uma frase", "em 2 linhas",
    "conceito geral", "quem é", "ola", "oi", "bom dia", "boa tarde"
]

def requires_rag(message: str) -> bool:
    """Check if the message needs RAG context based on keywords."""
    message_lower = message.lower()

    # Priority to direct keywords if they appear with simple questions
    if any(k in message_lower for k in DIRECT_KEYWORDS) and not any(k in message_lower for k in RAG_KEYWORDS):
        return False

    return any(k in message_lower for k in RAG_KEYWORDS)

def is_system_state_question(message: str) -> bool:
    """Check if user is asking about the current state of the system."""
    message_lower = message.lower()
    patterns = [
        r"está (rodando|ativo|ligado|on|vivo)",
        r"status (do|de)",
        r"como está",
        r"está funcionando",
        r"qual o estado"
    ]
    return any(re.search(p, message_lower) for p in patterns)

def is_command_request(message: str) -> bool:
    """Check if user wants to execute or learn about a command."""
    message_lower = message.lower()
    return "kryonix" in message_lower or "kora" in message_lower or "rodar" in message_lower or "execute" in message_lower

def validate_command_hallucination(command: str) -> Optional[str]:
    """
    Check if a suggested command exists in the registry.
    Returns None if valid or suggested alternative if invalid.
    """
    tool = find_tool(command)
    if tool:
        return None

    return f"O comando '{command}' não foi encontrado no registry oficial. Por favor, use comandos documentados ou peça um plano de implementação."
