# ==============================================================================
# Módulo: base (compat layer para common)
# Autor: Gabriel Rocha (ragton) + Codex
# Data: 2026-03-12
#
# O que é:
# - Camada base que delega para o módulo `common` existente.
#
# Por quê:
# - Preserva compatibilidade da refatoração enquanto a base antiga é decomposta
#   em módulos menores sem quebrar os hosts atuais.
# ==============================================================================
{ ... }:
{
  imports = [ ../common ];
}
