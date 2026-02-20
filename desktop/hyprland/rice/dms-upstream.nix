# =============================================================================
# Rice: DMS (DankMaterialShell) - integração via módulos Nix upstream
#
# O que é:
# - Wrapper fino que importa o módulo Home Manager oficial do DMS.
# - Evita reimplementar opções/serviços e facilita upgrades upstream.
#
# Como:
# - Usa `inputs.dms-flake` (flake=true) para obter `dmsPkgs` (dms-shell, quickshell, etc.)
# - Importa `${inputs.dms}/distro/nix/home.nix` (módulo HM) passando `dmsPkgs`.
#
# Importante:
# - Não escolhe desktop. Deve ser usado junto com Hyprland.
# - Não é ativado automaticamente; você opta por `rag.rice.dmsUpstream.enable`.
# =============================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.rag.rice.dmsUpstream;
  system = pkgs.stdenv.hostPlatform.system;

  # Pacotes providos pelo flake upstream do DMS.
  # Esperado: `packages.${system}.dms-shell` e `packages.${system}.quickshell`.
  dmsPkgs =
    if inputs ? dms-flake then
      inputs.dms-flake.packages.${system}
    else
      { };

in
{
  imports = [
    # Importa o módulo Home Manager oficial do DMS (do repo upstream via inputs.dms)
    # e injeta `dmsPkgs` para o mkPackageOption funcionar.
    (import (inputs.dms + "/distro/nix/home.nix"))
  ];

  options.rag.rice.dmsUpstream = {
    enable = lib.mkEnableOption "Enable DankMaterialShell using upstream Nix modules";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = inputs ? dms-flake;
        message = "dms-upstream: missing flake input 'dms-flake'";
      }
      {
        assertion = inputs ? dms;
        message = "dms-upstream: missing flake input 'dms' (needed to import upstream HM module at distro/nix/home.nix)";
      }
      {
        assertion = dmsPkgs ? dms-shell;
        message = "dms-upstream: upstream does not export packages.${system}.dms-shell";
      }
      {
        assertion = dmsPkgs ? quickshell;
        message = "dms-upstream: upstream does not export packages.${system}.quickshell";
      }
    ];

    # Bridge: nosso toggle rag.* aciona o módulo upstream `programs.dank-material-shell`.
    programs.dank-material-shell = {
      enable = true;
      systemd.enable = lib.mkDefault true;

      # Usa o quickshell do upstream por padrão.
      quickshell.package = lib.mkDefault dmsPkgs.quickshell;
    };

    # Garante que o módulo upstream tenha acesso a `dmsPkgs`.
    _module.args.dmsPkgs = dmsPkgs;
  };
}
