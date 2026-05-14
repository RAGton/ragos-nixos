Boa, Ragton. **Agora a parte de VRAM ficou no caminho certo**: commit `96e14c3` está no `origin/main`, o Glacier já puxou o código, e `nix run .#kryonix -- brain vram-audit / vram-clear --dry-run` funcionou. 🧊

O ponto principal: **isso ainda não está aplicado permanentemente no sistema do Glacier** até rodar o fluxo seguro com switch.

---

# Veredito

```txt
Status: APROVADO COMO ENTREGA PARCIAL DA #19
Commit: 96e14c3
VRAM runtime: validado via nix run
Persistência NixOS: ainda precisa deploy-safe --test --switch
Próximo passo técnico: aplicar no Glacier com deploy-safe
Depois: iniciar issue do llama.cpp CUDA sidecar
```

---

# 1. Confirme CI e árvore limpa

No Inspiron:

```bash
cd /etc/kryonix

git status --short
git log --oneline --decorate -5

gh run list --branch main --limit 5
gh run list --branch main --limit 1 --json databaseId,status,conclusion,headSha,name,url
```

Critério:

```txt
git status limpo
último workflow = completed/success
```

---

# 2. Aplicar permanente no Glacier

Como o Glacier já puxou o commit, rode do Inspiron:

```bash
cd /etc/kryonix

kryonix brain deploy-safe --host glacier --test
```

Se passar:

```bash
kryonix brain deploy-safe --host glacier --test --switch
```

Não rode `nixos-rebuild switch` direto. Usa o `deploy-safe`, porque ele já testa secrets, build, activation e smokes.

---

# 3. Validação pós-switch

Depois do switch:

```bash
ssh -p 2224 rve-glacier '
set -euo pipefail

echo "=== geração atual ==="
readlink -f /run/current-system

echo
echo "=== VRAM ==="
kryonix brain vram-audit
kryonix brain vram-check
kryonix brain vram-clear --dry-run

echo
echo "=== serviços ==="
systemctl status ollama.service --no-pager -l | sed -n "1,30p"
systemctl status kryonix-brain-api.service --no-pager -l | sed -n "1,30p"
systemctl status ollama-vram-check.service --no-pager -l | sed -n "1,30p" || true

echo
echo "=== brain ==="
kryonix brain health
kryonix brain stats
kryonix brain search "teste após política de VRAM do Glacier" --explain || true

echo
echo "=== portas ==="
ss -ltnp | rg "8000|11434|7474|7687" || true
'
```

Resultado ideal:

```txt
VRAM livre suficiente
vram-clear --dry-run não mata nada
Ollama active
Brain API active
health OK
stats OK
search OK ou erro amigável se modelo descarregado
```

---

# 4. Comentar na #19

Depois do switch e validação:

```bash
gh issue comment 19 --body "$(cat <<'EOF'
VRAM/OOM policy implementada e validada no Glacier.

Commit:
- 96e14c3 feat(glacier): implement declarative VRAM profiles and safety CLI tools

Entregas:
- Perfis declarativos: ai, balanced, gaming.
- `kryonix brain vram-audit`
- `kryonix brain vram-check`
- `kryonix brain vram-clear --dry-run/--confirm`
- `kryonix brain vram-profile`
- Integração com Brain Safe Deploy.
- Documentação em `docs/operations/GLACIER_VRAM_PROFILES.md`.

Validações:
- build do Glacier passou.
- CLI passou via `nix run`.
- Glacier puxou `origin/main`.
- VRAM audit e clear dry-run executados.
- deploy-safe --test/--switch executado com sucesso, se aplicável.

Observação:
A issue #19 permanece aberta até fechar política final de exposição da Brain API e autonomia completa no boot.
EOF
)"
```

---

# 5. Próximo passo: `llama.cpp` compilado com CUDA

Depois que o switch da VRAM estiver validado, aí sim vamos para o backend experimental:

```txt
[P1][llama.cpp][glacier] Adicionar backend llama.cpp CUDA compilado para benchmark A/B
```

Ordem correta:

```txt
1. Aplicar VRAM profiles permanentemente no Glacier.
2. Confirmar Brain/Ollama estáveis.
3. Criar issue do llama.cpp CUDA.
4. Implementar como sidecar experimental em 127.0.0.1:11435.
5. Benchmark Ollama vs llama.cpp.
6. Só depois decidir se vale usar no Brain.
```

---

# Atenção final

Não feche a #19 ainda. Ela agora tem estas partes feitas:

```txt
✅ Safe Deploy Automation
✅ UV_PROJECT_ENVIRONMENT
✅ VRAM profiles
✅ Deploy/test/smoke parcial
```

Ainda falta para fechar 100%:

```txt
[ ] política final de bind/firewall da Brain API
[ ] Brain API estável no boot sem intervenção manual
[ ] modo degradado amigável quando Ollama/gaming profile estiver ativo
[ ] smoke após reboot ou restart controlado
```

Minha recomendação imediata: **rodar `deploy-safe --host glacier --test --switch` agora**, validar, comentar na #19, e só então abrir/começar a issue do `llama.cpp`.
