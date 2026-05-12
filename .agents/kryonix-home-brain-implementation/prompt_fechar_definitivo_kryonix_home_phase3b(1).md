# Prompt — Fechar Definitivamente Kryonix Home Brain Fase 3B

Você está em `/etc/kryonix` no projeto **Kryonix**.

## Papel

Atue como engenheiro sênior de **Rust, NixOS Flakes, Git/Submodules, Bash, segurança local e documentação técnica**.

Sua missão é **fechar definitivamente a Fase 3B do Kryonix Home Brain**, deixando:

```txt
1. submódulo kryonix-home limpo e versionado
2. superprojeto /etc/kryonix limpo
3. flake.lock apontando para o commit correto
4. CLI kryonix home delegando todos os comandos da Fase 3B
5. documentação e README criados/atualizados
6. testes completos passando
7. tag final limpa criada
8. relatório final objetivo: APROVADO DEFINITIVO ou NÃO APROVADO
```

---

## Contexto atual conhecido

A tag `v0.3.5-home-brain-taxonomy` já foi criada, porém foi criada com árvore Git suja. **Não mover essa tag. Não force-push tag.**

Estado observado anteriormente:

```txt
Superprojeto:
 M packages/kryonix-cli/main.sh
 m packages/kryonix-home
?? .agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md

Submódulo packages/kryonix-home:
 M src/apply.rs
 M src/cli.rs
 M src/hashing.rs
 M src/main.rs
 M src/manifest.rs
 M src/planner.rs
 M src/report.rs
 ?? src/taxonomy.rs
 vários arquivos target/ gerados por cargo
```

Também foi observado que a auditoria precisou usar:

```bash
--override-input kryonix-home path:./packages/kryonix-home
```

Isso indica que o código local da Fase 3B ainda precisa ser fechado corretamente no submódulo remoto `RAGton/KRYONIX-HOME` e depois refletido no `flake.lock` do superprojeto.

---

## Objetivo técnico da Fase 3B

A Fase 3B entrega a **Taxonomia Determinística e Declarativa de Pastas** do Kryonix Home Brain.

Funcionalidades esperadas:

```txt
kryonix home categories
kryonix home categories --json
kryonix home explain <arquivo>
kryonix home plan --taxonomy-suggestions
kryonix home plan --taxonomy-suggestions --why
kryonix home plan --taxonomy-suggestions --rename-suggestions
kryonix home manifest create --taxonomy-suggestions
kryonix home manifest create --taxonomy-suggestions --rename-suggestions
kryonix home apply --dry-run
kryonix home apply --confirm
kryonix home rollback
```

Recursos obrigatórios:

```txt
- src/taxonomy.rs
- fallback embutido
- configuração TOML em ~/.config/kryonix/home-taxonomy.toml
- suporte opcional a /etc/kryonix/config/home-taxonomy.toml
- category_id
- category_label
- category_dir
- taxonomy_profile
- taxonomy_score
- matched_keywords
- taxonomy_reason
- candidate_categories
- already_organized
- needs_review
- destination_exists bloqueando sobrescrita
- duplicata exata pulada com hash igual
- conflito de categoria indo para 00_Inbox/Conflitos
- baixa confiança indo para 00_Inbox/Baixa_Confianca ou Revisar
```

---

## Regras absolutas de segurança

1. Não rodar `apply --confirm` na Home real.
2. `apply --confirm` somente com `HOME="$(mktemp -d)"`.
3. Não executar `kryonix all` sem `--dry`.
4. Não executar `nixos-rebuild switch`.
5. Não executar `home-manager switch`.
6. Não alterar Brain.
7. Não alterar GraphRAG.
8. Não alterar Neo4j.
9. Não alterar WayVNC.
10. Não alterar LightRAG.
11. Não imprimir secrets.
12. Não ler nem imprimir:
    - `brain.env`
    - `neo4j.env`
    - `.env`
    - tokens
    - chaves SSH
