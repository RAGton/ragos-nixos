import json

CAPABILITIES = {
    "identity": {
        "status": "working",
        "description": "Reconhece Ragton, Nicoly e visitantes por sessão/perfil.",
        "limits": "USER é hint, não autenticação forte."
    },
    "voice_push_to_talk": {
        "status": "working",
        "description": "Conversa por voz via push-to-talk e transcrição contínua com VAD."
    },
    "voice_always_on": {
        "status": "partial",
        "description": "Serviço em segundo plano em desenvolvimento."
    },
    "wake_word_kora": {
        "status": "pending",
        "description": "Depende de modelo real de wake-word Kora."
    },
    "speaker_id": {
        "status": "foundation",
        "description": "Voice Identity ainda sem embeddings biométricos reais."
    },
    "memory": {
        "status": "partial",
        "description": "Memória no Vault e fila/worker."
    },
    "rag": {
        "status": "partial",
        "description": "Brain/LightRAG disponível, precisa benchmark de qualidade."
    },
    "commands": {
        "status": "guarded",
        "description": "Comandos via Tool Registry e Policy Engine."
    },
    "n8n": {
        "status": "foundation",
        "description": "Automação local via n8n."
    }
}

def get_capabilities_summary() -> str:
    """Returns a formatted summary of the current capabilities."""
    return json.dumps(CAPABILITIES, indent=2, ensure_ascii=False)

def get_deterministic_capabilities_response(user: str = "unknown", profile: dict = None) -> str:
    """Returns the strict, deterministic text for capabilities query."""
    
    greeting = ""
    from .identity import get_identity_response, should_greet
    if profile and should_greet(profile):
        greeting = get_identity_response(profile) + "\n\n"
    elif user and user != "unknown":
        greeting = f"Olá, {user}.\n\n"

    return greeting + """O que podemos fazer agora:

1. Kryonix e infraestrutura
   Diagnosticar serviços, logs, NixOS, Ollama, Brain, Neo4j, rede, GPU, storage e automações.

2. Memória e conhecimento
   Registrar ideias no Vault, recuperar decisões, consultar Brain/RAG e preparar indexação com Neo4j.

3. Voz e presença
   Conversar por push-to-talk e modo VAD. O modo always-on e wake-word "Kora" ainda estão em evolução.

4. Automação
   Preparar ações via n8n local, criar planos e propor comandos reais pelo Tool Registry.

5. Segurança
   Bloquear secrets, comandos destrutivos e separar permissões entre usuários.

Estado atual:
- STT: funcionando.
- TTS: funcionando com fallback.
- Wake-word "Kora": pendente se ready=false.
- Speaker ID biométrico: foundation."""
