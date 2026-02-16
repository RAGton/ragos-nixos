{ pkgs, nhModules, lib, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/kde"
  ];

  # Autostart (KDE): inicia o OpenRGB sozinho e já minimizado na bandeja.
  xdg.configFile."autostart/openrgb.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=OpenRGB
    Comment=OpenRGB (start minimized)
    Exec=openrgb --startminimized
    Icon=openrgb
    Terminal=false
    StartupNotify=false
    X-KDE-autostart-after=panel
    X-KDE-StartupNotify=false
    X-GNOME-Autostart-enabled=true
  '';

  # Habilita home-manager
  programs.home-manager.enable = true;

  # Editor: VSCode via nix (evita flatpak/manual e garante atualização com `nix flake update`).
  rag.vscode = {
    enable = true;
    channel = "unstable";
    flavor = "vscode";
  };

  # Nota: GameMode é instalado aqui como pacote; ativar serviços de sistema
  # (daemons) deve ser feito na configuração do host (NixOS).

  # Pacotes de jogos (ambiente do usuário). Drivers e ajustes de kernel/performance
  # no nível do sistema são responsabilidade da configuração do host (NixOS).
  home.packages = with pkgs; [
    steam
    lutris
    heroic
    gamemode
    atlauncher

    # Streaming de jogos (Sunshine/GameStream)
    moonlight-qt
  ];

  # (sem opção extra de backup aqui; mantenha o controle via `home.file`)

  # A configuração do Zsh (incluindo Powerlevel10k) é centralizada em
  # modules/home-manager/programs/zsh.

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
