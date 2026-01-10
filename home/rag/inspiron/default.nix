{ pkgs, nhModules, lib, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/kde"
  ];

  # Habilita home-manager
  programs.home-manager.enable = true;

  # Nota: GameMode é instalado aqui como pacote; ativar serviços de sistema
  # (daemons) deve ser feito na configuração do host (NixOS).

  # Pacotes de jogos (ambiente do usuário). Drivers e ajustes de kernel/performance
  # no nível do sistema são responsabilidade da configuração do host (NixOS).
  home.packages = with pkgs; [
    steam
    gamemode
    atlauncher
  ];

  # (sem opção extra de backup aqui; mantenha o controle via `home.file`)

  # Gerencia o Powerlevel10k a partir deste repositório
  home.activation.create-p10k-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/zsh"
  '';

  home.file.".config/zsh/.p10k.zsh" = {
    source = ./p10k.zsh;
    # Permite sobrescrever o arquivo existente sem prompt interativo
    force = true;
  };

  # A configuração do Zsh é centralizada nos módulos reutilizáveis em
  # modules/home-manager/programs/zsh. Aqui mantemos apenas o arquivo do p10k.

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
