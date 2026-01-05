{ pkgs, ... }:
{
  # Otimizações gerais de games no nível do sistema

  # GameMode (daemon da Feral): já está no user env, aqui ativamos o serviço
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept";
      };
    };
  };

  # Ferramentas úteis para jogos (globais, não por usuário)
  environment.systemPackages = with pkgs; [
    mangohud
    gamescope
    vkbasalt
  ];

  # Garante suporte 32‑bit para jogos (Steam/Proton)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
