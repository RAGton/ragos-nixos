# Fluxo de Desenvolvimento (Submódulos)

O repositório `kryonix-home` é um submódulo independente. Para garantir a reprodutibilidade e a saúde do projeto principal, siga este fluxo.

## Modos de Operação

### 1. Modo Release (Produção)
No `flake.nix` do superprojeto, o input deve apontar para o repositório remoto:
```nix
kryonix-home = {
  url = "github:RAGton/KRYONIX-HOME";
  flake = false;
};
```
O arquivo `flake.lock` garante que todos os usuários e o CI utilizem a mesma versão pinada.

### 2. Modo Desenvolvimento Local
Ao fazer alterações no código Rust em `packages/kryonix-home`, você deve testar localmente antes de publicar.

**Comando de teste com override:**
```bash
nix build .#kryonix-home --override-input kryonix-home path:./packages/kryonix-home
```

**Comando de execução com override:**
```bash
nix run .#kryonix --override-input kryonix-home path:./packages/kryonix-home -- home scan
```

## Publicando Alterações

1. **No Submódulo:**
   ```bash
   cd packages/kryonix-home
   # ... fazer alterações ...
   cargo test --all
   git add .
   git commit -m "feat: sua mudança"
   git push origin main
   ```

2. **No Superprojeto:**
   ```bash
   cd /etc/kryonix
   # Atualizar o lock para o novo commit remoto
   nix flake update kryonix-home
   # Sincronizar o ponteiro do submódulo no Git
   git add flake.lock packages/kryonix-home
   git commit -m "chore(home): update kryonix-home to latest"
   ```

## Regras de Ouro
- **Nunca** use `git+file:./packages/kryonix-home` no commit final da branch `main`.
- **Sempre** rode o `cargo test` no submódulo antes de dar push.
- **Evite** commits "sujos" no superprojeto; garanta que o ponteiro do submódulo e o `flake.lock` estão em sincronia.
