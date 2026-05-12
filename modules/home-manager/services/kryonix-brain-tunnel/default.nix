# Home Manager: serviço de túnel SSH em segundo plano para o Kryonix Brain
# Autor: Gabriel Aguiar Rocha (RAGton) + Antigravity
#
# O que é
# - Um serviço systemd de usuário que cria e mantém um túnel SSH estável
#   com o servidor Glacier encaminhando a porta 8000 para a porta local 18000.
#
# Como usar
# - Ativar via: services.kryonix-brain-tunnel.enable = true;
# - Garante que KRYONIX_REMOTE_BRAIN_URL = "http://127.0.0.1:18000" funcione sem
#   precisar manter uma janela de terminal com o SSH aberta.
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kryonix-brain-tunnel;
in
{
  options.services.kryonix-brain-tunnel = {
    enable = lib.mkEnableOption "Kryonix Brain remote SSH tunnel to Glacier";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.kryonix-brain-tunnel = {
      Unit = {
        Description = "Kryonix Brain SSH Tunnel to Glacier";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Environment = [ "SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh" ];
        ExecStart = "${pkgs.openssh}/bin/ssh -N -T -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -L 18000:127.0.0.1:8000 glacier-public";
        Restart = "always";
        RestartSec = "10";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
