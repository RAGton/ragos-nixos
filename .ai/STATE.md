# Kryonix AI State

- **Objetivo atual**: Consolidar a arquitetura global do Brain no diretório canônico `/home/rocha/.local/share/kryonix/kryonix-vault`.
- **Último passo concluído**: Refatoramos o módulo Nix (`brain.nix`) e a configuração Python (`config.py`) para apontar para o novo caminho global independentemente de repositório. O serviço agora roda como `rocha` para permissões locais nativas.
- **Próximos passos**:
  1. Transferir notas existentes ou iniciar a ingestão no novo `vault/` local.
  2. Aguardar o término do processo (pode levar alguns minutos).
  3. Validar com `kryonix brain stats` e `kryonix brain search "arquitetura Glacier"`.
- **Serviços verificados**:
  - `kryonix-lightrag.service`: **SUCCESS (AQUECIDO)**.
  - `kryonix-brain-api.service`: **SUCCESS (ONLINE NA PORTA 8000)**.
- **Testes executados**:
  - `nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link`: Sucesso (dependência compilou sem testes).
- **Erros pendentes**:
  - Modelos LLM ausentes (erro 404 do Ollama).
  - Storage graphml/vetores está vazio.
- **Timestamp da última execução**: 2026-05-01T22:34:28Z
