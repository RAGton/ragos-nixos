{ lib, pkgs, ... }:

{
  # Bluetooth do Glacier — pareamento de caixas de som/headsets.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs.bluez;

    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        Enable = "Source,Sink,Media,Socket";
        ControllerMode = "dual";
        JustWorksRepairing = "always";
      };

      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.blueman.enable = true;

  # Áudio Bluetooth via PipeWire/WirePlumber.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman
    pavucontrol
    pulseaudio
  ];

  # Evita Bluetooth desligado por economia agressiva.
  systemd.services.bluetooth.wantedBy = [ "multi-user.target" ];
}
