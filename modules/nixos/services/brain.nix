# =============================================================================
# Módulo: kryonix.services.brain
#
# O que é:
# - Configura Ollama + Brain API + LightRAG como serviços no Glacier.
# - Separação explícita: server (hospeda) vs client (acessa remoto).
#
# Por quê:
# - Ollama sem autostart preserva VRAM para gaming.
# - keep_alive=0 descarrega o modelo imediatamente após uso.
# - kryonix-lightrag aquece o índice antes da Brain API subir.
# - Firewall por interface: apenas LAN (br0) e Tailscale (tailscale0).
#
# Riscos:
# - EnvironmentFile com KRYONIX_BRAIN_KEY deve existir antes do switch.
#   Criar manualmente: sudo install -m600 /dev/null /etc/kryonix/brain.env
# - packageDir aponta para /etc/kryonix/packages/... (requer repo instalado).
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kryonix.services.brain;

  # Script de verificação de VRAM antes de iniciar o Ollama.
  # Aborta se VRAM livre < vramMinGiB * 1024 MiB.
  # Protege a RTX 4060 (8 GB) contra OOM ao subir qwen2.5-coder:7b.
  vramCheckScript = pkgs.writeShellScript "ollama-vram-check" ''
    set -euo pipefail
    REQUIRED_MIB=$(( ${toString cfg.ollama.vramMinGiB} * 1024 ))

    # nvidia-smi fica em /run/current-system/sw/bin no NixOS com hardware.nvidia
    NVIDIA_SMI="/run/current-system/sw/bin/nvidia-smi"
    if [ ! -x "$NVIDIA_SMI" ]; then
      echo "WARN: nvidia-smi não encontrado, pulando verificação de VRAM" >&2
      exit 0
    fi

    VRAM_FREE=$("$NVIDIA_SMI" --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null \
      | head -1 | tr -d ' \r' || echo "")

    if [ -z "$VRAM_FREE" ] || ! printf '%s' "$VRAM_FREE" | grep -qE '^[0-9]+$'; then
      echo "WARN: Não foi possível ler VRAM (GPU indisponível?), continuando" >&2
      exit 0
    fi

    if [ "$VRAM_FREE" -lt "$REQUIRED_MIB" ]; then
      echo "ERRO: VRAM insuficiente: ''${VRAM_FREE}MiB livres, ''${REQUIRED_MIB}MiB necessários para ${cfg.ollama.model}" >&2
      echo "Feche jogos ou apps usando GPU antes de iniciar o Ollama." >&2
      exit 1
    fi

    echo "VRAM OK: ''${VRAM_FREE}MiB livres / mínimo ''${REQUIRED_MIB}MiB para ${cfg.ollama.model}"
  '';

  # Script de warmup do índice LightRAG.
  # Valida GraphML + aquece VDB antes da Brain API subir.
  lightragWarmupScript = pkgs.writeShellScript "kryonix-lightrag-warmup" ''
    set -euo pipefail
    echo "kryonix-lightrag: iniciando warmup do índice LightRAG..."
    cd "${cfg.packageDir}"
    ${pkgs.uv}/bin/uv run python - <<'PYEOF'
    import asyncio, sys

    async def warmup():
        try:
            from kryonix_brain_lightrag import rag
            print("LightRAG: inicializando storages...")
            await rag.get_rag_async()
            print("LightRAG: validando graph...")
            info = await rag.stats()
            status = info.get("consistency_status", "UNKNOWN")
            entities = info.get("entities", 0)
            relations = info.get("relations", 0)
            print(f"LightRAG: {entities} entities, {relations} relations, status={status}")
            err_msg = info.get("error", "Unknown")
            print(f"WARN: LightRAG status={status}: {err_msg}", file=sys.stderr)
        except Exception as e:
            print(f"ERRO no warmup LightRAG: {e}", file=sys.stderr)
            sys.exit(1)

    asyncio.run(warmup())
    PYEOF
    echo "kryonix-lightrag: warmup concluído."
  '';

  # Script de start da Brain API via uv run (sem instalar no Nix store).
  brainApiStartScript = pkgs.writeShellScript "kryonix-brain-api-start" ''
    set -euo pipefail
    cd "${cfg.packageDir}"
    exec ${pkgs.uv}/bin/uv run python -m kryonix_brain_lightrag.api
  '';

