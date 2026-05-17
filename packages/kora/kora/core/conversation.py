# =============================================================================
# Kora — Conversation Memory (Short-term Voice Sessions)
#
# Persiste turnos da conversa por voz para manter contexto entre falas.
# Cada sessão acumula até MAX_TURNS turnos recentes.
# Armazenado em /var/lib/kryonix/kora/sessions/voice-current.json
# =============================================================================

from __future__ import annotations

import json
import logging
import re
import time
from pathlib import Path
from typing import Any, Optional

logger = logging.getLogger("kora.core.conversation")

SESSIONS_DIR = Path("/var/lib/kryonix/kora/sessions")
VOICE_SESSION_FILE = SESSIONS_DIR / "voice-current.json"
MAX_TURNS = 12  # keep last 12 turns (6 exchanges)

# ── Patterns that indicate the user is complaining about prior answer ────────
_FOLLOWUP_PATTERNS = [
    r"voc[eê] n[aã]o respond",
    r"n[aã]o respondeu",
    r"ignorou",
    r"esqueceu",
    r"eu perguntei outra coisa",
    r"lembra o que.*falei",
    r"lembra.*minha.*pergunta",
    r"n[aã]o completou",
    r"responda.*completa",
    r"faltou responder",
    r"minha pergunta anterior",
]

_COMPILED_PATTERNS = [re.compile(p, re.IGNORECASE) for p in _FOLLOWUP_PATTERNS]


def _ensure_dir() -> None:
    try:
        SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass


def _load_session() -> dict:
    if VOICE_SESSION_FILE.exists():
        try:
            return json.loads(VOICE_SESSION_FILE.read_text("utf-8"))
        except Exception:
            pass
    return {
        "session_id": f"voice-{int(time.time())}",
        "speaker": "unknown",
        "turns": [],
        "updated_at": time.time(),
    }


def _save_session(session: dict) -> None:
    _ensure_dir()
    session["updated_at"] = time.time()
    try:
        VOICE_SESSION_FILE.write_text(
            json.dumps(session, indent=2, ensure_ascii=False), encoding="utf-8"
        )
    except OSError as e:
        logger.warning(f"Não foi possível salvar sessão de voz: {e}")


def append_turn(
    user_text: str,
    assistant_text: str,
    intent: str = "general_chat",
    metadata: dict | None = None,
) -> None:
    """Adiciona um turno à sessão atual de voz."""
    session = _load_session()
    turn = {
        "user": user_text,
        "kora": assistant_text,
        "intent": intent,
        "ts": time.time(),
    }
    if metadata:
        turn["meta"] = metadata
    session["turns"].append(turn)

    # Trim to MAX_TURNS
    if len(session["turns"]) > MAX_TURNS:
        session["turns"] = session["turns"][-MAX_TURNS:]

    _save_session(session)


def get_recent_turns(limit: int = 8) -> list[dict]:
    """Retorna os últimos N turnos da sessão."""
    session = _load_session()
    return session["turns"][-limit:]


def get_last_user_turn() -> str | None:
    """Retorna a última pergunta feita pelo usuário."""
    session = _load_session()
    if session["turns"]:
        return session["turns"][-1].get("user")
    return None

def get_last_assistant_turn() -> str | None:
    """Retorna a última resposta da Kora."""
    session = _load_session()
    if session["turns"]:
        return session["turns"][-1].get("kora")
    return None

def get_last_unanswered_or_partial_turn() -> str | None:
    """Retorna o último turno que provavelmente ficou parcial (fallback to last)."""
    return get_last_user_turn()


def detect_followup_complaint(text: str) -> bool:
    """Detecta se o usuário está reclamando de resposta incompleta."""
    for pattern in _COMPILED_PATTERNS:
        if pattern.search(text):
            return True
    return False


def format_history_for_prompt(limit: int = 4) -> str:
    """Formata o histórico recente como contexto para o LLM."""
    turns = get_recent_turns(limit)
    if not turns:
        return ""

    lines = ["## Histórico recente desta conversa por voz\n"]
    for i, turn in enumerate(turns, 1):
        lines.append(f"**Turno {i}:**")
        lines.append(f"- Usuário: {turn['user']}")
        lines.append(f"- Kora: {turn['kora']}")
        lines.append("")

    return "\n".join(lines)


def build_followup_context(current_text: str) -> str:
    """
    Se o usuário está reclamando de resposta incompleta,
    retorna contexto extra com a pergunta anterior para injetar no prompt.
    """
    if not detect_followup_complaint(current_text):
        return ""

    last_q = get_last_user_turn()
    if not last_q:
        return ""

    return (
        "\n\n## ATENÇÃO — Reclamação de resposta incompleta\n"
        "O usuário está dizendo que a resposta anterior foi incompleta ou ignorou parte da pergunta.\n"
        f"A pergunta anterior do usuário foi:\n\n> {last_q}\n\n"
        "INSTRUÇÃO: Recupere esta pergunta, liste as partes dela, explique rapidamente que vai completar "
        "a resposta e então forneça todas as informações que faltaram."
    )


def clear_session() -> None:
    """Limpa a sessão atual."""
    if VOICE_SESSION_FILE.exists():
        VOICE_SESSION_FILE.unlink()
