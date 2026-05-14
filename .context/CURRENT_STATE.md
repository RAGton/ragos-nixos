# Current State - Kryonix 🧊⚡

- **Fase Atual:** Evolução Operacional e Registry v2 (v0.5.0-beta).
- **Arquitetura:** 
    - **Inspiron:** Workstation cliente, Hyprland/Caelestia, CLI local.
    - **Glacier:** Servidor IA, Brain API, Neo4j, Ollama (IP `100.125.99.110`, SSH `2224`).
- **Estado do Repo:** 
    - Sincronizado e limpo. 
    - `flake.lock` atualizado com as últimas versões de `lightrag` e `home-manager`.
    - Resíduo `test-llama` no Glacier removido.
- **CLI & Operações:**
    - **Registry v2:** Implementado em `packages/kryonix-cli/registry.sh`. Fonte única de verdade para comandos, riscos, requisitos e exemplos.
    - **Help:** Dinâmico e colorido com avisos de `sudo` e níveis de risco.
    - **Autocomplete:** Bash (autoload fixado), Zsh e Fish operacionais.
    - **Shortcuts:** Documentados em `docs/SHORTCUTS.md`. Teclado ABNT2 fixado.
- **Brain & AI:**
    - **Health:** API e Storage estáveis no Glacier.
    - **Stats:** Grafo Neo4j e Vetores em `/var/lib/kryonix/brain/storage` operacionais.
    - **Resiliência:** Proteção contra falhas de metadados integrada.
- **Bloqueios:** Nenhum.
- **Foco:** Consolidação de Contexto e Automação de Ingestão (v0.5.x).

*Última atualização: 2026-05-14 por Antigravity*
