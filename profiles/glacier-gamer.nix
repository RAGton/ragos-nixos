# =============================================================================
# Profile: glacier-gamer
#
# O que é:
# - Habilita o stack completo de gaming no Glacier.
# - Inclui: Steam, Gamescope, GameMode, MangoHud, Lutris, Wine, Heroic, OpenRGB.
# - Também habilita workstation (desktop Hyprland/Caelestia + apps produtividade).
# - GPU totalmente disponível para jogos quando Ollama está parado.
#
# Por quê:
# - Um único lugar para tudo que é "gamer + desktop" no Glacier.
# - Elimina duplicação entre glacier/default.nix e features/*.
# - keep_alive=0 no glacier-ai garante que VRAM fica livre após queries IA.
#
# Toggles de runtime (sem rebuild):
#   Modo IA:    kryonix ollama start
#   Modo gamer: kryonix ollama stop  (VRAM fica livre após keep_alive=0)
# =============================================================================
{
  config,
  lib,
  ...
}:

let
  cfg = config.kryonix.profiles.glacier-gamer;
in
{
  options.kryonix.profiles.glacier-gamer = {
    enable = lib.mkEnableOption "Perfil gamer do Glacier (Steam, Lutris, Wine, Heroic, OpenRGB, desktop)";
  };

  config = lib.mkIf cfg.enable {
    # Desktop/workstation (Hyprland/Caelestia + apps produtividade)
    kryonix.features.workstation.enable = true;

    # OpenRGB (controle de LED do hardware)
    kryonix.features.openrgb.enable = true;

    # Stack completo de gaming — todos os valores explícitos, sem mkDefault
    kryonix.features.gaming = {
      enable = true;
      steam = {
        enable = true;
        gamescope = true;
      };
      gamemode.enable = true;
      mangohud.enable = true;
      lutris.enable = true;
      wineTools.enable = true;
      heroic.enable = true;
      nvtop.enable = false; # puxa CUDA toolkit completo — desnecessário com nvidia-smi
    };

    # Garantia explícita: Ollama NÃO sobe automaticamente.
    # O glacier-ai já seta autoStart=false, mas este mkForce é segurança adicional
    # para garantir que GPU fica 100% livre para jogos no boot.
    systemd.services.ollama.wantedBy = lib.mkForce [ ];
  };
}
