# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para gerenciar `kanshi` (perfis de monitores) no Wayland.
#
# Por quê:
# - Alterna automaticamente entre cenários “docked” e “undocked” sem configuração manual.
#
# Como:
# - Habilita `services.kanshi` e define `settings` com perfis e outputs.
# - Usa `systemdTarget = "hyprland-session.target"` para iniciar junto da sessão Hyprland.
#
# Riscos:
# - `criteria = "*"` pode aplicar regras em monitores inesperados.
# - Nomes de saída (ex.: `eDP-1`) variam entre GPUs/drivers; ajuste por host se necessário.
# =============================================================================
{ ... }:
{
  # Gerencia o serviço do kanshi via Home Manager.
  services.kanshi = {
    enable = false;
    systemdTarget = "hyprland-session.target";
    settings = [
      {
        profile.name = "casa";
        profile.outputs = [
          {
            criteria = "HDMI-A-1";
            position = "0,0";
            scale = 1.0;
            status = "enable";
          }
          {
            criteria = "eDP-1";
            position = "1920,0";
            scale = 1.0;
            status = "enable";
          }
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
            scale = 1.0;
          }
        ];
      }
    ];
  };
}
