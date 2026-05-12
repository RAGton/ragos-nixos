# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o `k9s`.
# - Define UI “enxuta” e atalhos (hotkeys) para recursos comuns do Kubernetes.
#
# Por quê:
# - Padroniza atalhos e reduz ruído visual.
# - Acelera navegação diária (pods/deployments/nodes/services/ingress).
#
# Como:
# - Ajusta `programs.k9s.settings.k9s.ui`.
# - Declara `hotKeys` com comandos correspondentes.
#
# Riscos:
# - Atalhos podem conflitar com teclas do terminal/WM.
# - Comandos podem variar por versão/config do k9s.
# =============================================================================
{ ... }:
{
  # Instala e configura o k9s via Home Manager.
  programs.k9s = {
    enable = true;
    settings.k9s = {
      ui = {
        headless = true;
        logoless = true;
      };
    };
    hotKeys = {
      shift-1 = {
        shortCut = "Shift-1";
        description = "Show pods";
        command = "pods";
      };
      shift-2 = {
        shortCut = "Shift-2";
        description = "Show deployments";
        command = "dp";
      };
      shift-3 = {
        shortCut = "Shift-3";
        description = "Show nodes";
        command = "nodes";
      };
      shift-4 = {
        shortCut = "Shift-4";
        description = "Show services";
        command = "services";
      };
      shift-5 = {
        shortCut = "Shift-5";
        description = "Show Ingress";
        command = "ingress";
      };
      shift-6 = {
        shortCut = "Shift-6";
        description = "Show Pulses";
        command = "pulses";
      };
      shift-7 = {
        shortCut = "Shift-7";
        description = "Show Events";
        command = "events";
      };
    };
  };
}
