---
applyTo: "desktop/hyprland/**/*,modules/nixos/hyprland/**/*.nix,modules/nixos/desktop/**/*.nix,home/**/caelestia-shell.nix,docs/CAELESTIA_MANUAL.md"
---

Preserve a separação: Hyprland é desktop; shell/rice ficam na camada do Caelestia.

Atalhos e autostarts gráficos devem continuar alinhados com `uwsm`.

Não adicione launcher paralelo como caminho principal. Rofi pode existir como fallback utilitário, mas não substitui Caelestia.

Quando investigar bugs de launcher, confirme o caminho completo: bind ou drawer do shell, helper invocado, desktop entry resolvido, `uwsm app --`, processo gerado e janela real.

Evite “corrigir” UX gráfica trocando componentes inteiros. Prefira ajustar o helper mínimo, o desktop entry ou o binding correto.
