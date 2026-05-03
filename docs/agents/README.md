# Documentação para Agentes

Este diretório contém a base para as inteligências artificiais e prompts do sistema Kryonix.

## Regras Canônicas

Todo agente ao atuar no repositório Kryonix deve respeitar as seguintes regras:

1. **Consultar `docs/README.md` primeiro**: Todas as referências da estrutura canônica encontram-se ali.
2. **Documentação Canônica fica em `docs/`**: Não criar documentação solta na raiz do repositório.
3. **Prompts e Regras de Agentes ficam em `docs/agents/`** (este diretório).
4. **Nunca documentar feature inexistente como pronta**: Tudo que não foi efetivamente implementado no código, validado e testado, deve ser enviado para `docs/ROADMAP.md`.
5. **Testes Antes de Confirmar**: Sempre execute testes de integridade, build, e linting do Nix antes de finalizar sua tarefa. A CLI `kryonix` oferece as verificações base.
6. A fonte de verdade é sempre o repositório principal e seu estado de código ativo (`flake.nix`, `hosts/`, `modules/`, etc).

Consulte as regras completas em `/etc/kryonix/AGENTS.md` (raiz do projeto).
