# =============================================================================
# Profile: glacier-ai
#
# O que é:
# - Habilita Ollama + Brain API + LightRAG no Glacier.
# - Ollama sem autostart: GPU fica livre até start manual.
# - keep_alive=0: modelo descarregado da VRAM após cada query.
#
# Por quê:
# - Separação limpa: IA não afeta gaming.
# - VRAM da RTX 4060 (8 GB) fica disponível para jogos quando Ollama parado.
# - Controle manual: kryonix ollama start/stop
#
# Como usar:
#   kryonix.profiles.glacier-ai.enable = true;
#
# Modo gamer (desligar IA temporariamente):
#   systemctl stop ollama kryonix-lightrag kryonix-brain-api
# =============================================================================
{
  config,
  lib,
  ...
}:

let
  cfg = config.kryonix.profiles.glacier-ai;
in
{
  options.kryonix.profiles.glacier-ai = {
    enable = lib.mkEnableOption "Perfil IA do Glacier (Ollama + Brain + LightRAG, sem autostart)";

    model = lib.mkOption {
      type = lib.types.str;
      default = "qwen2.5-coder:7b";
      description = "Modelo Ollama padrão para o Glacier.";
    };

    keepAlive = lib.mkOption {
      type = lib.types.str;
      default = "0";
      description = ''
        Tempo de keep-alive do modelo em VRAM.
        "0" = descarrega imediatamente (recomendado para Glacier gamer).
      '';
    };

    vramMinGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 6;
      description = "VRAM mínima (GiB) para iniciar o Ollama (RTX 4060 = 8 GiB).";
    };
  };

  config = lib.mkIf cfg.enable {
    kryonix.services.brain = {
      enable = true;
      role = "server";

      # NÃO iniciar automaticamente no boot (se quiser manter disabled).
      # Start manual: kryonix ollama start → systemctl start ollama
      # Mas o user pediu para habilitar por padrão e remover o model warmup do boot.
      ollamaAutoStart = lib.mkDefault true;
      modelWarmupOnBoot = lib.mkDefault false;

      ollama = {
        enable = true;
        model = cfg.model;
        keepAlive = cfg.keepAlive;
        vramMinGiB = cfg.vramMinGiB;
        acceleration = "cuda";
      };
      storagePath = "/var/lib/kryonix/brain/storage";
      vaultPath = "/var/lib/kryonix/vault";
    };
  };
}
