# =============================================================================
# Kora — Identity Module
#
# Gerencia a identidade do usuário, perfis persistentes e níveis de permissão.
# =============================================================================

import os
import json
import re
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger("kora.core.identity")

# ── Configuração de Caminhos ─────────────────────────────────────

def _get_base_dir() -> Path:
    base = Path("/var/lib/kryonix")
    if os.access(base.parent, os.W_OK) or base.exists():
        return base
    fallback = Path.home() / ".local/share/kryonix"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback

BASE_DIR = _get_base_dir()
VAULT_USER_DIR = BASE_DIR / "vault/Kora/User"
PROFILE_CACHE_DIR = BASE_DIR / "kora/profile"

# ── Perfis e Modelos ─────────────────────────────────────────────

RAGTON_PROFILE = {
    "id": "ragton",
    "display_name": "Ragton",
    "full_name": "Gabriel Aguiar Rocha",
    "unix_user": "rocha",
    "role": "operador principal do Kryonix",
    "permission_level": "admin_owner",
    "can_execute_readonly": True,
    "can_request_admin_actions": True,
    "can_access_private_memory": True,
    "requires_sudo_for_admin": True,
    "main_project": "Kryonix",
    "interests": ["NixOS", "Linux", "IA local", "RAG", "Neo4j", "Rust", "Python"]
}

KNOWN_USER_TEMPLATE = {
    "id": "known_user",
    "display_name": "Usuário Conhecido",
    "permission_level": "trusted_guest",
    "can_execute_readonly": False,
    "can_request_admin_actions": False,
    "can_access_private_memory": False,
}

UNKNOWN_PROFILE = {
    "id": "unknown",
    "display_name": "Visitante",
    "full_name": "Visitante Desconhecido",
    "unix_user": "unknown",
    "role": "visitante",
    "permission_level": "guest",
    "can_execute_readonly": False,
    "can_request_admin_actions": False,
    "can_access_private_memory": False,
}

# ── Detecção e Resolução ─────────────────────────────────────────

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
    """
    user = runtime.get("user")
    
    # 1. Caso especial: Ragton (rocha)
    if user == "rocha":
        return RAGTON_PROFILE
    
    # 2. Tenta carregar do Vault/Cache
    profile = get_known_user_profile(user)
    if profile:
        return profile
    
    # 3. Fallback: Desconhecido
    return UNKNOWN_PROFILE

def get_known_user_profile(user: str) -> Optional[Dict[str, Any]]:
    """
    Tenta carregar o perfil do usuário do Cache ou Vault.
    """
    # Tenta Cache
    PROFILE_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = PROFILE_CACHE_DIR / f"{user}.json"
    if cache_file.exists():
        try:
            with open(cache_file, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Erro ao ler cache de perfil para {user}: {e}")

    # Tenta Vault
    vault_file = VAULT_USER_DIR / f"{user}.md"
    if vault_file.exists():
        try:
            with open(vault_file, "r") as f:
                content = f.read()
                display_match = re.search(r"display_name:\s*\"?([^\"]+)\"?", content)
                permission_match = re.search(r"permission_level:\s*\"?([^\"]+)\"?", content)
                if display_match:
                    profile = KNOWN_USER_TEMPLATE.copy()
                    profile.update({
                        "id": user,
                        "display_name": display_match.group(1),
                        "unix_user": user,
                        "permission_level": permission_match.group(1) if permission_match else "trusted_guest"
                    })
                    return profile
        except Exception as e:
            logger.error(f"Erro ao ler perfil no Vault para {user}: {e}")

    return None

# ── Checagem de Permissões ───────────────────────────────────────

def can_execute_commands(profile: Dict[str, Any]) -> bool:
    return profile.get("can_execute_readonly", False) or profile.get("permission_level") == "admin_owner"

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
    if profile["id"] == "ragton":
        interests = ", ".join(profile.get("interests", []))
        return (
            f"Bom dia, Ragton.\n\n"
            f"Sim. Você é {profile['full_name']}, operador principal do Kryonix. "
            f"Seu foco é NixOS com Flakes, Linux avançado, infraestrutura, Proxmox, OPNsense, "
            f"IA local, RAG, LightRAG, Neo4j, Ollama, Obsidian, Rust e Python.\n\n"
            f"Eu reconheço esta sessão como autorizada, mas ações administrativas ainda exigem confirmação e autenticação local."
        )
    elif profile["id"] == "unknown":
        return (
            "Olá.\n\n"
            "Ainda não reconheci sua identidade. Posso responder perguntas gerais, "
            "mas não posso acessar memórias privadas nem executar comandos do sistema."
        )
    else:
        return f"Olá, {profile.get('display_name', 'usuário')}. Eu reconheço você como um convidado autorizado do Kryonix."
