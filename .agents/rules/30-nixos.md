# NixOS Rules

Regras para manipulação da infraestrutura NixOS.

- **Usar flakes:** Todas as alterações devem respeitar a estrutura de flakes do projeto.
- **Evitar mudanças globais:** Não altere configurações globais sem necessidade técnica comprovada.
- **Validar com nix flake check:** Sempre que possível, valide as alterações com `nix flake check`.
- **Preservar rollback:** Não faça alterações que impeçam o sistema de retornar a uma geração anterior funcional.
