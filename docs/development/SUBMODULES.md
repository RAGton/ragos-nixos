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

## Arquitetura de Submódulos (Opção A)

O Kryonix adotou o padrão "Opção A" para o gerenciamento de submódulos, que consiste em:
- **Submódulo local (`packages/<pacote>`)**: Utilizado apenas para desenvolvimento, visualização do código-fonte e auditoria.
- **Flake Input Remoto (`flake.nix`)**: Fonte oficial para o build do Nix.
- **`flake.lock`**: Garante a pinagem da versão reproduzível usada pelo sistema.

### Pacotes Atuais neste Padrão
- `packages/kryonix-home`
- `packages/kryonix-brain-lightrag`

## Fluxo de Desenvolvimento

Para editar um pacote que é submódulo:

1. **Edição Local**:
   ```bash
   cd packages/<pacote>
   # fazer alterações
   git add .
   git commit -m "feat: nova funcionalidade"
   git push origin main
   ```

2. **Atualização no Superprojeto**:
   O superprojeto (Kryonix) rastreia tanto o ponteiro do Git quanto o input do Flake.
   ```bash
   cd /etc/kryonix
   nix flake lock --update-input <pacote>
   git add packages/<pacote> flake.lock
   git commit -m "chore(<pacote>): update <pacote>"
   ```

## Regras de Ouro
- Nunca esqueça de commitar e pushar dentro do diretório do submódulo antes de atualizar o superprojeto.
- Mantenha o `flake.lock` em sincronia com o commit do submódulo.
