# Estado Atual para Agentes

Atualizado em 2026-04-23.

## Resumo

- O repositório já opera como RagOS VE.
- `rag.*` é o namespace público ativo.
- Hyprland é o desktop real.
- Caelestia é o shell/rice principal dos hosts Hyprland.
- DMS ainda existe como legado de transição e não deve receber novos acoplamentos.
- `ragos` é o entrypoint operacional preferencial.

## Hosts ativos

- `inspiron`: notebook principal de desenvolvimento local, Hyprland + Caelestia.
- `inspiron-nina`: perfil mais leve, Hyprland + Caelestia.
- `glacier`: workstation principal para virtualização/gaming, storage em `/srv/ragenterprise`.
- `iso`: output de instalação, não confundir com fluxo de adoção de host já instalado.

## Estado atual do launcher

- O launcher do Caelestia usa o código upstream em `modules/launcher/services/Apps.qml`.
- Apps gráficas passam pelo helper `assets/rag-launch-desktop-entry`.
- Apps marcadas como `runInTerminal` passam por `app2unit`.
- O problema real encontrado neste repositório não estava no fuzzy search nem em cache pesado.
- A falha principal estava no launch de apps gráficas por desktop ID sem resolução robusta do desktop entry antes de `uwsm`.

## Correção local adotada

- O pacote do Caelestia recebe um patch local no helper `rag-launch-desktop-entry`.
- O helper agora resolve desktop entries por caminho real nos diretórios XDG/Nix/Flatpak e só então chama `uwsm app --`.
- Isso preserva `uwsm`, evita parsing manual frágil de `Exec=` e cobre apps de sistema, Home Manager e Flatpak.

## Camada local de contexto

- `AGENTS.md` continua sendo o contrato principal.
- `context/` agora é o índice curto e estável.
- `skills/` guarda rotinas operacionais reutilizáveis.
- `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` e `.github/prompts/*.prompt.md` cobrem a integração nativa com Copilot.
- `ai/` permanece como material anterior e não é a nova entrada principal.

## Atenções abertas

- `desktop/hyprland/user.nix` segue grande e concentra wrappers demais.
- Ainda há documentação histórica divergente fora da trilha curta de contexto.
- No host atual usado para teste, o Obsidian apresentou falha antiga de runtime do pacote (`Cannot find module 'electron'`), separada da correção do launcher.
