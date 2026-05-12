# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o toolchain Rust de forma declarativa.
#
# Por quê:
# - Garante `cargo`/`rustc` disponíveis em todas as máquinas sem depender de rustup.
# - Mantém tooling comum (fmt/clippy/analyzer) consistente entre hosts.
#
# Como:
# - Instala componentes via `home.packages`.
# - Define `CARGO_HOME` e adiciona `$CARGO_HOME/bin` no PATH.
#
# Notas:
# - Se você preferir rustup, evite misturar com este módulo (paths e overrides podem conflitar).
# =============================================================================
{ config, pkgs, ... }:
let
  CARGO_HOME = "${config.home.homeDirectory}/.cargo";
in
{
  home.sessionVariables = {
    inherit CARGO_HOME;
  };

  # Garante que binários instalados via `cargo install` fiquem no PATH.
  home.sessionPath = [
    "${CARGO_HOME}/bin"
  ];

  home.packages = with pkgs; [
    cargo
    rustc

    # Tooling padrão
    rustfmt
    clippy
    rust-analyzer
  ];
}