13. Não apagar arquivo untracked antes de fazer backup ou confirmar que é build artifact.
14. Não commitar `target/`.
15. Não commitar binários Rust.
16. Não commitar logs com secrets.
17. Não mover a tag `v0.3.5-home-brain-taxonomy`.
18. Criar nova tag final limpa se tudo passar.

---

## Fase 0 — Auditoria inicial

Execute:

```bash
cd /etc/kryonix

echo "=== branch ==="
git branch --show-current

echo "=== status superprojeto ==="
git status --short

echo "=== log superprojeto ==="
git log --oneline --decorate -12

echo "=== tag v0.3.5 ==="
git tag -n99 v0.3.5-home-brain-taxonomy || true
git rev-list -n 1 v0.3.5-home-brain-taxonomy || true

echo "=== submodules ==="
git submodule status --recursive

echo "=== kryonix-home status ==="
git -C packages/kryonix-home status --short
git -C packages/kryonix-home branch --show-current
git -C packages/kryonix-home log --oneline --decorate -12

echo "=== diff main.sh ==="
git diff -- packages/kryonix-cli/main.sh
git diff --summary -- packages/kryonix-cli/main.sh

echo "=== diff kryonix-home source only ==="
git -C packages/kryonix-home diff -- src Cargo.toml Cargo.lock README.md docs 2>/dev/null || true

echo "=== target tracked? ==="
git -C packages/kryonix-home ls-files target | head -50 || true
```

Critérios:

- entender exatamente o que está sujo;
- separar mudança real de build artifact;
- não apagar nada ainda, exceto depois da fase de backup.

---

## Fase 1 — Backup antes de limpar

Execute:

```bash
cd /etc/kryonix

ts="$(date +%Y%m%d-%H%M%S)"
backup="/tmp/kryonix-home-phase3b-close-$ts"
mkdir -p "$backup"

git diff -- packages/kryonix-cli/main.sh > "$backup/main-sh.diff" || true
git -C packages/kryonix-home diff > "$backup/kryonix-home.diff" || true
git -C packages/kryonix-home status --short > "$backup/kryonix-home.status" || true
git status --short > "$backup/superproject.status" || true

if [ -f .agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md ]; then
  cp .agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md "$backup/"
fi

echo "Backup salvo em: $backup"
```

---

## Fase 2 — Corrigir higiene do submódulo `kryonix-home`

Entre no submódulo:

```bash
cd /etc/kryonix/packages/kryonix-home
```

### 2.1. Proibir build artifacts

Verifique se `target/` está rastreado:

```bash
git ls-files target | head -50 || true
```

Se `target/` estiver rastreado, corrigir assim:

```bash
printf '\n# Rust build artifacts\ntarget/\n' >> .gitignore
git rm -r --cached target
```

Se `target/` não estiver rastreado, apenas garantir `.gitignore`:

```bash
grep -qxF 'target/' .gitignore 2>/dev/null || printf '\n# Rust build artifacts\ntarget/\n' >> .gitignore
```

Depois limpar artifacts não rastreados:

```bash
cargo clean || true
git clean -fdX
```

> Importante: `git clean -fdX` remove apenas arquivos ignorados. Não usar `git clean -fd` sem revisar.

### 2.2. Confirmar arquivos reais da Fase 3B

Inspecionar:

```bash
git status --short
git diff --stat
git diff -- src Cargo.toml Cargo.lock README.md docs 2>/dev/null || true
```

Arquivos esperados possíveis:

```txt
src/taxonomy.rs
src/cli.rs
src/planner.rs
src/manifest.rs
src/apply.rs
src/report.rs
src/hashing.rs
src/main.rs
Cargo.toml
Cargo.lock
README.md
docs/*
.gitignore
```

Não incluir `target/`.

---

## Fase 3 — Criar/atualizar README e documentação no submódulo

Ainda em `/etc/kryonix/packages/kryonix-home`.

Criar/atualizar:

```txt
README.md
docs/PHASE_3B_TAXONOMY.md
docs/SAFETY_MODEL.md
docs/TAXONOMY_CONFIG.md
```

