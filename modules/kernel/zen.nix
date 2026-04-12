/*
  Autor: RAGton
  Descrição: Módulo NixOS para kernel desktop (Zen/XanMod),
             com foco em desempenho, baixa latência e extensibilidade.
*/

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.kernelZen;

  xanmodKernelPackages =
    if pkgs ? linuxPackages_xanmod_latest then
      pkgs.linuxPackages_xanmod_latest
    else if pkgs ? linuxPackages_xanmod then
      pkgs.linuxPackages_xanmod
    else
      null;

  baseKernel = if cfg.kernel == "xanmod" then xanmodKernelPackages.kernel else pkgs.linux_zen;

  tunedKernel =
    if (!cfg.useLLVMStdenv && cfg.extraMakeFlags == [ ]) then
      baseKernel
    else
      baseKernel.override (
        (lib.optionalAttrs cfg.useLLVMStdenv {
          stdenv = pkgs.llvmPackages_latest.stdenv;
        })
        // {
          extraMakeFlags = cfg.extraMakeFlags;
        }
      );

  tunedKernelLocal =
    if cfg.forceLocalBuild then
      tunedKernel.overrideAttrs (_old: {
        preferLocalBuild = true;
        allowSubstitutes = false;
      })
    else
      tunedKernel;

  kernelPackages = pkgs.linuxPackagesFor tunedKernelLocal;
in
{
  ############################
  # Opções do módulo
  ############################
  options.kernelZen = {
    enable = lib.mkEnableOption "Kernel Linux Zen otimizado para desktop";

    kernel = lib.mkOption {
      type = lib.types.enum [
        "zen"
        "xanmod"
      ];
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

    useLLVMStdenv = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Quando `true`, usa o `stdenv` do LLVM (clang/lld) para build do kernel.

        Útil para tuning de performance e builds com toolchain mais moderna.
        Pode aumentar tempo de build e, dependendo da versão do nixpkgs/kernel,
        exigir ajustes adicionais.
      '';
    };

    extraMakeFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Flags extras passadas para o `make` do kernel.

        Exemplo (tuning por host):
        - "KCFLAGS=-march=native -O3"
        - "KCPPFLAGS=-march=native -O3"
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
      default = [ ];
      description = "Parâmetros extras adicionados ao kernel.";
    };
  };

  ############################
  # Configuração
  ############################
  config = lib.mkIf cfg.enable {

    assertions = [
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

    # Kernel como padrão (permitindo override)
    boot.kernelPackages = lib.mkDefault kernelPackages;

    # Parâmetros globais do Zen; flags genéricas de boot moram em common.
    boot.kernelParams = lib.mkAfter (
      [
        "nowatchdog"
      ]
      ++ lib.optionals cfg.disableMitigations [
        "mitigations=off"
        "noibrs"
        "noibpb"
      ]
      ++ cfg.extraKernelParams
    );

  };
}
