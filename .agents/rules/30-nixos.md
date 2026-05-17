# NixOS Rules

Regras para manipulação da infraestrutura NixOS.

- **Usar flakes:** Todas as alterações devem respeitar a estrutura declarativa de flakes do projeto (`flake.nix`).
- **Separação de Papéis dos Hosts:**
  - **Glacier (Servidor):** Host de IA, GPU NVIDIA RTX 4060, Ollama, Kryonix Brain API, Neo4j, storage LightRAG e MCP Brain server.
  - **Inspiron (Cliente):** Workstation leve, Hyprland/Caelestia, Waybar, MCP Client, sem dependências locais de Ollama ou RAG pesado.
- **Evitar mudanças globais:** Não altere configurações de hardware ou opções globais sem necessidade técnica comprovada.
- **Validar com nix flake check:** Sempre valide as alterações locais com `nix flake check --keep-going --show-trace` e construa o alvo localmente (`nix build`) antes de propor switches de sistema.
- **Preservar rollback:** Não faça alterações que impeçam o sistema de retornar a uma geração anterior funcional.
- **Segurança de Serviços:** Mantenha os units do systemd isolados com permissões mínimas (`DynamicUser=true` ou grupo `kryonix`) e configure `EnvironmentFile` fora do `/nix/store`.
