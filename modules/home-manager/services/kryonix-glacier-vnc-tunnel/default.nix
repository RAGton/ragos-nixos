{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kryonix-glacier-vnc-tunnel;
in
{
  options.services.kryonix-glacier-vnc-tunnel = {
    enable = lib.mkEnableOption "Kryonix VNC remote SSH tunnel to Glacier";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.kryonix-glacier-vnc-tunnel = {
      Unit = {
        Description = "Kryonix VNC SSH Tunnel to Glacier";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Environment = [ "SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh" ];
        ExecStart = "${pkgs.openssh}/bin/ssh -N -T -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -L 5901:127.0.0.1:5900 glacier-publico";
        Restart = "always";
        RestartSec = "10";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
