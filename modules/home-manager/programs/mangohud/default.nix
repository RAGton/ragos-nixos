# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar e configurar `MangoHud` (OSD/telemetria em jogos).
#
# Por quê:
# - Facilita troubleshooting de performance (FPS, frametime, GPU/CPU, VRAM).
# - Mantém um preset leve e reproduzível.
#
# Como:
# - Ativa somente no Linux via `lib.mkIf (!pkgs.stdenv.isDarwin)`.
# - Escreve `~/.config/MangoHud/MangoHud.conf`.
# - O pacote em si deve vir do sistema/host para evitar duplicação.
#
# Riscos:
# - O OSD pode interferir com alguns jogos/anti-cheat dependendo do título.
# - Config incorreta pode poluir a tela; ajuste conforme necessidade.
# =============================================================================
{ lib, pkgs, ... }:
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Preset simples (sem cores hardcoded) para monitorar FPS/frametime e uso de GPU/CPU.
    xdg.configFile."MangoHud/MangoHud.conf" = {
      force = true;
      text = ''
      legacy_layout=0
      horizontal
      fps
      frametime
      frame_timing=1

      gpu_stats
      gpu_temp
      gpu_core_clock
      gpu_mem_clock
      vram

      cpu_stats
      cpu_temp
      ram

      # Útil para troubleshooting de runtime/driver
      vulkan_driver
      engine_version
      '';
    };
  };
}
