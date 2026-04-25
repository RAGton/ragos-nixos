# Runbook: Launcher Caelestia

## Objetivo

Localizar regressões entre o drawer do Caelestia, desktop entries, wrappers e `uwsm`.

## Checklist curto

1. confirmar helper real de launch:
   `rg -n "kryonix-launch|rag-launch-desktop-entry|Apps.qml|uwsm app --" /home/rocha/src/caelestia-shell desktop modules`
2. confirmar serviço do shell:
   `systemctl --user status caelestia --no-pager`
3. confirmar desktop entry:
   `find ~/.local/share ~/.nix-profile/share /run/current-system/sw/share -type f | rg '<app>\\.desktop$'`
4. comparar:
   `uwsm app -- <id>`
   `uwsm app -- <id>.desktop`
   `uwsm app -- /caminho/real/<id>.desktop`
5. observar processo, unit e janela:
   `pgrep -af '<app>'`
   `systemctl --user list-units 'app-*<app>*' --all --no-pager`
   `hyprctl clients -j | jq`

## Interpretação

- se `<id>` falhar e `<id>.desktop` funcionar, o problema está na resolução do desktop entry
- se ambos falharem, verificar wrapper, PATH e runtime do app
- se abrir app errado, comparar o `Exec` do desktop entry publicado com o binário bruto

## Resultado esperado

Uma causa raiz curta, um patch mínimo e um teste real por app crítico.