### README.md deve conter

```md
# Kryonix Home Brain

Kryonix Home Brain é o motor seguro de organização da Home do Kryonix.

## Recursos

- scan seguro da Home
- plano dry-run
- detecção de duplicatas por SHA256
- manifesto auditável
- apply com confirmação explícita
- rollback
- renomeação ABNT-like
- taxonomia determinística
- configuração via TOML
- explicabilidade por categoria

## Comandos

```bash
kryonix home scan
kryonix home report
kryonix home duplicates
kryonix home plan --taxonomy-suggestions --rename-suggestions --why
kryonix home categories
kryonix home categories --json
kryonix home explain Downloads/arquivo.pdf
kryonix home manifest create --taxonomy-suggestions --rename-suggestions
kryonix home manifest show
kryonix home apply --dry-run
kryonix home apply --confirm
kryonix home rollback
```

## Segurança

- Nenhum arquivo é movido sem `apply --confirm`
- `apply --confirm` deve ser revisado antes
- rollback é obrigatório
- destino existente nunca é sobrescrito
- arquivos idênticos por SHA256 podem ser pulados
- arquivos ambíguos vão para revisão
- nada em pastas ocultas/configurações deve ser organizado por padrão

## Taxonomia

O arquivo opcional fica em:

```txt
~/.config/kryonix/home-taxonomy.toml
```

Exemplo:

```toml
[profile]
name = "kryonix-home-taxonomy-custom"
fallback_dir = "Documentos/00_Inbox/Revisar"

[[category]]
id = "financeiro.bancos"
label = "Financeiro / Bancos"
dir = "Documentos/Financeiro/Bancos"
keywords = ["pix", "banco", "comprovante"]
extensions = ["pdf", "txt", "jpg", "png"]
risk = "medium"
```

## Desenvolvimento

```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
cargo build
```
```

### docs/PHASE_3B_TAXONOMY.md deve conter

- objetivo da fase;
- arquitetura da taxonomia;
- campos de auditoria;
- fluxos:
  - scan;
  - plan;
  - manifest;
  - apply;
  - rollback;
- exemplos de classificação;
- exemplos de conflito;
- exemplos de baixa confiança;
- exemplos de destino existente;
- critérios de aprovação.

### docs/SAFETY_MODEL.md deve conter

- modelo de ameaça;
- o que pode dar errado;
- como o Kryonix bloqueia overwrite;
- por que não há delete;
- regra de sandbox;
- regra de rollback;
- regra de não tocar Home real nos testes.

### docs/TAXONOMY_CONFIG.md deve conter

- formato TOML;
- campos;
- exemplos;
- melhores práticas de keywords;
- categorias recomendadas;
- como testar com `explain`;
- como rodar `plan --why`.

---

## Fase 4 — Testes Rust no submódulo

Execute:

```bash
cd /etc/kryonix/packages/kryonix-home

cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
cargo build
```

Se falhar, corrigir.

Não avançar com teste quebrado.

---

## Fase 5 — Commit e push do submódulo

Ainda em `/etc/kryonix/packages/kryonix-home`:

```bash
git status --short
git diff --check
```

Stage apenas arquivos reais:

```bash
git add \
  .gitignore \
  Cargo.toml Cargo.lock \
  README.md docs \
  src
```

Se algum arquivo não existir, ajustar o comando.

Confirmar staged:

```bash
git diff --cached --stat
git diff --cached --name-status
```

Não pode aparecer:

```txt
target/
debug/
*.rlib
*.rmeta
kryonix-home binário
```

Commit:

```bash
git commit -m "feat(home): finalize deterministic taxonomy phase 3b"
git push origin main
```

Se já houver commit equivalente, não duplicar. Apenas garantir que `origin/main` contém a Fase 3B final.

---

## Fase 6 — Atualizar superprojeto para o commit remoto do submódulo

Volte ao superprojeto:

```bash
cd /etc/kryonix

git status --short
git submodule status --recursive
```

