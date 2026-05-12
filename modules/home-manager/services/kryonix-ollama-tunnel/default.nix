# Home Manager: serviço de túnel SSH em segundo plano para o Ollama do Glacier
# Autor: Gabriel Aguiar Rocha (RAGton) + Antigravity
#
# O que é
# - Um serviço systemd de usuário que cria e mantém um túnel SSH estável
#   com o servidor Glacier encaminhando a porta 11434 local para a porta 11434 de Glacier.
#
# Como usar
# - Ativar via: services.kryonix-ollama-tunnel.enable = true;
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kryonix-ollama-tunnel;
in
{
  options.services.kryonix-ollama-tunnel = {
    enable = lib.mkEnableOption "Kryonix Ollama remote SSH tunnel to Glacier";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.kryonix-ollama-tunnel = {
      Unit = {
        Description = "Kryonix Ollama SSH Tunnel to Glacier";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Environment = [ "SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh" ];
        ExecStart = "${pkgs.openssh}/bin/ssh -N -T -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -L 11434:127.0.0.1:11434 glacier-public";
        Restart = "always";
        RestartSec = "10";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
