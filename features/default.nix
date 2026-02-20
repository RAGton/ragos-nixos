# =============================================================================
# Features Manager: Auto-import de features baseado em opções
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Auto-importa módulos de features quando habilitados via opções
# - Centraliza gerenciamento de features
#
# Por quê:
# - Features são opt-in via opções
# - Cada feature é auto-contida
# - Fácil adicionar novas features
#
# Como:
# 1. Features definem suas próprias opções (rag.features.*)
# 2. Este manager importa automaticamente quando enable = true
# 3. Hosts apenas habilitam: rag.features.gaming.enable = true
# =============================================================================
{ config, lib, ... }:

{
  # Importa todos os módulos de features
  # Cada um define suas próprias opções e só ativa quando enable = true
  imports = [
    ./gaming.nix
    ./virtualization.nix
    ./development.nix
  ];

  # Configuração base comum a todas as features
  config = {
    # Assertions gerais (se necessário)
    assertions = [
      # Add global feature assertions here if needed
    ];
  };
}