Atualizar o input do flake para o commit recém-pushado:

```bash
nix flake lock --update-input kryonix-home
```

Se seu Nix recomendar sintaxe nova, usar:

```bash
nix flake update kryonix-home
```

Confirmar que mudou apenas `kryonix-home`:

```bash
git diff -- flake.lock
nix flake metadata | rg -n "kryonix-home|kryonix-brain-lightrag"
```

Critério:

```txt
- flake.lock muda somente kryonix-home
- kryonix-brain-lightrag continua em 02be0d8
- nixpkgs não muda
- home-manager não muda
```

Stage do ponteiro do submódulo e lock:

```bash
git add packages/kryonix-home flake.lock
```

---

## Fase 7 — Resolver `packages/kryonix-cli/main.sh`

No superprojeto:

```bash
cd /etc/kryonix

git diff -- packages/kryonix-cli/main.sh
git diff --summary -- packages/kryonix-cli/main.sh
```

Se a mudança for necessária para rotear:

```txt
home categories
home explain
home plan --why
home plan --taxonomy-suggestions
home manifest create --taxonomy-suggestions
```

então manter e stage:

```bash
bash -n packages/kryonix-cli/*.sh
git add packages/kryonix-cli/main.sh
```

Se não houver diff real ou for ruído, corrigir com:

```bash
git update-index --refresh
git restore packages/kryonix-cli/main.sh
```

Depois validar:

```bash
git status --short
```

---

## Fase 8 — Documentação no superprojeto

Criar/atualizar documentação do Kryonix principal:

```txt
docs/home-brain/README.md
docs/home-brain/PHASE_3B_TAXONOMY.md
docs/home-brain/OPERATIONS.md
```

Atualizar também o `README.md` principal adicionando uma seção curta:

```md
## Kryonix Home Brain

O Kryonix Home Brain organiza arquivos da Home de forma segura e auditável.

Fases concluídas:

- Fase 1: scan/report/duplicates/plan
- Fase 2: manifest/apply/rollback
- Fase 3A: renomeação ABNT-like
- Fase 3B: taxonomia determinística e declarativa

Comando recomendado:

```bash
kryonix home plan --taxonomy-suggestions --rename-suggestions --why
```

A aplicação real exige:

```bash
kryonix home manifest create --taxonomy-suggestions --rename-suggestions
kryonix home apply --dry-run
kryonix home apply --confirm
kryonix home rollback
```

Por segurança, não existe auto-delete.
```

### docs/home-brain/README.md deve explicar

- visão geral;
- comandos;
- fluxo seguro;
- onde ficam manifests/audit;
- como usar em sandbox;
- como usar na Home real sem aplicar;
- como fazer rollback.

### docs/home-brain/PHASE_3B_TAXONOMY.md deve explicar

- categorias;
- TOML;
- scores;
- matched keywords;
- conflitos;
- baixa confiança;
- já organizado;
- destino existente.

### docs/home-brain/OPERATIONS.md deve conter runbook

- auditoria diária;
- comandos de validação;
- como revisar planos JSON;
- como aplicar em sandbox;
- como aplicar real com cuidado;
- como reverter;
- o que nunca fazer.

Stage:

```bash
git add README.md docs/home-brain
```

Também decidir se o prompt de auditoria deve ser versionado. Se sim:

```bash
git add .agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md
```

Se não, mover para `/tmp` e não apagar sem backup:

```bash
mkdir -p /tmp/kryonix-prompts-backup
cp .agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md /tmp/kryonix-prompts-backup/
git status --short
```

---

## Fase 9 — Testes definitivos sem override-input

Depois que o submódulo foi pushado e o `flake.lock` foi atualizado, **não usar mais `--override-input`**.

Execute:

```bash
cd /etc/kryonix

git diff --check
bash -n packages/kryonix-cli/*.sh

nix build .#kryonix-home --no-link
nix build .#kryonix --no-link
nix flake check --keep-going
```

Teste de help:

