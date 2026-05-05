# =============================================================================
# Feature: Remote Desktop (WayVNC)
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Implementação declarativa de acesso remoto para Wayland/Hyprland.
# - Servidor: wayvnc (VNC server nativo wlroots).
# - Cliente: tigervnc + wrapper kryonix-remote-desktop.
#
# Por quê:
# - Acesso remoto seguro e performático ao Glacier/Inspiron.
# - Suporte a Hyprland e Wayland.
#
# Como:
# - Habilitar kryonix.features.remoteDesktop.server.enable = true.
# - Porta padrão: 5905 (aberta no firewall).
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.features.remoteDesktop;
in
{
  options.kryonix.features.remoteDesktop = {
    server = {
      enable = lib.mkEnableOption "Servidor VNC (wayvnc) para Hyprland";
      port = lib.mkOption {
        type = lib.types.port;
        default = 5905;
        description = "Porta para o servidor VNC";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Endereço para o bind do servidor (127.0.0.1 para segurança total, 0.0.0.0 para público)";
      };
    };
    client = {
      enable = lib.mkEnableOption "Clientes VNC e wrapper kryonix-remote-desktop";
    };
  };

  config = lib.mkMerge [
    # Configuração do SERVIDOR
    (lib.mkIf cfg.server.enable {
      # Firewall: Abre a porta apenas na interface Tailscale por padrão
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.server.port ];

      environment.systemPackages = [ pkgs.wayvnc ];

      # Serviço de usuário para rodar dentro da sessão Hyprland
      # O UWSM/Hyprland exporta as variáveis necessárias para o graphical-session.target
      systemd.user.services.wayvnc = {
        description = "WayVNC Server for Hyprland";
        documentation = [ "https://github.com/any1/wayvnc" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wayvnc}/bin/wayvnc ${cfg.server.address} ${toString cfg.server.port}";
          Restart = "always";
          RestartSec = "5sec";
        };
      };
    })

    # Configuração do CLIENTE
    (lib.mkIf cfg.client.enable {
      environment.systemPackages = with pkgs; [
        tigervnc # Fornece vncviewer
        (writeShellApplication {
          name = "kryonix-remote-desktop";
          runtimeInputs = [
            bash
            coreutils
            tigervnc
          ];
          text = ''
            set -euo pipefail

            TARGET="''${1:-}"
            PORT=${toString cfg.server.port}

            if [[ -z "$TARGET" ]]; then
              echo "Uso: kryonix-remote-desktop <host|ip>"
              echo "Exemplo: kryonix-remote-desktop glacier"
              exit 1
            fi

            # Resolução básica de hostnames conhecidos do ecossistema Kryonix
            case "$TARGET" in
              glacier)
                # Tenta IP do Tailscale primeiro, depois LAN
                IP="100.108.71.36" 
                ;;
              inspiron)
                IP="inspiron" # Assume resolução via /etc/hosts ou DNS local
                ;;
              *)
                IP="$TARGET"
                ;;
            esac

            echo "🚀 Conectando ao Kryonix Remote Desktop em $IP:$PORT..."
            
            # tigervnc viewer usa host::port para conexões diretas
            # -SecurityTypes=None (padrão do wayvnc se não configurado TLS)
            vncviewer "$IP::$PORT"
          '';
        })
      ];
    })
  ];
}
