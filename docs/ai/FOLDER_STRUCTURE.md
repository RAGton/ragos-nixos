# FOLDER_STRUCTURE

## Raiz

- `.github/`: instrucoes Copilot, prompts e CI.
- `.vscode/`: configuracao local do editor.
- `AGENTS.md`: contrato principal para agentes.
- `README.md` e `README-en.md`: visao publica do projeto.
- `flake.nix`: entrada principal Nix.
- `flake.lock`: pins; nao alterar sem motivo.
- `Makefile`: atalhos seguros e alvos destrutivos protegidos.
- `SECURITY.md`: politica de reporte.

## Infra NixOS

- `hosts/`: hosts NixOS e ISO.
- `hosts/common/`: configuracao comum.
- `hosts/glacier/`: workstation AMD + NVIDIA, gaming e virtualizacao.
- `hosts/inspiron/`: notebook principal.
- `hosts/inspiron-nina/`: notebook da Nina.
- `hosts/iso/`: live/install ISO.
- `modules/nixos/`: modulos de sistema.
- `modules/kernel/`: kernel Zen.
- `modules/virtualization/`: rede/virtualizacao compartilhada.
- `features/`: capacidades opt-in.
- `profiles/`: composicoes por papel.
- `overlays/`: overrides de pacotes.
- `packages/`: pacotes/CLIs do projeto.
- `lib/`: helpers e opcoes.

## Usuario e desktop

- `home/`: Home Manager por usuario/host.
- `modules/home-manager/`: modulos Home Manager reutilizaveis.
- `desktop/hyprland/`: configuracao Hyprland system/user.
- `desktop/hyprland/rice/`: Caelestia/DMS e arquivos de rice.
- `files/`: assets e arquivos estaticos usados pelo sistema.

## Contexto e documentacao

- `docs/`: documentacao humana e historica.
- `docs/ai/`: contexto curto para LLMs.
- `context/`: memoria operacional curta e rastreavel.
- `skills/`: procedimentos reutilizaveis para agentes.
- `ai/`: material anterior/experimental; nao e a entrada principal atual.

## Diretorios que agentes devem evitar em varreduras

- `.git/`
- `node_modules/`
- `dist/`
- `build/`
- `target/`
- `result/`
- `.direnv/`
- `vendor/`
- caches em geral

## Observacao

Se a tarefa for especifica, leia primeiro o indice curto e o modulo relevante. Evite varredura cega do repo inteiro.
