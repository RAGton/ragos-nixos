# Incidente - 2026-04-28 - UWSM reporta executaveis ausentes em desktop entries validos

## Sintoma

- Caelestia mostrava notificacoes do UWSM como:
  - `Entry /run/current-system/sw/share/applications/rustdesk.desktop points to missing executable rustdesk`
  - `Entry /run/current-system/sw/share/applications/winbox.desktop points to missing executable WinBox`
  - `Entry /run/current-system/sw/share/applications/startcenter.desktop points to missing executable libreoffice`

## Evidencia operacional

- No shell interativo, `command -v rustdesk`, `command -v WinBox` e `command -v libreoffice` retornavam caminhos em `/run/current-system/sw/bin`.
- O `caelestia.service` rodava com `PATH` fechado por `systemd.user.services.caelestia.path`, sem `/run/current-system/sw/bin`.
- O `uwsm app -- <desktop-entry>` valida o `Exec=` com o `PATH` do processo chamador antes de criar a unit.

## Causa raiz

O helper `kryonix-launch` era chamado a partir do ambiente restrito do servico Caelestia. Assim, desktop entries validos do sistema pareciam quebrados para o UWSM mesmo quando os executaveis existiam no perfil do sistema.

## Correcao

- `kryonix-launch` agora reconstrui um PATH de launch com perfis Nix, Flatpak exports e o `bin`/`sbin` do pacote que publicou o desktop entry.
- RustDesk foi movido para Flatpak declarativo para evitar builds locais pesados do pacote nativo, mantendo wrapper CLI `rustdesk`.

## Validacao esperada

- `uwsm` nao deve mais emitir `points to missing executable` para desktop entries de apps presentes em perfis Nix/Flatpak.
- `rustdesk.desktop` deve vir do Flatpak, com `Exec=flatpak run ... com.rustdesk.RustDesk`.