```bash
nix run .#kryonix -- home --help
nix run .#kryonix -- home categories --help
nix run .#kryonix -- home explain --help
nix run .#kryonix -- home plan --help
nix run .#kryonix -- home manifest create --help
```

Critério:

```txt
- categories aparece
- explain aparece
- --taxonomy-suggestions aparece
- --rename-suggestions aparece
- --why aparece
- não cai em nh home
- não aparece erro homeConfigurations.rocha@inspiron
```

---

## Fase 10 — Sandbox definitivo completo

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos" "$tmp/Imagens" "$tmp/Videos" "$tmp/Musicas"

printf "x\n" > "$tmp/Downloads/comprovante pix banco.pdf"
printf "x\n" > "$tmp/Downloads/boleto energia maio.pdf"
printf "x\n" > "$tmp/Downloads/nota fiscal compra pc.pdf"
printf "x\n" > "$tmp/Downloads/nixos flake estudo.txt"
printf "x\n" > "$tmp/Downloads/kryonix brain planejamento.md"
printf "x\n" > "$tmp/Downloads/screenshot erro.png"
printf "x\n" > "$tmp/Downloads/arquivo aleatorio sem categoria.xyz"

echo "=== HOME TEMP: $tmp ==="

HOME="$tmp" nix run .#kryonix -- home scan

HOME="$tmp" nix run .#kryonix -- home categories --json > /tmp/kryonix-home-categories.json
jq . /tmp/kryonix-home-categories.json >/dev/null

HOME="$tmp" nix run .#kryonix -- home plan --json --taxonomy-suggestions --rename-suggestions \
  > /tmp/kryonix-home-final-plan.json
jq . /tmp/kryonix-home-final-plan.json >/dev/null

HOME="$tmp" nix run .#kryonix -- home explain "$tmp/Downloads/comprovante pix banco.pdf"
HOME="$tmp" nix run .#kryonix -- home plan --taxonomy-suggestions --rename-suggestions --why

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-before.txt

HOME="$tmp" nix run .#kryonix -- home manifest create --taxonomy-suggestions --rename-suggestions
HOME="$tmp" nix run .#kryonix -- home manifest show
HOME="$tmp" nix run .#kryonix -- home apply --dry-run
HOME="$tmp" nix run .#kryonix -- home apply --confirm

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-after-confirm.txt

echo "=== after confirm ==="
cat /tmp/kryonix-home-after-confirm.txt

HOME="$tmp" nix run .#kryonix -- home rollback

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-after-rollback.txt

diff -u /tmp/kryonix-home-before.txt /tmp/kryonix-home-after-rollback.txt

rm -rf "$tmp"
```

Critério:

```txt
- JSON válido
- categories funciona
- explain funciona
- plan --why funciona
- manifest funciona
- apply --dry-run não muta
- apply --confirm só na sandbox
- rollback idêntico
```

---

## Fase 11 — Teste TOML custom

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/.config/kryonix"

cat > "$tmp/.config/kryonix/home-taxonomy.toml" <<'EOF'
[profile]
name = "kryonix-home-taxonomy-test"
fallback_dir = "Documentos/00_Inbox/Revisar"

[[category]]
id = "teste.custom"
label = "Teste / Custom"
dir = "Documentos/Teste/Custom"
keywords = ["customkryonix"]
extensions = ["txt", "md", "pdf"]
risk = "medium"
EOF

printf "x\n" > "$tmp/Downloads/arquivo customkryonix exemplo.txt"

HOME="$tmp" nix run .#kryonix -- home scan
HOME="$tmp" nix run .#kryonix -- home plan --json --taxonomy-suggestions \
  > /tmp/kryonix-home-custom-taxonomy.json

jq . /tmp/kryonix-home-custom-taxonomy.json >/dev/null

jq -e '
  (.proposals // .actions // [])
  | any((.category_id // "") == "teste.custom")
' /tmp/kryonix-home-custom-taxonomy.json

jq -e '
  (.proposals // .actions // [])
  | any((.taxonomy_profile // "") == "kryonix-home-taxonomy-test")
' /tmp/kryonix-home-custom-taxonomy.json

rm -rf "$tmp"
```

