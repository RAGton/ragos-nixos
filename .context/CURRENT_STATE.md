# Current State

- **Fase Atual:** Governança e Expansão de Capacidades do Brain (v0.5.0).
- **Ambiente:** Linux (Glacier - NixOS Server / Inspiron - Client).
- **Git Status:** Sincronizado; fix de resiliência `entity_type` e melhorias de CAG integradas ao upstream.
- **Serviços Críticos:**
    - Ollama: Backend `llama_cpp` (primário) com fallback automático para `ollama`.
    - Brain API / LightRAG: Operacional em `:8000` com persistência em `/var/lib/kryonix/brain/storage`.
- **Progresso:** 
    - **Separação de Contrato:** `search` (evidências, sem LLM) e `ask` (síntese, com LLM) plenamente operacionais.
    - **Resiliência:** Proteção contra `KeyError` em metadados incompletos do grafo implementada.
    - **Diagnostics:** `kryonix brain doctor` agora reporta saúde unificada de RAG e CAG.
    - **Sucesso:** Auditoria de governança concluída; v0.4.2 marcada como estável.
- **Bloqueios:** Nenhum. Foco movido para Síntese Comparativa e Autocura do Vault.
