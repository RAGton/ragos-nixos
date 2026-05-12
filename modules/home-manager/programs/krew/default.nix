# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar o `krew` (plugin manager do `kubectl`).
# - Instala plugins declarados e faz upgrade de forma amortizada (no máx. 1x/semana).
#
# Por quê:
# - Mantém o set de plugins do kubectl consistente entre máquinas.
# - Evita deixar o `home-manager switch` lento por upgrades frequentes.
#
# Como:
# - Instala `pkgs.krew` e adiciona `~/.krew/bin` ao PATH.
# - No activation, garante plugins presentes e faz upgrade com “stamp” em cache.
#
# Riscos:
# - O activation roda comandos de rede (krew) e pode falhar offline.
# - A lista de plugins é estado fora do Nix store (instala em `~/.krew`).
# =============================================================================
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

  # Converte a lista de plugins em uma string separada por espaços.
  krewPkgStr = lib.concatStringsSep " " krewPkgs;
in
{
  # Garante que o pacote krew esteja instalado.
  home.packages = [ pkgs.krew ];

  # Garante que o krew esteja no PATH.
  home.sessionPath = [ "$HOME/.krew/bin" ];

  # Instala plugins do krew.
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
