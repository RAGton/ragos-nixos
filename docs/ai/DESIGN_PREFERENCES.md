# DESIGN_PREFERENCES

## Escopo

Este repositorio nao possui frontend web tradicional. As preferencias de design aqui se aplicam a experiencia desktop Linux, branding e documentacao visual do Kryonix.

## Desktop real

- Hyprland e o desktop ativo.
- Caelestia e o shell/rice principal.
- DMS e legado em transicao.
- GDM, GRUB, Plymouth, wallpaper e `/etc/os-release` carregam branding Kryonix.

## Preferencias de UX

- Desktop deve ser responsivo, previsivel e estavel antes de ser chamativo.
- Launcher deve abrir apps graficos via desktop entries validos.
- Preserve UWSM no caminho de launch.
- Evite atalhos frageis baseados em parsing manual de `Exec=` quando houver alternativa robusta.
- Nao reintroduza `wofi` sem decisao explicita.
- Evite auto-lock/auto-suspend no notebook principal quando a decisao atual for manter sessao ativa.

## Branding

- Nome publico atual: Kryonix.
- Compatibilidade Kryonix/KRYONIX deve aparecer apenas onde necessaria para migracao.
- Remocoes de branding legado devem ser incrementais e testadas.

## Validacao visual/operacional

- Login/session inicia.
- Hyprland sobe.
- Caelestia inicia.
- Launcher abre apps graficos comuns.
- Apps de terminal continuam funcionando.
- Wallpaper/branding nao quebram build.
- Mudancas em NVIDIA/Wayland no `glacier` exigem cuidado extra.