in
{
  options.kryonix.services.brain = {
    enable = mkEnableOption "Kryonix Brain AI services";

    role = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      default = "client";
      description = "Papel do host: server hospeda Ollama/LightRAG; client acessa remoto.";
    };

    serverHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "IP/Host do servidor Brain (usado pelo client).";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Porta da Brain API (FastAPI HTTP).";
    };

    environmentFile = mkOption {
      type = types.str;
      default = "/etc/kryonix/brain.env";
      description = ''
        Arquivo de variáveis de ambiente para Brain API e LightRAG.
        Deve conter KRYONIX_BRAIN_KEY e variáveis LIGHTRAG_*.
        NUNCA versionar este arquivo — contém secrets.
        Criar manualmente: sudo install -m600 /dev/null /etc/kryonix/brain.env
      '';
    };

    packageDir = mkOption {
      type = types.str;
      default = "/etc/kryonix/packages/kryonix-brain-lightrag";
      description = "Diretório do pacote Python kryonix-brain-lightrag (usado pelo uv run).";
    };

    ollama = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Habilita o servidor Ollama localmente.";
      };

      # Workaround: default não pode referenciar cfg.role aqui por avaliação lazy.
      # Hosts server devem setar ollama.enable = true explicitamente.

      autoStart = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Se true, Ollama sobe automaticamente no boot.
          Se false (padrão), requer start manual via: kryonix ollama start
          Manter false no Glacier para preservar VRAM para gaming.
        '';
      };

      model = mkOption {
        type = types.str;
        default = "qwen2.5-coder:7b";
        description = "Modelo padrão para o Ollama (referência para kryonix ollama run e VRAM check).";
      };

      keepAlive = mkOption {
        type = types.str;
        default = "0";
        description = ''
          Tempo de keep-alive do modelo em VRAM após inatividade.
          "0" = descarrega imediatamente após query (recomendado para Glacier gamer).
          "5m" = mantém por 5 minutos.
        '';
      };

      vramMinGiB = mkOption {
        type = types.ints.positive;
        default = 6;
        description = ''
          VRAM mínima (GiB) necessária antes de iniciar o Ollama.
          RTX 4060 = 8 GiB total. Mínimo 6 GiB para qwen2.5-coder:7b.
        '';
      };

      acceleration = mkOption {
        type = types.nullOr (
          types.enum [
            "cuda"
            "rocm"
          ]
        );
        default = "cuda";
        description = ''
          Aceleração de hardware para o Ollama.
          Mapeia para o pacote correto: cuda→ollama-cuda, rocm→ollama-rocm, null→ollama.
        '';
      };
    };

    storagePath = mkOption {
      type = types.path;
      default = "/home/rocha/.local/share/kryonix/kryonix-vault/storage";
      description = "Caminho para o storage do LightRAG (apenas server).";
    };

    vaultPath = mkOption {
      type = types.path;
      default = "/home/rocha/.local/share/kryonix/kryonix-vault";
      description = "Caminho para o Vault Obsidian montado/local (apenas server).";
    };
  };

  config = mkIf cfg.enable {

    # ── Pacotes comuns ─────────────────────────────────────────────
    environment.systemPackages =
      with pkgs;
      [
        curl
        jq
      ]
      ++ lib.optionals (cfg.role == "server") [
        ollama-cuda
      ];

    # ── Ollama (apenas server) ─────────────────────────────────────
    # NixOS unstable removeu services.ollama.acceleration e listenAddress.
    # Usar .package e .host/.port em vez disso.
    services.ollama = mkIf cfg.ollama.enable (
      let
        ollamaPackages = {
          cuda = pkgs.ollama-cuda;
          rocm = pkgs.ollama-rocm;
        };
      in
      {
        enable = true;
        package =
          if cfg.ollama.acceleration != null && builtins.hasAttr cfg.ollama.acceleration ollamaPackages then
            ollamaPackages.${cfg.ollama.acceleration}
          else
            pkgs.ollama;
        host = "0.0.0.0";
        port = 11434;
      # keep_alive=0: modelo descarregado da VRAM imediatamente após uso.
      # Crítico para liberar GPU quando Ollama para (kryonix ollama stop).
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = cfg.ollama.keepAlive;
      };
    });

    # Sem autostart: wantedBy vazio = Ollama não sobe no boot.
    # Start manual: kryonix ollama start  →  systemctl start ollama
    systemd.services.ollama = mkIf cfg.ollama.enable {
      wantedBy = mkForce (if cfg.ollama.autoStart then [ "multi-user.target" ] else [ ]);
    };

    # ── VRAM check (oneshot antes do ollama) ───────────────────────
    # Roda apenas quando ollama.service é iniciado manualmente.
    # Aborta se VRAM livre < vramMinGiB * 1024 MiB.
    systemd.services.ollama-vram-check = mkIf cfg.ollama.enable {
      description = "Verifica VRAM disponível antes de iniciar o Ollama";
      before = [ "ollama.service" ];
      requiredBy = [ "ollama.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = vramCheckScript;
        RemainAfterExit = false;
      };
    };

    # ── kryonix-lightrag (warmup oneshot) ──────────────────────────
    # Valida storage + aquece VDB antes da Brain API subir.
    # Type=oneshot + RemainAfterExit=true = considerado "up" após warmup.
    systemd.services.kryonix-lightrag = mkIf (cfg.role == "server") {
      description = "Kryonix LightRAG Index Warmup";
      after = [
        "network.target"
        "ollama.service"
      ];
      requires = [ "ollama.service" ];
      before = [ "kryonix-brain-api.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        LD_LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ]}";
        KRYONIX_BRAIN_HOME = "/home/rocha/.local/share/kryonix/kryonix-vault";
        LIGHTRAG_VAULT_DIR = "/home/rocha/.local/share/kryonix/kryonix-vault/vault";
        LIGHTRAG_WORKING_DIR = "/home/rocha/.local/share/kryonix/kryonix-vault/storage";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lightragWarmupScript;
        EnvironmentFile = cfg.environmentFile;
        User = "rocha";
        Group = "users";
        WorkingDirectory = cfg.packageDir;
      };
    };

    # ── kryonix-brain-api (FastAPI HTTP) ──────────────────────────
    # Brain API: /health, /stats, /search, /ingest/*
    # Depende de: ollama + lightrag warmup
    systemd.services.kryonix-brain-api = mkIf (cfg.role == "server") {
      description = "Kryonix Brain API Service (FastAPI HTTP :${toString cfg.port})";
      after = [
        "network.target"
        "ollama.service"
        "kryonix-lightrag.service"
      ];
      requires = [
        "ollama.service"
        "kryonix-lightrag.service"
      ];
      # wantedBy é mkForce [] no glacier/default.nix até o switch ser validado.
      # Remover o mkForce [] para que suba automaticamente após ollama+lightrag.
      wantedBy = [ "multi-user.target" ];
      environment = {
        LD_LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ]}";
        KRYONIX_BRAIN_HOME = "/home/rocha/.local/share/kryonix/kryonix-vault";
        LIGHTRAG_VAULT_DIR = "/home/rocha/.local/share/kryonix/kryonix-vault/vault";
        LIGHTRAG_WORKING_DIR = "/home/rocha/.local/share/kryonix/kryonix-vault/storage";
      };
      serviceConfig = {
        ExecStart = brainApiStartScript;
        WorkingDirectory = cfg.packageDir;
        EnvironmentFile = cfg.environmentFile;
        Restart = "on-failure";
        RestartSec = "10";
        User = "rocha";
        Group = "users";
      };
    };

    # ── Usuário de sistema do Brain ────────────────────────────────
    # O serviço roda como rocha para ter acesso de leitura e escrita nativos ao Vault em /home/rocha

    # ── Firewall por interface ─────────────────────────────────────
    # Brain API e Ollama só acessíveis via LAN (br0) e Tailscale (tailscale0).
    # NÃO usar allowedTCPPorts (abre para todas as interfaces).
    networking.firewall.interfaces = mkIf (cfg.role == "server") {
      # Tailscale: acesso remoto Inspiron → Glacier
      tailscale0.allowedTCPPorts = [
        cfg.port # Brain API :8000
        11434 # Ollama
      ];
      # LAN (bridge br0): acesso local na rede 10.0.0.0/24
      br0.allowedTCPPorts = [
        cfg.port
        11434
      ];
    };
  };
}
