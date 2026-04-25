# ==============================================================================
# Módulo: hosts/common (agregador de composição NixOS)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Ponto único de importação para tudo que é compartilhado entre hosts NixOS.
# - Mantém os hosts (inspiron, glacier, iso) focados em hardware/partições/boot.
#
# Por quê:
# - Reduz duplicação de imports entre hosts.
# - Facilita troubleshooting porque a arquitetura fica previsível por camadas.
#
# Como:
# - Encadeia opções, módulos de base/sistema, features e profiles.
# - Expõe a seleção de desktop via `kryonix.desktop.environment`.
# ==============================================================================
{ ... }:
{
  imports = [
    ../../lib/options.nix
    ../../modules/nixos/base
    ../../modules/nixos/hardware
    ../../modules/nixos/input
    ../../modules/nixos/audio
    ../../modules/nixos/network
    ../../modules/nixos/programs/kryonix
    ../../modules/nixos/theming
    ../../modules/nixos/services
    ../../modules/nixos/desktop
    ../../features
    ../../profiles
  ];
}
