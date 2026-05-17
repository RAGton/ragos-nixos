from __future__ import annotations

DIALOGUE_POLICY = {
    "casual_check": {
        "style": "natural_short",
        "forbidden": ["STT", "TTS", "openWakeWord", "diagnostico tecnico"],
        "example": "Sim, Ragton. Estou te ouvindo.",
    },
    "capabilities_query": {
        "style": "structured_medium",
        "must_include": ["capacidades reais", "pendencias reais", "seguranca"],
    },
    "technical_diagnostic": {
        "style": "engineering",
        "must_include": ["diagnostico", "causa provavel", "correcao", "validacao"],
    },
    "complaint_bad_answer": {
        "style": "repair",
        "must_include": ["reconhecer falha", "recuperar pergunta anterior", "corrigir"],
    },
    "followup_complaint": {
        "style": "repair",
        "must_include": ["reconhecer falha", "recuperar pergunta anterior", "corrigir"],
    },
    "learning_request": {
        "style": "engineering",
        "must_include": ["perfil", "correcoes", "memoria", "benchmark"],
    },
    "voice_status": {
        "style": "structured_medium",
        "must_include": ["estado real", "pendencias", "seguranca"],
    },
    "general_chat": {
        "style": "natural_direct",
        "must_include": ["responder a pergunta"],
    },
}


def get_dialogue_policy(intent: str) -> dict:
    return DIALOGUE_POLICY.get(intent, DIALOGUE_POLICY["general_chat"])
