# =============================================================================
# Feature: OpenRGB
#
# O que é:
# - Controle declarativo do OpenRGB via módulo NixOS oficial.
#
# Por quê:
# - Mantém RGB/hardware fora do perfil base e liga a feature somente em hosts
#   que precisam dela.
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.features.openrgb;
  legacyCfg = config.kryonix.hardware.openrgb;
  openrgbPackage = pkgs.openrgb;
  enableOpenrgb = cfg.enable || legacyCfg.enable;
in
{
  options.kryonix.features.openrgb = {
    enable = lib.mkEnableOption "OpenRGB (serviço, CLI e regras udev)";

    package = lib.mkOption {
      type = lib.types.package;
      default = openrgbPackage;
      defaultText = lib.literalExpression "pkgs.openrgb";
      description = "Pacote OpenRGB usado pelo serviço, CLI e regras udev.";
    };

    offAtBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Se verdadeiro, desliga todos os LEDs no boot.";
    };
  };

  config = lib.mkIf enableOpenrgb {
    # Habilita I2C para controle de DRAM e periféricos
    hardware.i2c.enable = true;

    # Carrega módulos de kernel necessários para I2C e OpenRGB
    boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

    services.hardware.openrgb = {
      enable = true;
      package = cfg.package;
    };

    # Serviço para desligar LEDs no boot
    systemd.services.kryonix-rgb-off = lib.mkIf cfg.offAtBoot {
      description = "Desliga LEDs via OpenRGB no boot";
      after = [ "network.target" "multi-user.target" "openrgb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/openrgb --mode static --color 000000";
        RemainAfterExit = true;
      };
    };

    # Garante que o usuário rocha tenha acesso ao hardware sem sudo
    users.users.rocha.extraGroups = [
      "i2c"
      "video"
      "input"
    ];

    environment.systemPackages = [ cfg.package ];
    services.udev.packages = [ cfg.package ];
  };
}
