# Kryonix — Instruções de Repositório para Copilot

Leia `AGENTS.md` e `context/INDEX.md` antes de propor mudanças amplas.

Trate o código real como fonte de verdade. Para documentação, priorize `docs/CURRENT_STATE.md`, `docs/OPERATIONS.md`, `docs/ROADMAP.md` e o índice curto em `context/`.

Mantenha mudanças pequenas, reversíveis e alinhadas ao estado atual do projeto.

Hyprland é o desktop real. Caelestia é a camada principal de shell/rice. DMS é legado em transição e não deve receber novos acoplamentos.

Não reintroduza `wofi`. Preserve `uwsm` no caminho de lançamento dos apps e prefira desktop entries válidos para apps gráficos em vez de atalhos frágeis ou parsing manual de `Exec=`.

Ao tocar em Nix, não mexa em `flake.lock` sem necessidade real. Em árvore suja, prefira validação com `path:$PWD` para não perder arquivos ainda não rastreados.

No `glacier`, não use `disko`, `format-*`, `install-system` ou `hosts/glacier/disks.nix` para mudanças incrementais.

Quando a mudança alterar comportamento público, atualize a documentação mínima no mesmo patch e registre decisão/incidente em `context/` se isso ajudar futuras iterações.

Ao validar, se a mudança tocar desktop/host/flake, prefira esta ordem: `nix flake show`, `nix flake check --keep-going`, builds dos hosts afetados e só então testes operacionais.
