# Módulo NixOS: Gaming (otimizações e ferramentas)
# Autor: rag
#
# O que é
# - Ajustes e ferramentas globais para jogos (GameMode, MangoHud, Gamescope, Vulkan tools etc.).
# - Garante suporte 32-bit para Steam/Proton.
#
# Por quê
# - Consolida “stack de jogos” no nível do sistema para ficar pronto após rebuild.
# - Evita repetir pacotes e flags em múltiplos hosts.
#
# Como
# - Ativa `programs.gamemode` e instala ferramentas em `environment.systemPackages`.
# - Habilita `hardware.graphics.enable32Bit`.
#
# Riscos
# - Algumas ferramentas podem mudar comportamento/perf com drivers (NVIDIA/Mesa); revisar após updates.
{ pkgs, ... }:
{
  # Otimizações gerais de games no nível do sistema.

  # GameMode (daemon da Feral): ativa o serviço no nível do sistema.
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = -10;
      };
      gpu = {
        apply_gpu_optimisations = "accept";
      };
    };
  };

  # Ferramentas úteis para jogos (globais, não por usuário).
  environment.systemPackages = with pkgs; [
    mangohud
    gamescope
    vkbasalt
    vulkan-tools
    mesa-demos
    nvtopPackages.nvidia
    umu-launcher
    protonup-qt
    protontricks
  ];

  # Garante suporte 32‑bit para jogos (Steam/Proton).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
