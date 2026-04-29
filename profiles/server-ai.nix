{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kryonix.profiles.server-ai;
in
{
  options.kryonix.profiles.server-ai = {
    enable = mkEnableOption "Profile de Servidor de IA (Glacier)";
  };

  config = mkIf cfg.enable {
    # Habilita o Brain como servidor
    kryonix.services.brain = {
      enable = true;
      role = "server";
      ollama.enable = true;
      ollama.acceleration = "cuda";
      storagePath = "/var/lib/kryonix/brain/storage";
      vaultPath = "/var/lib/kryonix/vault";
    };

    # SSH para gerenciamento remoto
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      openFirewall = true;
    };

    # Tailscale é essencial para o ecossistema distribuído
    services.kryonix.tailscale = {
      enable = true;
      autoconnect = true;
    };

    # Otimização de performance para servidor de alta carga
    powerManagement.cpuFreqGovernor = "performance";

    # Monitoramento básico
    environment.systemPackages = with pkgs; [
      htop
      nvtopPackages.nvidia
      iotop
    ];

    # Firewall restrito: Apenas LAN e Tailscale
    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      # Permitir tráfego da LAN 10.0.0.0/24 (exemplo)
      extraCommands = ''
        iptables -A INPUT -s 10.0.0.0/24 -j ACCEPT
      '';
    };
  };
}
