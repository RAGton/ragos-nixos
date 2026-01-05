{ pkgs, nhModules, lib, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/kde"
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Note: GameMode is provided as a package here; enabling system
  # services (daemons) should be done in the NixOS host configuration.

  # Gaming packages (user environment). System-level drivers and kernel
  # performance tweaks are handled in the NixOS host configuration.
  home.packages = with pkgs; [
    steam
    lutris
    heroic
    gamemode
    atlauncher
  ];

  # (no extra backup option here; keep file management local via `home.file` options)

  # Manage Powerlevel10k config from the dotfiles repository
  home.activation.create-p10k-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/zsh"
  '';

  home.file.".config/zsh/.p10k.zsh" = {
    source = ./p10k.zsh;
    # Allow Home Manager to overwrite existing file without interactive prompt
    force = true;
  };

  # A configuração do Zsh é centralizada nos módulos reutilizáveis em
  # modules/home-manager/programs/zsh. Aqui mantemos apenas o arquivo do p10k.

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
