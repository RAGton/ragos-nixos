# Submódulos do Kryonix

Este repositório utiliza submódulos Git para gerenciar pacotes internos de forma isolada.

## Inicialização

Ao clonar o repositório, use:
```bash
git clone --recurse-submodules https://github.com/RAGton/kryonix.git
```

Em um repositório já clonado:
```bash
git submodule update --init --recursive
```

## Fluxo de Desenvolvimento (ex: kryonix-home)

Para editar um pacote que é submódulo:

1. **Edição Local**:
   ```bash
   cd packages/kryonix-home
   # fazer alterações
   cargo test
   git add .
   git commit -m "feat: nova funcionalidade"
   git push origin main
   ```

2. **Atualização no Superprojeto**:
   O superprojeto (Kryonix) rastreia tanto o ponteiro do Git quanto o input do Flake.
   ```bash
   cd /etc/kryonix
   nix flake lock --update-input kryonix-home
   git add packages/kryonix-home flake.lock
   git commit -m "chore(home): update kryonix-home"
   ```

## Regras de Ouro
- Nunca esqueça de commitar e pushar dentro do diretório do submódulo antes de atualizar o superprojeto.
- Mantenha o `flake.lock` em sincronia com o commit do submódulo.
