{ pkgs, nhModules, lib, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/kde"
  ];

  # Habilita home-manager
  programs.home-manager.enable = true;

  # Jupyter: opt-in por host (mantemos fora do módulo common para não quebrar outras máquinas)
  programs.jupyter = {
    enable = true;

    kernels = {
      # base
      python = true;

      # mais usados
      rust = true;
      cpp = true;
      bash = true;
      dotnet = false;

      # ainda não suportado por este módulo (precisa pacote/kernel no nixpkgs)
      node = false;
    };
  };

  # Editor: VSCode via nix (evita flatpak/manual e garante atualização com `nix flake update`).
  rag.vscode = {
    enable = true;
    channel = "unstable";
    flavor = "vscode";
  };

  # Tema: Edna Dark (Plasma + GTK + ícones)
  rag.theme.edna = {
    enable = true;
    # Se o nome exato no Plasma/GTK/Icons for diferente, ajuste aqui.
    name = "Edna";
    gtkName = "Edna";
    iconName = "Edna";
    plasmaLookAndFeel = null;
  };

  # Nota: GameMode é instalado aqui como pacote; ativar serviços de sistema
  # (daemons) deve ser feito na configuração do host (NixOS).

  # Pacotes de jogos (ambiente do usuário). Drivers e ajustes de kernel/performance
  # no nível do sistema são responsabilidade da configuração do host (NixOS).
  home.packages = with pkgs; [
    steam
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

  # (Removido) backupFileExtension: esta configuração não está exposta neste setup.
  # Preferimos resolver os conflitos explicitamente com force nos arquivos conhecidos.

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}
