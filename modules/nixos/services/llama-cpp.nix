{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.services.llama-cpp;
in
{
  options.kryonix.services.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp server (experimental CUDA backend)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp.override { cudaSupport = true; };
      description = "Pacote llama.cpp com suporte CUDA.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Endereço para o llama-server escutar.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11435;
      description = "Porta para o llama-server escutar.";
    };

    modelPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Caminho para o arquivo de modelo GGUF.";
    };

    ctxSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      description = "Tamanho do contexto (tokens).";
    };

    gpuLayers = lib.mkOption {
      type = lib.types.ints.between (-1) 1000;
      default = -1;
      description = "Número de camadas para a GPU (-1 = todas).";
    };

    threads = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Número de threads CPU.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Argumentos extras para o llama-server.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.modelPath != null;
        message = "kryonix.services.llama-cpp.modelPath deve ser configurado.";
      }
    ];

    systemd.services.kryonix-llama-cpp = {
      description = "llama.cpp server (Experimental AI Backend)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/llama-server \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            --model ${cfg.modelPath} \
            --ctx-size ${toString cfg.ctxSize} \
            --n-gpu-layers ${toString cfg.gpuLayers} \
            --threads ${toString cfg.threads} \
            ${lib.escapeShellArgs cfg.extraArgs}
        '';
        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = [ cfg.modelPath ];
        MemoryDenyWriteExecute = false; # Necessário para CUDA/JIT se houver
        DynamicUser = true;
        SupplementaryGroups = [
          "video"
          "render"
        ]; # Acesso GPU
      };
    };
  };
}
