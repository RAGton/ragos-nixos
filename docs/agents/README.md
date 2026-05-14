# Documentação para Agentes

Este diretório contém a base para as inteligências artificiais e prompts do sistema Kryonix.

## Regras Canônicas

Todo agente ao atuar no repositório Kryonix deve respeitar as seguintes regras:

1. **Ler `AGENTS.md` na raiz**: Este é o seu mandato oficial.
2. **Consultar `.context/CURRENT_STATE.md`**: Para saber o que aconteceu nas últimas horas e qual o foco atual.
3. **Consultar `packages/kryonix-cli/registry.sh`**: Fonte única de verdade para ferramentas e comandos.
4. **Documentação Canônica fica em `docs/`**: Não criar documentação solta na raiz do repositório.
5. **Nunca documentar feature inexistente como pronta**: Tudo que não foi efetivamente implementado no código deve estar em `docs/ROADMAP.md`.
6. **Testes Antes de Confirmar**: Sempre execute `kryonix check` ou validações específicas antes de finalizar.
7. A fonte de verdade final é sempre o **Código Ativo**.

Consulte as regras completas em `/etc/kryonix/AGENTS.md` (raiz do projeto).
