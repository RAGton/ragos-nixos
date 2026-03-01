# =============================================================================
# Desktop Manager: Auto-import de desktops baseado em opção
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Módulo que automaticamente importa o desktop correto baseado em rag.desktop.environment
# - Abstração de alto nível para simplificar configuração dos hosts
#
# Por quê:
# - Hosts não precisam saber qual módulo importar
# - Trocar desktop = mudar 1 linha ao invés de mexer em imports
# - Padrão moderno de NixOS (options over imports)
#
# Como usar:
# 1. No host: rag.desktop.environment = "kde";
# 2. Este módulo importa automaticamente desktop/kde/system.nix
# 3. O usuário importa desktop/kde/user.nix no Home Manager
#
# Riscos:
# - Depende de lib/options.nix estar carregado primeiro
# - Se o desktop escolhido não existir, build falhará
# =============================================================================
{ config, lib, options, ... }:

{
  # Importa condicionalmente os módulos de desktop
  # IMPORTANTE: Não podemos usar config.rag.desktop aqui (recursão infinita)
  # Por isso, importamos TODOS os desktops e eles se auto-desabilitam via mkIf
  imports = [
    ./kde/system.nix
    ./hyprland/system.nix

    # LightDM agora é importado via hosts/inspiron/default.nix (temporário para teste)
    # TODO: mover para local adequado após validação
  ];

  # Configurações base para todos os desktops Wayland
  config = lib.mkIf (config.rag.desktop.wayland) {
    # Mesa drivers (comum para qualquer Wayland)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # XWayland support (apps X11 em Wayland)
    programs.xwayland.enable = lib.mkDefault true;
  };
}


