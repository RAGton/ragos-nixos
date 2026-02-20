# Variáveis (sobrescreva se necessário)
HOSTNAME ?= $(shell hostname)
FLAKE ?= .#$(HOSTNAME)
HOME_TARGET ?= $(FLAKE)
EXPERIMENTAL ?= --extra-experimental-features "nix-command flakes"

.PHONY: help install-nix install-nix-darwin darwin-rebuild nixos-rebuild \
	home-manager-switch nix-gc flake-update flake-check bootstrap-mac

help:
	@echo "Alvos disponíveis:"
	@echo "  install-nix          - Instala o gerenciador de pacotes Nix"
	@echo "  install-nix-darwin   - Instala o nix-darwin usando a flake $(FLAKE)"
	@echo "  darwin-rebuild       - Reconstrói a configuração do nix-darwin"
	@echo "  nixos-rebuild        - Reconstrói a configuração do NixOS"
	@echo "  home-manager-switch  - Aplica a configuração do Home Manager usando a flake $(HOME_TARGET)"
	@echo "  nix-gc               - Executa coleta de lixo do Nix"
	@echo "  flake-update         - Atualiza as entradas (inputs) da flake"
	@echo "  flake-check          - Verifica a flake por problemas"
	@echo "  bootstrap-mac        - Instala Nix e nix-darwin em sequência"

install-nix:
	@echo "Instalando o Nix..."
	@sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
	@echo "Instalação do Nix concluída."

install-nix-darwin:
	@echo "Instalando o nix-darwin..."
	@sudo nix run nix-darwin $(EXPERIMENTAL) -- switch --flake $(FLAKE)
	@echo "Instalação do nix-darwin concluída."

darwin-rebuild:
	@echo "Reconstruindo a configuração do Darwin..."
	@sudo darwin-rebuild switch --flake $(FLAKE)
	@echo "Reconstrução do Darwin concluída."

nixos-rebuild:
	@echo "Reconstruindo a configuração do NixOS..."
	@sudo nixos-rebuild switch --flake $(FLAKE)
	@echo "Reconstrução do NixOS concluída."

home-manager-switch:
	@echo "Aplicando a configuração do Home Manager..."
	@home-manager switch --flake $(HOME_TARGET)
	@echo "Home Manager aplicado com sucesso."

nix-gc:
	@echo "Coletando lixo do Nix..."
	@nix-collect-garbage -d
	@echo "Coleta de lixo concluída."

flake-update:
	@echo "Atualizando entradas (inputs) da flake..."
	@nix flake update
	@echo "Atualização da flake concluída."

flake-check:
	@echo "Verificando a flake..."
	@nix flake check
	@echo "Verificação da flake concluída."

bootstrap-mac: install-nix install-nix-darwin
