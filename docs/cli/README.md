# Kryonix CLI Documentation

Esta seção contém a documentação técnica e operacional da interface de linha de comando `kryonix`.

## Estrutura da CLI

A CLI é construída seguindo o padrão de **Registro Centralizado**, onde todos os comandos, descrições e flags são definidos em um único local:

- **Registro:** `packages/kryonix-cli/registry.sh`
- **Implementação:** `packages/kryonix-cli/main.sh`
- **Autocompletar:** `packages/kryonix-cli/completions/`

## Introspecção para Agentes e IAs

Se você é um agente de IA (como Antigravity, Codex ou Claude), use o comando abaixo para entender todas as capacidades atuais da CLI:

```bash
kryonix commands --json
```

Isso retornará um mapa completo de comandos, grupos, descrições e subcomandos disponíveis.

## Validação e CI

Qualquer alteração na CLI que adicione novos comandos ou mude comportamentos existentes deve:

1. Atualizar o `registry.sh`.
2. Garantir que `nix flake check` passe (ele valida a consistência do help).
3. Atualizar a documentação se houver mudança contratual.

## Documentos Relacionados

- [USAGE.md](../USAGE.md): Guia rápido de uso.
- [KRYONIX_COMMAND_CONTRACT.md](./KRYONIX_COMMAND_CONTRACT.md): Regras canônicas de sintaxe e operação.
