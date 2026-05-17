from __future__ import annotations

from typing import Any

MAX_HISTORY_TURNS = 6
MAX_PROFILE_CHARS = 1800
MAX_CONTEXT_CHARS = 5000


def _clip(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[: limit - 20].rstrip() + "\n[contexto truncado]"


def format_history(turns: list[dict[str, Any]], limit: int = MAX_HISTORY_TURNS) -> str:
    if not turns:
        return ""

    lines: list[str] = []
    for turn in turns[-limit:]:
        user = str(turn.get("user", "")).strip()
        kora = str(turn.get("kora", "")).strip()
        if user:
            lines.append(f"Usuario: {user}")
        if kora:
            lines.append(f"Kora: {kora}")
    return "\n".join(lines)


def build_mind_context(
    *,
    user_id: str,
    identity_trust: str,
    source: str,
    intent: str,
    conversation_history: list[dict[str, Any]] | list,
    profile_context: str,
    system_state: dict[str, Any],
    safety_context: dict[str, Any],
    dialogue_policy: dict[str, Any],
    rag_context: str = "",
) -> str:
    history_text = format_history(conversation_history)
    profile_text = _clip(profile_context or "", MAX_PROFILE_CHARS)
    state_lines = []
    for key, value in (system_state or {}).items():
        if value is None or value == "":
            continue
        state_lines.append(f"- {key}: {value}")

    safety_lines = []
    for key, value in (safety_context or {}).items():
        safety_lines.append(f"- {key}: {value}")

    policy_lines = []
    for key, value in (dialogue_policy or {}).items():
        policy_lines.append(f"- {key}: {value}")

    context = f"""## Contexto compacto da KoraMind
- usuario atual: {user_id}
- trust level: {identity_trust}
- source: {source}
- intent: {intent}

## Politica de dialogo
{chr(10).join(policy_lines) if policy_lines else "- default"}

## Perfil resumido
{profile_text or "Sem perfil dinamico disponivel."}

## Historico recente
{history_text or "Sem historico recente."}

## Estado real relevante
{chr(10).join(state_lines) if state_lines else "- Sem estado runtime validado para esta pergunta."}

## Seguranca
{chr(10).join(safety_lines) if safety_lines else "- Voz nao autoriza acoes criticas."}
"""

    if rag_context:
        context += f"\n## Contexto RAG\n{rag_context}\n"

    return _clip(context, MAX_CONTEXT_CHARS)
