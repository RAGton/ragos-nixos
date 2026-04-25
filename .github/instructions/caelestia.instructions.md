---
applyTo: "modules/nixos/desktop/caelestia/**/*.nix,desktop/hyprland/rice/caelestia-config.nix,home/**/caelestia-shell.nix,context/INCIDENTS/*launcher*.md,skills/launcher-diagnosis/SKILL.md"
---

Caelestia deve continuar ativado no nível de sistema. Home Manager publica dados/configuração, não a ativação principal do shell.

Para apps gráficos vindos do launcher, prefira resolver um desktop entry válido antes de delegar a `uwsm app --`.

Não introduza parsing manual frágil de `Exec=` quando um desktop entry ou caminho oficial puder ser usado.

`app2unit` permanece apropriado para apps que realmente precisam rodar em terminal ou para fluxos específicos do shell. Não o force para todos os lançamentos gráficos.

Registre regressões de launcher em `context/INCIDENTS/` com evidência operacional.
