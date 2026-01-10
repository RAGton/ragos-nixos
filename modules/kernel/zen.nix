/*
 Autor: RAGton
 Descrição: Módulo NixOS para habilitar o kernel Linux Zen em desktops,
            com foco em desempenho, baixa latência e extensibilidade.
*/

{ config, pkgs, lib, ... }:

let
  cfg = config.kernelZen;
in
{
  ############################
  # Opções do módulo
  ############################
  options.kernelZen = {
    enable = lib.mkEnableOption "Kernel Linux Zen otimizado para desktop";

    disableMitigations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Desativa mitigations de segurança (Spectre, Meltdown, etc).
        Ganho de performance, com riscos conhecidos.
      '';
    };

    extraKernelParams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Parâmetros extras adicionados ao kernel.";
    };
  };

  ############################
  # Configuração
  ############################
  config = lib.mkIf cfg.enable {

    # Kernel Zen como padrão (permitindo override)
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;

    # Parâmetros de kernel
    boot.kernelParams =
      [
        "quiet"
        "nowatchdog"
      ]
      ++ lib.optionals cfg.disableMitigations [
        "mitigations=off"
        "noibrs"
        "noibpb"
      ]
      ++ cfg.extraKernelParams;

    # Garante que só rode em x86_64
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "O módulo kernelZen é suportado apenas em x86_64-linux.";
      }
    ];
  };
}