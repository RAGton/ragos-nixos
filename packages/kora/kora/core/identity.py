import os
import json
import re
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional
from .users import UserRegistry, KoraUser

logger = logging.getLogger("kora.core.identity")

from enum import Enum

class IdentityTrust(str, Enum):
    HINT = "hint"                 # Claimed via environment/session without proof
    VERIFIED = "verified"         # Authenticated via session token or secure local channel
    SECURE = "secure"             # Strong MFA, physical key, or biometrics

class PermissionSource(str, Enum):
    ENVIRONMENT = "environment"   # Inherited from client environment claim (weak)
    AUTH_TOKEN = "auth_token"     # Cryptographic token verification (medium)
    BIOMETRICS = "biometrics"     # Speaker ID / Face ID (strong)
    SUDO_GATE = "sudo_gate"       # Elevating via local Unix polkit / sudo (strongest)

# ── Configuração de Caminhos ─────────────────────────────────────

def _get_base_dir() -> Path:
    base = Path("/var/lib/kryonix")
    if os.access(base.parent, os.W_OK) or base.exists():
        return base
    fallback = Path.home() / ".local/share/kryonix"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback

BASE_DIR = _get_base_dir()

def detect_runtime_identity() -> Dict[str, Any]:
    """
    Detecta informações do ambiente de execução.
    """
    return {
        "user": os.environ.get("USER") or os.environ.get("LOGNAME") or "unknown",
        "hostname": os.uname().nodename,
        "ssh": "SSH_CONNECTION" in os.environ,
        "tty": os.isatty(0) if hasattr(os, "isatty") else False,
        "timestamp": datetime.now().isoformat()
    }

def resolve_identity(runtime: Dict[str, Any]) -> Dict[str, Any]:
    """
    Resolve a identidade baseada no contexto de execução e perfis conhecidos.
    Retorna um dicionário com trust boundary explícito.
    """
    linux_user = runtime.get("user")
    registry = UserRegistry()

    # Identidade padrão para visitantes / desconhecidos
    guest_profile = {
        "id": "unknown",
        "display_name": "Visitante",
        "full_name": "Visitante Desconhecido",
        "linux_user": linux_user,
        "role": "visitante",
        "permission_level": "guest",
        "can_execute_readonly": False,
        "can_request_admin_actions": False,
        "can_access_private_memory": False,
        "preferences": []
    }

    user = registry.find_by_linux_user(linux_user)
    if user:
        return {
            "client_claimed_user": linux_user,
            "resolved_identity": user.to_dict(),
            "identity_trust": IdentityTrust.HINT.value,
            "permission_source": PermissionSource.ENVIRONMENT.value
        }

    return {
        "client_claimed_user": linux_user,
        "resolved_identity": guest_profile,
        "identity_trust": IdentityTrust.HINT.value,
        "permission_source": PermissionSource.ENVIRONMENT.value
    }

# ── Checagem de Permissões ───────────────────────────────────────

def can_execute_commands(profile: Dict[str, Any]) -> bool:
    return profile.get("permission_level") == "admin_owner" or profile.get("can_request_commands", False)

def can_request_admin_actions(profile: Dict[str, Any]) -> bool:
    return profile.get("can_request_admin_actions", False)

def can_access_private_memory(profile: Dict[str, Any]) -> bool:
    return profile.get("can_access_private_memory", False)

# ── Interceptação de Query ───────────────────────────────────────

def is_identity_query(message: str) -> bool:
    """
    Detecta se a mensagem é uma pergunta sobre a identidade do usuário.
    """
    message_lower = message.lower()

    if re.search(r"quem (é você|vc é|é a kora)", message_lower):
        return False

    patterns = [
        r"quem sou eu",
        r"vc sabe quem (eu )?sou eu",
        r"você sabe quem (eu )?sou eu",
        r"o que (você )?(sabe|lembra) de mim",
        r"qual (é )?meu perfil",
        r"você me conhece",
        r"quem está (digitando|falando)"
    ]
    for p in patterns:
        if re.search(p, message_lower):
            return True
    return False

def get_identity_response(profile: Dict[str, Any]) -> str:
    """
    Gera a resposta determinística para perguntas de identidade.
    """
    user_id = profile.get("id")
    display_name = profile.get("display_name", "usuário")

    if user_id == "ragton":
        return (
            f"Bom dia, Ragton.\n\n"
            f"Sim. Você é Gabriel Aguiar Rocha, operador principal do Kryonix. "
            f"Seu foco é NixOS com Flakes, Linux avançado, infraestrutura, Proxmox, OPNsense, "
            f"IA local, RAG, LightRAG, Neo4j, Ollama, Obsidian, Rust e Python.\n\n"
            f"Eu reconheço esta sessão como autorizada, mas ações administrativas ainda exigem confirmação e autenticação local."
        )
    elif user_id == "nicoly":
        return (
            f"Olá, Nicoly.\n\n"
            f"Eu reconheço você como uma parceira de confiança do Kryonix. "
            f"Posso conversar e ajudar com tarefas do dia a dia, mas não tenho permissão para "
            f"acessar as memórias privadas do Ragton ou executar comandos do sistema nesta sessão."
        )
    elif user_id == "unknown":
        return (
            "Olá.\n\n"
            "Ainda não reconheci sua identidade. Posso responder perguntas gerais, "
            "mas não posso acessar memórias privadas nem executar comandos do sistema."
        )
    else:
        return f"Olá, {display_name}. Eu reconheço você como um convidado autorizado do Kryonix."

def should_greet(profile: Dict[str, Any]) -> bool:
    """
    Define se a Kora deve iniciar com uma saudação personalizada.
    """
    return profile.get("id") != "unknown"
