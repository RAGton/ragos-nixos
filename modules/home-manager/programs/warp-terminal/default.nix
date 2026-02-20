# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager que instala o `warp-terminal` no perfil do usuário.
#
# Por quê:
# - Garante o binário correto via Nix (reprodutível) sem depender de instalação manual.
#
# Como:
# - Adiciona `pkgs.warp-terminal` em `home.packages`.
#
# Riscos:
# - Em alguns ambientes, Warp pode ter dependências/integrações específicas do sistema.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  # Instala o pacote `warp-terminal` para garantir o binário correto via Nix.
  home.packages = [ pkgs.warp-terminal ];

  # Ajustes de performance:
  # - Desliga auto-indexação de codebase do Agent Mode (pode ser bem pesado)
  # - Desliga sync de settings (reduz tráfego/latência na inicialização)
  # Mantém o arquivo intacto, apenas sobrescrevendo essas duas chaves.
  home.activation.warp-terminal-performance-tweaks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    prefs_file="${config.xdg.configHome}/warp-terminal/user_preferences.json"
    if [ -f "$prefs_file" ]; then
      tmp="$(mktemp)"
      if ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 < "$prefs_file"; then
        ${pkgs.jq}/bin/jq '
          .prefs.AgentModeCodebaseContextAutoIndexing = "false" |
          .prefs.IsSettingsSyncEnabled = "false"
        ' "$prefs_file" > "$tmp" && mv "$tmp" "$prefs_file"
      else
        rm -f "$tmp"
      fi
    fi
  '';
}
