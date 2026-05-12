# Current State

- **Fase Atual:** Estabilização de Serviços do Glacier e Brain API (Operacional Remoto).
- **Ambiente:** Linux (Glacier - NixOS Server / Inspiron - Client).
- **Git Status:** Commit de refatoração do Brain concluído.
- **Serviços Críticos:**
    - Ollama: Habilitado no boot (via `ollamaAutoStart`).
    - Brain API / LightRAG: Parametrizados para usar `/var/lib/kryonix/brain/storage` e `/var/lib/kryonix/vault`.
    - Warmup de Modelo: Desacoplado do boot (via `modelWarmupOnBoot = false`).
- **Progresso:** 
    - Migração física dos dados do Vault/Storage para `/var/lib/kryonix` concluída com sucesso.
    - Avaliação do sistema via `nix build` passou.
    - **Sucesso:** Kryonix Brain e CAG confirmados operacionais remotamente no Inspiron sem necessidade de SSH direto.
- **Bloqueios:** Nenhum. O sistema está em estado estável de runtime.
