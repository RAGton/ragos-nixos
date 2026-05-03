# Incidente — 2026-04-23 — Launcher Caelestia abrindo apps de forma incorreta

## Sintoma

- apps gráficas do launcher demoravam ou falhavam para abrir
- algumas entradas abriam pelo caminho errado
- `org.kde.dolphin` e `com.gexperts.Tilix` falharam quando enviados ao `uwsm` sem `.desktop`

## Evidência operacional

- `uwsm app -- org.kde.dolphin` retornou `Command not found: "org.kde.dolphin"`
- `uwsm app -- org.kde.dolphin.desktop` abriu Dolphin corretamente e criou unit `app-Hyprland-org.kde.dolphin-...scope`
- `uwsm app -- com.gexperts.Tilix` retornou `Command not found: "com.gexperts.Tilix"`
- o código upstream do launcher usa `entry.id` para apps gráficas no helper `rag-launch-desktop-entry`

## Causa raiz

O launcher estava delegando IDs nus ao `uwsm` sem resolver primeiro um desktop entry válido.

## Correção

- adicionar patch local no pacote do Caelestia
- resolver desktop entries por caminho real nos diretórios XDG/Nix/Flatpak
- manter `uwsm app --` como backend de lançamento

## Pendências separadas

- no host atual, o Obsidian apresentou falha antiga de runtime do pacote (`Cannot find module 'electron'`)
- essa falha é independente da resolução do desktop entry do launcher
