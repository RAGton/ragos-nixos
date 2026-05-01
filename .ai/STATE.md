# Kryonix AI State

- **Objetivo atual**: Corrigir falhas de biblioteca (`libstdc++.so.6`) durante o runtime do Python no systemd.
- **Último passo concluído**: Injeção da variável de ambiente `LD_LIBRARY_PATH` (apontando para `pkgs.stdenv.cc.cc.lib` e `pkgs.zlib`) nas units `kryonix-lightrag` e `kryonix-brain-api` no NixOS, além da remoção do cache indevido do submódulo `.ai/kryonix-vault`.
- **Próximos passos**:
  1. O usuário deve rodar `kryonix switch` novamente no host para ativar a configuração sem erros.
  2. Remover `systemd.services.kryonix-brain-api.wantedBy = lib.mkForce [ ];` de `hosts/glacier/default.nix` (após o switch ser 100% limpo).
  3. Baixar os modelos do Ollama requeridos (`kryonix ollama pull qwen2.5-coder:7b` e `nomic-embed-text:latest`).
  4. Implementar a ingestão dos dados iniciais do repositório no Vault (LightRAG).
- **Serviços verificados**:
  - A ativação do `kryonix-lightrag.service` e `kryonix-brain-api.service` aguardam o usuário rodar o switch final.
- **Testes executados**:
  - `nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link`: Sucesso (dependência compilou sem testes).
- **Erros pendentes**:
  - Modelos LLM ausentes (erro 404 do Ollama).
  - Storage graphml/vetores está vazio.
- **Timestamp da última execução**: 2026-05-01T22:34:28Z
