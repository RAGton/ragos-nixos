{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kryonix-wayvnc;
in
{
  options.services.kryonix-wayvnc = {
    enable = lib.mkEnableOption "Kryonix WayVNC Server (Loopback only)";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.kryonix-wayvnc = {
      Unit = {
        Description = "Kryonix WayVNC Server (127.0.0.1:5900)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.wayvnc}/bin/wayvnc 127.0.0.1 5900";
        Restart = "always";
        RestartSec = "5";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
