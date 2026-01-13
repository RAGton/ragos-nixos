/*
 Autor: RAGton
 Descrição: Módulo NixOS para kernel desktop (Zen/XanMod),
            com foco em desempenho, baixa latência e extensibilidade.
*/

{ config, pkgs, lib, ... }:

let
  cfg = config.kernelZen;

  xanmodKernelPackages =
    if pkgs ? linuxPackages_xanmod_latest then
      pkgs.linuxPackages_xanmod_latest
    else if pkgs ? linuxPackages_xanmod then
      pkgs.linuxPackages_xanmod
    else
      null;

  baseKernelPackages =
    if cfg.kernel == "xanmod" then xanmodKernelPackages else pkgs.linuxPackages_zen;

  kernelPackages =
    if cfg.forceLocalBuild then
      baseKernelPackages
      // {
        kernel = baseKernelPackages.kernel.overrideAttrs (old: {
          preferLocalBuild = true;
          allowSubstitutes = false;
        });
      }
    else
      baseKernelPackages;
in
{
  ############################
  # Opções do módulo
  ############################
  options.kernelZen = {
    enable = lib.mkEnableOption "Kernel Linux Zen otimizado para desktop";

    kernel = lib.mkOption {
      type = lib.types.enum [ "zen" "xanmod" ];
      default = "zen";
      description = ''
        Define qual kernel usar.

        - "zen": kernel Zen (nixpkgs: linuxPackages_zen)
        - "xanmod": kernel XanMod (nixpkgs: linuxPackages_xanmod*_)
      '';
    };

    forceLocalBuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Quando `true`, tenta forçar o build local do kernel (sem substituters)
        marcando o derivation do kernel com `preferLocalBuild = true` e
        `allowSubstitutes = false`.

        Isso aumenta bastante o tempo de rebuild.
      '';
    };

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

    assertions =
      [
        {
          assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
          message = "O módulo kernelZen é suportado apenas em x86_64-linux.";
        }
      ]
      ++ lib.optionals (cfg.kernel == "xanmod") [
        {
          assertion = xanmodKernelPackages != null;
          message = "kernelZen.kernel=\"xanmod\" foi selecionado, mas nixpkgs não expõe linuxPackages_xanmod(_latest).";
        }
      ];

    # Kernel Zen como padrão (permitindo override)
    boot.kernelPackages = lib.mkDefault kernelPackages;

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

  };
}