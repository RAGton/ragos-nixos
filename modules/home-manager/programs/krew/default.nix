{
  pkgs,
  lib,
  ...
}:
let
  krewPkgs = [
    "ctx"
    "ns"
  ];

  # Convert the list of plugins into a space-separated string
  krewPkgStr = lib.concatStringsSep " " krewPkgs;
in
{
  # Ensure krew package installed
  home.packages = [ pkgs.krew ];

  # Ensure krew is in the PATH
  home.sessionPath = [ "$HOME/.krew/bin" ];

  # Install krew plugins
  home.activation.krew = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="$HOME/.krew/bin:${pkgs.git}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:/usr/bin:$PATH";

    STATE_DIR="$HOME/.cache/home-manager"
    STAMP="$STATE_DIR/krew-last-upgrade"
    mkdir -p "$STATE_DIR"

    # Garante que os plugins declarados estejam instalados, mas evita upgrade a cada switch.
    for plugin in ${krewPkgStr}; do
      if ! ${pkgs.krew}/bin/krew list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qx "$plugin"; then
        ${pkgs.krew}/bin/krew install "$plugin"
      fi
    done

    # Faz upgrade no máximo 1x por semana (reduz muito o tempo do home-manager switch).
    if [ ! -f "$STAMP" ] || [ -n "$(find "$STAMP" -mtime +7 -print -quit 2>/dev/null)" ]; then
      ${pkgs.krew}/bin/krew upgrade
      touch "$STAMP"
    fi
  '';
}
