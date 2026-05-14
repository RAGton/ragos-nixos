# Decision Records - Kryonix 🧊⚡

Este documento registra decisões arquiteturais e operacionais importantes para evitar regressões.

### [2026-05-14] CLI Registry v2
- **Decisão:** Expandir o registry para incluir metadados de risco, host, runtime e exemplos.
- **Motivo:** Facilitar a introspecção por agentes de IA e melhorar a segurança operacional (exibindo alertas de sudo e risco).
- **Impacto:** O comando `kryonix commands --json` agora é o contrato principal para ferramentas externas e o próprio Brain.

### [2026-05-13] Sincronização Glacier/Inspiron
- **Decisão:** Manter o Glacier como "Brain Server" e o Inspiron como "Client".
- **Motivo:** Otimização de recursos (GPU no Glacier) e portabilidade (Inspiron leve).
- **Conexão:** Tailscale + SSH porta 2224 como canal padrão.

### [2026-05-13] Llama.cpp Fallback
- **Decisão:** Priorizar `llama_cpp` para maior performance, mas manter `ollama` como fallback automático e provider padrão de embedding.
- **Motivo:** Estabilidade vs Performance.

### [2026-05-12] Governança Source Available
- **Decisão:** Transição para licenciamento Source Available / Proprietário (Issue #15).
- **Impacto:** Adição de headers de licença em todos os arquivos core.