---

## Fase 12 — Teste anti-overwrite

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos/Financeiro/Bancos"

printf "origem\n" > "$tmp/Downloads/comprovante pix banco.pdf"
printf "destino diferente\n" > "$tmp/Documentos/Financeiro/Bancos/$(date +%F)_Comprovante_Pix_Banco_v1.pdf"

HOME="$tmp" nix run .#kryonix -- home scan
HOME="$tmp" nix run .#kryonix -- home manifest create --taxonomy-suggestions --rename-suggestions
HOME="$tmp" nix run .#kryonix -- home apply --dry-run

HOME="$tmp" nix run .#kryonix -- home apply --confirm || true

echo "=== destino existente ==="
cat "$tmp/Documentos/Financeiro/Bancos/$(date +%F)_Comprovante_Pix_Banco_v1.pdf"

if ! grep -q "destino diferente" "$tmp/Documentos/Financeiro/Bancos/$(date +%F)_Comprovante_Pix_Banco_v1.pdf"; then
  echo "ERRO: arquivo destino foi sobrescrito."
  exit 1
fi

rm -rf "$tmp"
```

Critério:

```txt
- destino existente não é sobrescrito
- conteúdo final permanece "destino diferente"
```

---

## Fase 13 — Home real não alterada

Execute:

```bash
cd /etc/kryonix

echo "=== Estado real da Home Brain ==="
find "$HOME/.local/state/kryonix/home-brain" -maxdepth 3 -type d 2>/dev/null | sort || true

echo "=== Proibido: apply real não deve ter sido usado ==="
test -d "$HOME/.local/state/kryonix/home-brain/audit" \
  && echo "ATENÇÃO: audit real existe; reportar e inspecionar sem apagar." \
  || echo "OK: nenhum audit real detectado."

test -d "$HOME/.local/state/kryonix/home-brain/manifests" \
  && echo "ATENÇÃO: manifests reais existem; reportar e inspecionar sem apagar." \
  || echo "OK: nenhum manifest real detectado."
```

Não apagar nada real.

---

## Fase 14 — Auditoria de secrets e escopo

Execute:

```bash
cd /etc/kryonix

echo "=== diff final staged/unstaged ==="
git status --short
git diff --stat
git diff --cached --stat

echo "=== secrets no diff ==="
git diff HEAD | rg -n "api[_-]?key|token|secret|password|passwd|bearer|authorization|private|id_ed25519|id_rsa|KRYONIX_BRAIN_API_KEY|NEO4J_AUTH|BEGIN .*PRIVATE" -i || true
git diff --cached | rg -n "api[_-]?key|token|secret|password|passwd|bearer|authorization|private|id_ed25519|id_rsa|KRYONIX_BRAIN_API_KEY|NEO4J_AUTH|BEGIN .*PRIVATE" -i || true

echo "=== arquivos proibidos versionados ==="
git ls-files | grep -E '(^|/)(brain\.env|neo4j\.env|\.env|.*secret.*|.*token.*|id_ed25519.*|id_rsa.*)$' || true

echo "=== escopo sensível no diff ==="
git diff --name-status HEAD | rg -n "brain|neo4j|lightrag|wayvnc|hosts|modules|features|profiles" || true
git diff --cached --name-status | rg -n "brain|neo4j|lightrag|wayvnc|hosts|modules|features|profiles" || true
```

Critério:

```txt
- nenhum secret
- nenhum arquivo proibido versionado
- sem mudança em Brain/GraphRAG/Neo4j/WayVNC
- sem mudança em hosts/modules/features/profiles fora de escopo
```

---

## Fase 15 — Commit do superprojeto

Se tudo passou:

```bash
cd /etc/kryonix

