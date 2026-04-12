{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    home.packages = [ pkgs.warp-terminal ];

    # Ajustes leves:
    # - Desliga auto-indexação de codebase do Agent Mode (pode ser pesada)
    # - Desliga sync de settings para reduzir ruído na primeira inicialização
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
  };
}
