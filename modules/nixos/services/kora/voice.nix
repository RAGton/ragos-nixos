{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.kryonix.services.kora.voice;
in
{
  options.kryonix.services.kora.voice = {
    enable = mkEnableOption "Kora Voice Listener (Always-on)";
    
    alwaysOn = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to start the voice listener daemon on boot.";
    };

    wakeword = mkOption {
      type = types.str;
      default = "kora";
      description = "The wake-word to listen for.";
    };
  };

  config = mkIf cfg.enable {
    # Systemd user service template
    systemd.user.services.kora-voice-listener = {
      description = "Kora Voice Listener Daemon";
      after = [ "network.target" "sound.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.kora}/bin/kora voice daemon start";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      wantedBy = mkIf cfg.alwaysOn [ "default.target" ];
    };
  };
}
