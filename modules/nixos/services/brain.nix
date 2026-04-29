{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kryonix.services.brain;
in
{
  options.kryonix.services.brain = {
    enable = mkEnableOption "Kryonix Brain AI services";

    role = mkOption {
      type = types.enum [ "server" "client" ];
      default = "client";
      description = "Papel do host no ecossistema Brain (server = hospeda Ollama/LightRAG, client = acessa remoto)";
    };

    serverHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "IP/Host do servidor Brain (usado pelo client)";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Porta da Brain API";
    };

    ollama = {
      enable = mkOption {
        type = types.bool;
        default = cfg.role == "server";
        description = "Habilita o servidor Ollama localmente";
      };
      acceleration = mkOption {
        type = types.nullOr (types.enum [ "cuda" "rocm" ]);
        default = "cuda";
        description = "Aceleração de hardware para o Ollama";
      };
    };

    storagePath = mkOption {
      type = types.path;
      default = "/var/lib/kryonix/brain/storage";
      description = "Caminho para o storage do LightRAG (apenas server)";
    };

    vaultPath = mkOption {
      type = types.path;
      default = "/var/lib/kryonix/vault";
      description = "Caminho para o Vault Obsidian montado/local";
    };
  };

  config = mkIf cfg.enable {
    # Dependências comuns
    environment.systemPackages = with pkgs; [
      curl
      jq
    ];

    # =========================
    # CONFIGURAÇÃO DE SERVIDOR
    # =========================
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      package = if cfg.ollama.acceleration == "cuda" then pkgs.ollama-cuda else pkgs.ollama;
      host = "0.0.0.0"; # Permite acesso via Tailscale/LAN
    };

    # Firewall: Abrir portas para Tailscale e LAN segura
    networking.firewall.allowedTCPPorts = mkIf (cfg.role == "server") [
      cfg.port      # Brain API
      11434         # Ollama
    ];

    # Unidades de sistema para Brain API e LightRAG (Blueprint)
    systemd.services.kryonix-brain-api = mkIf (cfg.role == "server") {
      description = "Kryonix Brain API Service";
      after = [ "network.target" "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python -m kryonix_brain_lightrag.api";
        WorkingDirectory = "/var/lib/kryonix/brain/package";
        EnvironmentFile = "/etc/kryonix/brain.env";
        Restart = "always";
        User = "kryonix-brain";
        Group = "kryonix-brain";
      };
    };

    # Usuário dedicado para o Brain
    users.users.kryonix-brain = mkIf (cfg.role == "server") {
      isSystemUser = true;
      group = "kryonix-brain";
      home = "/var/lib/kryonix/brain";
      createHome = true;
    };
    users.groups.kryonix-brain = mkIf (cfg.role == "server") { };
  };
}
