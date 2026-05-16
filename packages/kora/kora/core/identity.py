# =============================================================================
# Kora — Identity Module
#
# Gerencia a identidade do usuário, perfis persistentes e estado de saudação.
# =============================================================================

import os
import json
import re
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger("kora.core.identity")

# Caminhos canônicos com fallback para ambiente de desenvolvimento/teste
def _get_base_dir() -> Path:
    base = Path("/var/lib/kryonix")
    if os.access(base.parent, os.W_OK) or base.exists():
        return base
    # Fallback para home do usuário se /var/lib não for acessível
    fallback = Path.home() / ".local/share/kryonix"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback

BASE_DIR = _get_base_dir()
SESSIONS_DIR = BASE_DIR / "kora/sessions"
VAULT_USER_DIR = BASE_DIR / "vault/Kora/User"
PROFILE_CACHE_DIR = BASE_DIR / "kora/profile"

# Perfil padrão para o criador (Ragton)
RAGTON_PROFILE = {
    "display_name": "Ragton",
    "full_name": "Gabriel Aguiar Rocha",
    "unix_user": "rocha",
    "role": "técnico/sysadmin e estudante de Sistemas de Informação",
    "main_project": "Kryonix",
    "preferences": [
        "PT-BR",
        "respostas diretas, técnicas e práticas",
        "NixOS declarativo com Flakes",
        "comandos prontos",
        "segurança antes de automação"
    ],
    "interests": [
        "Linux avançado",
        "NixOS",
        "Proxmox",
        "OPNsense",
        "IA local",
        "Ollama",
        "RAG",
        "LightRAG",
        "Neo4j",
        "Obsidian",
        "Rust",
        "Python"
    ]
}

def detect_runtime_identity() -> Dict[str, Any]:
    """
    Detecta informações do ambiente de execução.
    """
    return {
        "user": os.environ.get("USER") or os.environ.get("LOGNAME") or "unknown",
        "hostname": os.uname().nodename,
        "ssh": "SSH_CONNECTION" in os.environ,
        "timestamp": datetime.now().isoformat()
    }

def get_known_user_profile(user: str) -> Optional[Dict[str, Any]]:
    """
    Retorna o perfil do usuário se ele for reconhecido.
    Tenta:
    1. Mapeamento estático (Ragton)
    2. Cache em JSON em PROFILE_CACHE_DIR
    3. Perfil no Vault (Markdown/JSON)
    """
    # 1. Mapeamento estático prioritário
    if user == "rocha":
        return RAGTON_PROFILE
    
    # 2. Tenta carregar do cache JSON
    PROFILE_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = PROFILE_CACHE_DIR / f"{user}.json"
    if cache_file.exists():
        try:
            with open(cache_file, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Erro ao ler cache de perfil para {user}: {e}")

    # 3. Tenta carregar do Vault
    vault_file = VAULT_USER_DIR / f"{user}.md"
    if vault_file.exists():
        # Por enquanto, uma lógica simples de parsing de metadados se existir
        # Futuramente: usar um parser de frontmatter real
        try:
            with open(vault_file, "r") as f:
                content = f.read()
                # Tenta extrair display_name: "Valor"
                display_match = re.search(r"display_name:\s*\"?([^\"]+)\"?", content)
                full_name_match = re.search(r"full_name:\s*\"?([^\"]+)\"?", content)
                if display_match:
                    return {
                        "display_name": display_match.group(1),
                        "full_name": full_name_match.group(1) if full_name_match else user,
                        "unix_user": user,
                        "role": "Usuário Kryonix",
                        "preferences": ["PT-BR"],
                        "interests": []
                    }
        except Exception as e:
            logger.error(f"Erro ao ler perfil no Vault para {user}: {e}")

    return None

def is_known_admin(user: str) -> bool:
    """
    Verifica se o usuário é um administrador conhecido (Ragton).
    """
    return user == "rocha"

def should_greet(session_id: str, user: str) -> bool:
    """
    Verifica se devemos saudar o usuário nesta sessão.
    Usa persistência em disco para sobreviver a restarts do processo.
    """
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    session_file = SESSIONS_DIR / f"{session_id}.json"
    
    if not session_file.exists():
        # Nova sessão
        save_session_state(session_id, user, greeted=True)
        return True
    
    try:
        with open(session_file, "r") as f:
            state = json.load(f)
            if state.get("user") != user:
                # Mudou o usuário na mesma sessão? Saudar novamente.
                save_session_state(session_id, user, greeted=True)
                return True
            return not state.get("greeted", False)
    except Exception as e:
        logger.error(f"Erro ao ler estado da sessão: {e}")
        return True

def save_session_state(session_id: str, user: str, greeted: bool):
    """
    Salva o estado da sessão.
    """
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    session_file = SESSIONS_DIR / f"{session_id}.json"
    state = {
        "session_id": session_id,
        "user": user,
        "greeted": greeted,
        "last_seen": datetime.now().isoformat()
    }
    try:
        with open(session_file, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        logger.error(f"Erro ao salvar estado da sessão: {e}")

def get_greeting(profile: Optional[Dict[str, Any]]) -> str:
    """
    Gera uma saudação amigável baseada no horário e perfil.
    """
    now = datetime.now()
    if 5 <= now.hour < 12:
        base = "Bom dia"
    elif 12 <= now.hour < 18:
        base = "Boa tarde"
    else:
        base = "Boa noite"
    
    name = profile.get("display_name") if profile else None
    if name:
        return f"{base}, {name}."
    return f"{base}!"

def is_identity_query(message: str) -> bool:
    """
    Detecta se a mensagem é uma pergunta sobre a identidade do usuário.
    """
    message_lower = message.lower()
    
    # Se perguntar quem é a Kora, NÃO interceptar (deixar o LLM responder)
    if re.search(r"quem (é você|vc é|é a kora)", message_lower):
        return False

    patterns = [
        r"quem sou eu",
        r"vc sabe quem (eu )?sou eu",
        r"você sabe quem (eu )?sou eu",
        r"o que (você )?(sabe|lembra) de mim",
        r"qual (é )?meu perfil",
        r"você me conhece",
        r"me identifique",
        r"quem está digitando"
    ]
    for p in patterns:
        if re.search(p, message_lower):
            return True
    return False

def get_identity_response(profile: Dict[str, Any]) -> str:
    """
    Gera a resposta determinística para perguntas de identidade.
    """
    greeting = get_greeting(profile)
    interests = ", ".join(profile.get("interests", []))
    
    return (
        f"{greeting}\n\n"
        f"Sim. Você é {profile['full_name']}, usa o usuário `{profile['unix_user']}` no Kryonix "
        f"e está construindo o Kryonix como sua plataforma NixOS local.\n\n"
        f"Eu lembro que seu foco principal é {profile.get('main_project', 'o Kryonix')} e você tem interesse em: {interests}."
    )
