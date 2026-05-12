# Troubleshooting do Home Manager — Erros Comuns e Soluções

Este documento registra incidentes, causas e correções para falhas durante a ativação ou build do Home Manager no ecossistema Kryonix.

---

## Erro: libwebrtc-0.3.26 sem outputHash

### Sintoma

Durante `kryonix home` ou `nh home build`:

```txt
No hash was found while vendoring the git dependency libwebrtc-0.3.26
```

### Causa

Algum pacote Rust (ex.: `codex` / `codex-rs`) instalado pelo Home Manager usa uma dependência Git em seu `Cargo.lock`. O Nix exige que o atributo `cargoLock.outputHashes` seja declarado para todas as dependências Git vendorizadas a fim de garantir reprodutibilidade pura.

### Diagnóstico

Para identificar se há referências a webrtc ou dependências de build Rust no repositório:

```bash
rg -n "libwebrtc|webrtc|importCargoLock|outputHashes|buildRustPackage|cargoLock|rustPlatform" .
nh home build . -c rocha@inspiron -L --show-trace
```

### Correções possíveis

1. **Remover/desabilitar pacote opcional:** Se o pacote for secundário ou opcional (como a CLI do Codex), a melhor solução é comentá-lo ou desativá-lo temporariamente no perfil de pacotes de usuário do Home Manager.
2. **Trocar por pacote prebuilt:** Substituir por versões binárias prebuilt se disponíveis.
3. **Adicionar `cargoLock.outputHashes`:** Se for um pacote customizado empacotado no próprio repositório, adicionar o hash correto fornecido pelo Nix no atributo `cargoLock.outputHashes` da derivation.
