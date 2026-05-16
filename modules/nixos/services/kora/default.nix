# =============================================================================
# Módulo: kryonix.services.kora
#
# O que é:
# - Configura a Kora (Assistente Pessoal Local) como serviço no Glacier.
# - A Kora é o gateway/orchestrator — consome Brain API, Ollama e Neo4j.
# - Contrato público em :8787, acesso via LAN/Tailscale.
#
# Por quê:
# - Separação limpa: Kora = assistente, Brain = conhecimento, Ollama = inferência.
# - Auth separada: KORA_API_KEY para clientes, KRYONIX_BRAIN_API_KEY interna.
# - Tolerante: se Ollama ou Brain estiverem offline, /health retorna warn, não crash.
#
# Segurança:
# - Bind default em 127.0.0.1 — não expõe publicamente.
# - Secrets via EnvironmentFile, nunca no Nix store.
# - KORA_API_KEY separada de KRYONIX_BRAIN_API_KEY.
#
# Riscos:
# - EnvironmentFile deve existir antes do switch (ou usar prefixo '-' para opcional).
# - packageDir aponta para /etc/kryonix/packages/kora (requer repo instalado).
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kryonix.services.kora;
  runtimeLibPath = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.libffi
    pkgs.openssl
  ];

  koraStartScript = pkgs.writeShellScript "kora-start" ''
    set -euo pipefail
    cd "${cfg.packageDir}"
    export LD_LIBRARY_PATH="${runtimeLibPath}:''${LD_LIBRARY_PATH:-}"
    exec ${pkgs.uv}/bin/uv run python -m kora.api.server
  '';

in
{
  options.kryonix.services.kora = {
    enable = mkEnableOption "Kora Personal Assistant (gateway/orchestrator)";

    user = mkOption {
      type = types.str;
      default = "kryonix";
      description = "Usuário que executará o serviço da Kora.";
    };

    group = mkOption {
      type = types.str;
      default = "kryonix";
      description = "Grupo do serviço da Kora.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        IP de escuta (bind) da Kora API.
        Default: 127.0.0.1 (apenas local).
        Para acesso via LAN/Tailscale, usar "0.0.0.0" ou interface específica.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Porta da Kora API (FastAPI HTTP).";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/kryonix/kora";
      description = "Diretório de dados da Kora (sessões, auditoria, cache).";
    };

    ollamaUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:11434";
      description = "URL do servidor Ollama (model runtime).";
    };

    brainUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8000";
      description = "URL do Kryonix Brain API (knowledge backend).";
    };

    neo4jUri = mkOption {
      type = types.str;
      default = "bolt://127.0.0.1:7687";
      description = "URI do Neo4j (graph/memory backend).";
    };

    model = mkOption {
      type = types.str;
      default = "qwen2.5-coder:7b";
      description = "Modelo Ollama padrão para a Kora.";
    };

    environmentFile = mkOption {
      type = types.str;
      default = "/etc/kryonix/kora.env";
      description = ''
        Arquivo de variáveis de ambiente com KORA_API_KEY.
        Prefixo '-' no systemd torna opcional (não impede boot se ausente).
        Para Brain access interno, KRYONIX_BRAIN_API_KEY vem do brain.env.
      '';
    };

    brainEnvironmentFile = mkOption {
      type = types.str;
      default = "/etc/kryonix/brain.env";
      description = ''
        Arquivo com KRYONIX_BRAIN_API_KEY para acesso interno ao Brain.
        A Kora lê este arquivo para se autenticar no Brain API.
      '';
    };

    packageDir = mkOption {
      type = types.str;
      default = "/etc/kryonix/packages/kora";
      description = "Diretório do pacote Python kora (usado pelo uv run).";
    };
  };

  config = mkIf cfg.enable {
    # ── kora.service (FastAPI HTTP) ──────────────────────────────
    systemd.services.kora = {
      description = "Kora Personal Assistant API (FastAPI HTTP :${toString cfg.port})";
      after = [
        "network-online.target"
      ];
      # Soft dependencies — Kora funciona degradada sem estes serviços
      wants = [
        "ollama.service"
        "kryonix-brain-api.service"
      ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        LD_LIBRARY_PATH = runtimeLibPath;
        KORA_HOST = cfg.host;
        KORA_PORT = toString cfg.port;
        KORA_DATA_DIR = "${cfg.dataDir}";
        KORA_OLLAMA_URL = cfg.ollamaUrl;
        KORA_BRAIN_URL = cfg.brainUrl;
        KORA_NEO4J_URI = cfg.neo4jUri;
        KORA_MODEL = cfg.model;
        UV_PROJECT_ENVIRONMENT = "${cfg.dataDir}/.venv";
      };
      serviceConfig = {
        ExecStart = koraStartScript;
        WorkingDirectory = cfg.packageDir;
        EnvironmentFile = [
          "-${cfg.environmentFile}"
          "-${cfg.brainEnvironmentFile}"
        ];
        Restart = "on-failure";
        RestartSec = "10";
        User = cfg.user;
        Group = cfg.group;
      };
    };

    # ── Diretórios de runtime ────────────────────────────────────
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0770 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/sessions 0770 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/audit 0770 ${cfg.user} ${cfg.group} -"
    ];

    # ── Firewall por interface ───────────────────────────────────
    # Kora API apenas via Tailscale e LAN (nunca pública).
    networking.firewall.interfaces = {
      tailscale0.allowedTCPPorts = [ cfg.port ];
      br0.allowedTCPPorts = [ cfg.port ];
    };
  };
}
