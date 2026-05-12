# Kryonix CI Hardening

## Objetivo
Fortalecer as barreiras de qualidade e segurança do repositório Kryonix, garantindo que mudanças em Nix, Shell, Rust e Python sejam validadas automaticamente antes do merge em `main`.

## Jobs

### nix
- **Flake Show**: Valida que o flake pode ser lido e lista os outputs.
- **Flake Check**: Executa todos os checks declarativos no `flake.nix`.
- **Build Kryonix**: Valida o build da CLI principal (`.#kryonix`).
- **Build Kryonix Home**: Valida o build do componente Rust (`.#kryonix-home`).
- **Nota**: Utiliza `NIXPKGS_ALLOW_UNFREE=1` e `--impure` para permitir pacotes proprietários do projeto.

### shell
- **Bash Syntax**: Verifica erros de sintaxe em todos os scripts em `packages/kryonix-cli/` usando `bash -n`.
- **Git Check**: Valida a higiene do repositório (whitespace e marcadores de conflito) via `git diff --check`.
- **Documentation Audit**: Executa `./scripts/doc-audit.sh` para garantir que não existam placeholders (`T-O-D-O`, `W-I-P`) na documentação canônica e que os comandos descritos no `USAGE.md` sejam válidos.

### rust-home
- **Cargo Format**: Garante que o código segue o estilo padrão.
- **Cargo Clippy**: Auditoria estática para detectar anti-padrões e bugs potenciais.
- **Cargo Test**: Executa a suíte de testes unitários e de integração.
- **Cargo Build**: Valida a compilação completa do binário.

### python-brain
- **Python Compileall**: Verifica erros de sintaxe em todo o código Python do submódulo `kryonix-brain-lightrag`.

### security
- **Gitleaks**: Escaneamento de segredos na árvore de arquivos atual (`--no-git`) para evitar vazamentos acidentais de chaves de API ou segredos do sistema.
- **Pattern Scan**: Busca por padrões críticos (chaves SSH, tokens GitHub, segredos do Brain) fora das áreas de documentação.

## Como reproduzir localmente

### Nix
```bash
nix flake check --impure --keep-going
```

### Rust
```bash
cd packages/kryonix-home
cargo fmt --check
cargo clippy -- -D warnings
cargo test
```

### Shell & Docs
```bash
bash -n packages/kryonix-cli/*.sh
./scripts/doc-audit.sh
```

## Como interpretar falhas
- **Falha no Job `nix`**: Geralmente indica erro de sintaxe Nix ou dependência faltando no flake.
- **Falha no Job `shell`**: Erro de sintaxe em scripts ou `T-O-D-O` esquecido na documentação.
- **Falha no Job `rust-home`**: Erro de lógica, quebra de contrato ou formatação fora do padrão.
- **Falha no Job `security`**: **PARE IMEDIATAMENTE**. Verifique se você commitou um token ou chave privada. Use `git reset` para remover o segredo do commit antes de tentar novamente.

## Limitações
- O CI não executa testes que dependem de hardware real (GPU, discos físicos) ou conexões remotas ao Glacier (Tailscale).

## Relação com Issue #14
Este documento e as automações associadas resolvem a Issue #14 (CI Hardening), elevando o Kryonix ao padrão de governança profissional.
