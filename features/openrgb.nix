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
      default = pkgs.openrgb-git;
      description = "Pacote OpenRGB a ser utilizado.";
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
    # Blacklist sp5100_tco para evitar conflito com SMBus (RAM RGB no AM5)
    boot.blacklistedKernelModules = [ "sp5100_tco" ];
    boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

    services.hardware.openrgb = {
      enable = true;
      package = cfg.package;
    };

    # Serviço para desligar LEDs no boot
    systemd.services.kryonix-rgb-off = lib.mkIf cfg.offAtBoot {
      description = "Desliga LEDs via OpenRGB no boot";
      after = [ "openrgb.service" ];
      requires = [ "openrgb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2"; # Aguarda servidor estabilizar
        # Tenta múltiplos modos para garantir desligamento total (RAM, Motherboard, Keyboard)
        ExecStart = pkgs.writeShellScript "rgb-off-sequence" ''
          ${cfg.package}/bin/openrgb --mode static --color 000000 || true
          ${cfg.package}/bin/openrgb --mode Direct --color 000000 || true
          ${cfg.package}/bin/openrgb --mode off || true
        '';
        RemainAfterExit = true;
        User = "root"; # Executa como root para garantir acesso inicial
      };
    };

    # Garante que o usuário rocha e o grupo kryonix tenham acesso ao hardware sem sudo
    # Isso é essencial para operação via SSH onde uaccess pode falhar
    services.udev.extraRules = ''
      # Acesso OpenRGB para o grupo kryonix
      SUBSYSTEM=="hidraw", MODE="0660", GROUP="kryonix", TAG+="uaccess"
      SUBSYSTEM=="usb", MODE="0660", GROUP="kryonix", TAG+="uaccess"
      SUBSYSTEM=="i2c-dev", MODE="0660", GROUP="kryonix", TAG+="uaccess"
    '';

    users.users.rocha.extraGroups = [
      "i2c"
      "video"
      "input"
      "kryonix"
    ];

    environment.systemPackages = [ cfg.package ];
    services.udev.packages = [ cfg.package ];
  };
}