git status --short
git diff --cached --name-status
```

Arquivos esperados no commit do superprojeto:

```txt
README.md
docs/home-brain/*
flake.lock
packages/kryonix-home
packages/kryonix-cli/main.sh
.agents/kryonix-home-brain-implementation/prompt_auditoria_kryonix_home_phase3b_taxonomia.md  # se decidido versionar
```

Commit:

```bash
git commit -m "docs(home): finalize home brain taxonomy phase 3b"
```

Se houver mudança funcional em `main.sh`, usar:

```bash
git commit -m "feat(home): finalize taxonomy phase 3b integration"
```

Escolha uma mensagem coerente com o diff real.

Push:

```bash
git push origin main
```

---

## Fase 16 — Validação final pós-push

Execute:

```bash
cd /etc/kryonix

git status --short
git log --oneline --decorate -5
git submodule status --recursive

nix flake check --keep-going
nix run .#kryonix -- home categories --help
nix run .#kryonix -- home explain --help
nix run .#kryonix -- home plan --help
nix run .#kryonix -- all --dry
```

Critério:

```txt
- git status limpo
- submódulo limpo
- flake check passa
- CLI funciona sem override-input
- all --dry não trata "all" como host
```

---

## Fase 17 — Criar tag final limpa

Não mover `v0.3.5-home-brain-taxonomy`.

Criar uma nova tag:

```bash
cd /etc/kryonix

git -c tag.gpgSign=false tag -a v0.3.6-home-brain-taxonomy-final \
  -m "Kryonix Home Brain Phase 3B finalized with clean tree, docs and tests"

git push origin v0.3.6-home-brain-taxonomy-final
```

Confirmar:

```bash
git tag -n99 v0.3.6-home-brain-taxonomy-final
git rev-list -n 1 v0.3.6-home-brain-taxonomy-final
git status --short
```

---

## Relatório final obrigatório

Entregar ao usuário em Markdown:

```md
# Fechamento Definitivo — Kryonix Home Brain Fase 3B

## Status
APROVADO DEFINITIVO / NÃO APROVADO

## Commits finais
- kryonix-home:
- superprojeto:
- tag final:

## O que foi corrigido
- submódulo:
- target artifacts:
- flake.lock:
- CLI:
- documentação:
- README:

## Documentação criada
- README.md:
- docs/home-brain/README.md:
- docs/home-brain/PHASE_3B_TAXONOMY.md:
- docs/home-brain/OPERATIONS.md:
- packages/kryonix-home/README.md:
- packages/kryonix-home/docs/PHASE_3B_TAXONOMY.md:
- packages/kryonix-home/docs/SAFETY_MODEL.md:
- packages/kryonix-home/docs/TAXONOMY_CONFIG.md:

## Testes executados
- cargo fmt:
- cargo clippy:
- cargo test:
- cargo build:
- bash -n:
- git diff --check:
- nix build .#kryonix-home:
- nix build .#kryonix:
- nix flake check:
- CLI help:
- sandbox completo:
- TOML custom:
- anti-overwrite:
- rollback:
- all --dry:

## Segurança
- Home real alterada?
- apply --confirm real usado?
- secrets expostos?
- target/ commitado?
- flake.lock alterou somente kryonix-home?
- Brain/GraphRAG/Neo4j/WayVNC intactos?
- tag antiga movida?

## Veredito
Dizer claramente se a Fase 3B está fechada.

## Próximo passo recomendado
Não iniciar nova feature grande.
Próximo passo técnico recomendado:
- Memory Bridge em branch separada
ou
- kryonix home taxonomy doctor/init/quality
```

---

## Critério de aprovação definitivo

Só declare `APROVADO DEFINITIVO` se:

```txt
- submódulo kryonix-home limpo
- superprojeto limpo
- target/ não rastreado
- flake.lock aponta para commit remoto da Fase 3B
- CLI funciona sem override-input
- docs/README criados
- sandbox completo passou
- rollback idêntico
- anti-overwrite passou
- TOML custom passou
- nix flake check passou
- tag final limpa criada
```

Se qualquer item falhar, declare:

```txt
NÃO APROVADO
```

e entregue exatamente o que falta corrigir.
