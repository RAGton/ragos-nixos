# Prompt para Claude Opus — Auditoria e Melhorias da Fase 3B do Kryonix Home Brain

Você está em `/etc/kryonix` no projeto **Kryonix**.

## Papel

Atue como auditor e engenheiro sênior de **Rust, NixOS Flakes, Bash, segurança de dados locais e CLI UX**.

Sua tarefa é **auditar profundamente a Fase 3B do Kryonix Home Brain — Taxonomia Declarativa e Auditável de Pastas** e, se necessário, aplicar apenas correções pequenas e seguras.

A Fase 3B organiza arquivos por categoria, então qualquer falha pode mover arquivos para destinos errados. Trate como recurso crítico.

---

## Contexto atual

O Kryonix Home Brain já possui:

### Fase 1 — Fechada

- `scan`
- `report`
- `duplicates`
- `plan --dry-run`
- `plan --json`
- scanner seguro
- SHA256 para duplicatas exatas
- sem mutação

### Fase 2 — Fechada

- `manifest create`
- `manifest show`
- `apply --dry-run`
- `apply --confirm`
- `rollback`
- audit logs
- rollback validado em sandbox
- nenhuma mutação na Home real

### Fase 2.2 — Fechada

- `kryonix home manifest --help` delegado ao Rust
- `kryonix home apply --help` delegado ao Rust
- `kryonix home rollback --help` delegado ao Rust
- wrapper shell corrigido

### Fase 3A — Fechada

- `--rename-suggestions`
- perfil `kryonix-abnt-like-v1`
- nomes limpos determinísticos
- manifesto registra renames
- apply/rollback validados em sandbox

### Fase 3B — Implementada e precisa de auditoria final

Segundo relatório anterior, foram implementados:

- `src/taxonomy.rs`
- taxonomia declarativa via TOML
- fallback embutido
- `--taxonomy-suggestions`
- `--taxonomy-config`
- `--include-large-files`
- `--safe-only`
- `--review-only`
- `categories`
- `explain <PATH>`
- `plan --why`
- campos de explicabilidade:
  - `category_id`
  - `category_label`
  - `category_dir`
  - `taxonomy_profile`
  - `taxonomy_score`
  - `matched_keywords`
  - `taxonomy_reason`
  - `candidate_categories`
  - `already_organized`
- tratamento de conflitos
- baixa confiança
- mídia com `needs_review`
- arquivo sem extensão com risco alto
- destino existente bloqueado
- duplicata exata detectada por hash
- 19 testes unitários passando
- `nix flake check --keep-going` passando

---

## Objetivo desta tarefa

Auditar se a Fase 3B está realmente pronta para uso diário no Inspiron.

Você deve responder:

```txt
APROVADO / PARCIAL / REPROVADO
```

Também deve propor melhorias futuras sem misturar com esta auditoria.

---

## Regras absolutas de segurança

1. Não rodar `apply --confirm` na Home real.
2. `apply --confirm` só pode rodar com `HOME="$(mktemp -d)"`.
3. Não rodar `kryonix all` sem `--dry`.
4. Não rodar `nixos-rebuild switch`.
5. Não rodar `home-manager switch`.
6. Não alterar Brain.
7. Não alterar GraphRAG.
8. Não alterar Neo4j.
9. Não alterar WayVNC.
10. Não alterar LightRAG.
11. Não atualizar `flake.lock`.
12. Não apagar arquivos untracked.
13. Não imprimir secrets.
14. Não ler ou imprimir `brain.env`, `neo4j.env`, `.env`, tokens ou chaves SSH.
15. Não commitar nada antes do relatório de auditoria.
16. Se algum teste de rollback falhar, parar e reportar.
17. Se algum `apply --confirm` atingir Home real, marcar REPROVADO.

---

## Fase 0 — Estado inicial do repositório

Execute:

```bash
cd /etc/kryonix

echo "=== branch ==="
git branch --show-current

echo "=== status ==="
git status --short

echo "=== últimos commits superprojeto ==="
git log --oneline --decorate -12

echo "=== último commit superprojeto ==="
git show --name-status --oneline HEAD
git show --stat --oneline HEAD

echo "=== submodules ==="
git submodule status --recursive

echo "=== kryonix-home status ==="
git -C packages/kryonix-home status --short
git -C packages/kryonix-home log --oneline --decorate -12

echo "=== flake metadata ==="
nix flake metadata | rg -n "kryonix-home|kryonix-brain-lightrag"
```

Critérios:

- superprojeto deve estar limpo ou conter apenas arquivos documentais não rastreados;
- `packages/kryonix-home` deve estar limpo;
- `packages/kryonix-brain-lightrag` não pode ter mudado;
- `kryonix-brain-lightrag` deve continuar no commit `02be0d8`;
- `kryonix-home` deve apontar para o commit da Fase 3B.

Se houver alterações fora de escopo, parar e reportar antes de continuar.

---

## Fase 1 — Isolamento do `flake.lock`

Execute:

```bash
cd /etc/kryonix

echo "=== diff flake.lock contra commit anterior ==="
git diff HEAD~1 -- flake.lock || true
```

Critério:

O diff deve alterar somente `kryonix-home`:

- `rev`
- `narHash`
- `lastModified`

Não pode alterar:

- `nixpkgs`
- `home-manager`
- `kryonix-brain-lightrag`
- outros inputs

Se outro input mudou, marcar `PARCIAL` ou `REPROVADO`.

---

## Fase 2 — Inspeção do código da taxonomia

Execute:

```bash
cd /etc/kryonix/packages/kryonix-home

echo "=== arquivos src ==="
ls -lah src

echo "=== campos e recursos de taxonomia ==="
rg -n "taxonomy|Taxonomy|home-taxonomy|taxonomy_profile|taxonomy_score|matched_keywords|taxonomy_reason|candidate_categories|already_organized|category_id|category_label|category_dir|explain|--why|safe-only|review-only|include-large-files|categories" src Cargo.toml

echo "=== CLI args ==="
rg -n "taxonomy-suggestions|taxonomy-config|rename-suggestions|explain|why|safe-only|review-only|include-large-files|categories" src/cli.rs src/main.rs src/planner.rs src/taxonomy.rs || true

echo "=== pontos de mutação ==="
rg -n "std::fs::rename|remove_file|remove_dir|delete|trash|unlink|create_dir|copy" src

echo "=== testes relacionados ==="
rg -n "test_|comprovante|boleto|nota fiscal|nixos|kryonix|screenshot|taxonomy|fallback|conflict|already_organized|destination|no_extension|media|toml|safe|review" src
```

Critérios:

- existe `src/taxonomy.rs`;
- existe carregamento de TOML;
- existe fallback embutido;
- existem campos de explicabilidade;
- existe `categories`;
- existe `explain`;
- existe `plan --why`;
- existem `--safe-only` e `--review-only`;
- mutação física acontece somente no fluxo `apply`;
- não existe delete automático.

---

## Fase 3 — Testes Rust

Execute:

```bash
cd /etc/kryonix/packages/kryonix-home

echo "=== cargo fmt ==="
cargo fmt --check

echo "=== cargo clippy ==="
cargo clippy --all-targets --all-features -- -D warnings

echo "=== cargo test ==="
cargo test --all

echo "=== cargo build ==="
cargo build
```

Critérios:

- `cargo fmt --check` passa;
- clippy passa com `-D warnings`;
- `cargo test --all` passa;
- `cargo build` passa;
- esperado: 19 testes ou mais.

---

## Fase 4 — Builds Nix e Flake Check

Execute:

```bash
cd /etc/kryonix

echo "=== nix build kryonix-home ==="
nix build .#kryonix-home --no-link

echo "=== nix build kryonix ==="
nix build .#kryonix --no-link

echo "=== nix flake check ==="
nix flake check --keep-going
```

Classificar warnings como:

```txt
bloqueante / não bloqueante / dívida técnica
```

Não corrigir deduplicação `system-path` nesta tarefa.

---

## Fase 5 — Testar comandos de UX

Execute:

```bash
cd /etc/kryonix

nix run .#kryonix -- home categories --help || true
nix run .#kryonix -- home explain --help || true
nix run .#kryonix -- home plan --help || true
nix run .#kryonix -- home manifest create --help || true
```

Critérios:

- `categories` aparece;
- `explain` aparece;
- `--taxonomy-suggestions` aparece;
- `--rename-suggestions` aparece;
- `--why` aparece se prometido;
- `--safe-only` e `--review-only` aparecem se implementados;
- nenhum comando cai em `nh home`;
- não aparece erro `homeConfigurations.rocha@inspiron`.

---

## Fase 6 — Taxonomia sem rename

Objetivo: provar que `--taxonomy-suggestions` funciona sozinho.

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

HOME="$tmp" nix run .#kryonix -- home plan --json --taxonomy-suggestions \
  > /tmp/kryonix-taxonomy-only-plan.json

jq . /tmp/kryonix-taxonomy-only-plan.json >/dev/null

echo "=== categorias encontradas ==="
jq '.proposals // .actions // [] | map({
  action,
  old_path,
  new_dir,
  category_id,
  category_label,
  category_dir,
  taxonomy_profile,
  taxonomy_score,
  matched_keywords,
  taxonomy_reason,
  candidate_categories,
  already_organized,
  needs_review
})' /tmp/kryonix-taxonomy-only-plan.json

echo "=== checar categoria financeira ==="
jq -e '
  (.proposals // .actions // [])
  | any((.category_id // "") | test("financeiro|bancos|boletos|notas"; "i"))
' /tmp/kryonix-taxonomy-only-plan.json

echo "=== checar categoria nixos/kryonix ==="
jq -e '
  (.proposals // .actions // [])
  | any((.category_id // "") | test("nixos|kryonix|projetos|estudos"; "i"))
' /tmp/kryonix-taxonomy-only-plan.json

echo "=== checar fallback/revisão ==="
jq -e '
  (.proposals // .actions // [])
  | any((.new_dir // .category_dir // "") | test("Revisar|Inbox|Baixa_Confianca|Conflitos"; "i"))
' /tmp/kryonix-taxonomy-only-plan.json

rm -rf "$tmp"
```

Critérios:

- JSON válido;
- categorias específicas aparecem;
- `taxonomy_profile` aparece;
- `taxonomy_score` aparece;
- `matched_keywords` aparece;
- `taxonomy_reason` aparece;
- fallback/revisão aparece;
- nenhuma mutação física fora do estado `.local` da HOME temporária.

---

## Fase 7 — Taxonomia + rename + manifest + apply/rollback

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

echo "=== HOME TEMP: $tmp ==="

HOME="$tmp" nix run .#kryonix -- home scan

HOME="$tmp" nix run .#kryonix -- home plan --json --rename-suggestions --taxonomy-suggestions \
  > /tmp/kryonix-taxonomy-rename-plan.json

jq . /tmp/kryonix-taxonomy-rename-plan.json >/dev/null

echo "=== propostas ==="
jq '.proposals // .actions // [] | map({
  action,
  old_path,
  new_dir,
  new_filename,
  category_id,
  category_label,
  category_dir,
  taxonomy_score,
  matched_keywords,
  naming_profile,
  taxonomy_profile,
  taxonomy_reason,
  reason,
  needs_review
})' /tmp/kryonix-taxonomy-rename-plan.json

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-tax-before.txt

echo "=== manifest create ==="
HOME="$tmp" nix run .#kryonix -- home manifest create --rename-suggestions --taxonomy-suggestions

echo "=== manifest show ==="
HOME="$tmp" nix run .#kryonix -- home manifest show

echo "=== apply dry-run ==="
HOME="$tmp" nix run .#kryonix -- home apply --dry-run

echo "=== apply confirm sandbox ==="
HOME="$tmp" nix run .#kryonix -- home apply --confirm

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-tax-after-confirm.txt

echo "=== after confirm ==="
cat /tmp/kryonix-tax-after-confirm.txt

echo "=== validar destinos específicos ==="
rg "Financeiro|Boletos|Notas|NixOS|Kryonix|Screenshots|Documentos" /tmp/kryonix-tax-after-confirm.txt || true

echo "=== rollback ==="
HOME="$tmp" nix run .#kryonix -- home rollback

find "$tmp" -maxdepth 8 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-tax-after-rollback.txt

echo "=== diff rollback ==="
diff -u /tmp/kryonix-tax-before.txt /tmp/kryonix-tax-after-rollback.txt

rm -rf "$tmp"
```

Critérios:

- plan gera taxonomy + rename;
- manifest registra categoria;
- apply dry-run não altera;
- apply confirm só na HOME temporária;
- arquivos vão para pastas específicas;
- nomes ficam limpos;
- rollback restaura exatamente;
- diff before vs after rollback idêntico.

---

## Fase 8 — Config TOML declarativa

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
  > /tmp/kryonix-taxonomy-config-plan.json

jq . /tmp/kryonix-taxonomy-config-plan.json >/dev/null

echo "=== config taxonomy result ==="
jq '.proposals // .actions // []' /tmp/kryonix-taxonomy-config-plan.json

echo "=== validar categoria custom ==="
jq -e '
  (.proposals // .actions // [])
  | any((.category_id // "") == "teste.custom")
' /tmp/kryonix-taxonomy-config-plan.json

echo "=== validar profile custom ==="
jq -e '
  (.proposals // .actions // [])
  | any((.taxonomy_profile // "") == "kryonix-home-taxonomy-test")
' /tmp/kryonix-taxonomy-config-plan.json

rm -rf "$tmp"
```

Critérios:

- TOML é carregado;
- categoria custom funciona;
- `taxonomy_profile` custom aparece;
- fallback segue seguro.

---

## Fase 9 — Explain, Why e Categories

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads"

printf "x\n" > "$tmp/Downloads/comprovante pix banco.pdf"
printf "x\n" > "$tmp/Downloads/nixos flake estudo.txt"

echo "=== categories ==="
HOME="$tmp" nix run .#kryonix -- home categories
HOME="$tmp" nix run .#kryonix -- home categories --json > /tmp/kryonix-categories.json
jq . /tmp/kryonix-categories.json >/dev/null

echo "=== explain comprovante ==="
HOME="$tmp" nix run .#kryonix -- home explain "$tmp/Downloads/comprovante pix banco.pdf"

echo "=== explain nixos ==="
HOME="$tmp" nix run .#kryonix -- home explain "$tmp/Downloads/nixos flake estudo.txt"

echo "=== plan why ==="
HOME="$tmp" nix run .#kryonix -- home scan
HOME="$tmp" nix run .#kryonix -- home plan --taxonomy-suggestions --why

rm -rf "$tmp"
```

Critérios:

- `categories` lista categorias;
- `categories --json` é JSON válido;
- `explain` mostra score, keywords, categoria e motivo;
- `plan --why` explica decisões.

---

## Fase 10 — Edge cases

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos/Financeiro/Bancos"

printf "x\n" > "$tmp/Downloads/kryonix banco backup.pdf"
printf "x\n" > "$tmp/Downloads/zzzz_sem_sentido_123.abc"
printf "x\n" > "$tmp/Downloads/documento_sem_extensao"
printf "x\n" > "$tmp/Documentos/Financeiro/Bancos/comprovante pix banco.pdf"

HOME="$tmp" nix run .#kryonix -- home scan

HOME="$tmp" nix run .#kryonix -- home plan --json --taxonomy-suggestions \
  > /tmp/kryonix-taxonomy-edge-plan.json

jq . /tmp/kryonix-taxonomy-edge-plan.json >/dev/null

echo "=== edge cases ==="
jq '.proposals // .actions // [] | map({
  old_path,
  new_dir,
  category_id,
  taxonomy_score,
  matched_keywords,
  candidate_categories,
  already_organized,
  needs_review,
  reason
})' /tmp/kryonix-taxonomy-edge-plan.json

rm -rf "$tmp"
```

Critérios:

- arquivo ambíguo deve ir para conflito ou `needs_review`;
- arquivo sem sentido deve ir para Inbox/Revisar ou Baixa_Confianca;
- arquivo sem extensão deve ter risco alto e revisão humana;
- arquivo já organizado não deve gerar ação real redundante ou deve ser marcado `already_organized`.

---

## Fase 11 — Destino existente / overwrite

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos/Financeiro/Bancos"

printf "origem\n" > "$tmp/Downloads/comprovante pix banco.pdf"
printf "destino diferente\n" > "$tmp/Documentos/Financeiro/Bancos/comprovante pix banco.pdf"

HOME="$tmp" nix run .#kryonix -- home scan
HOME="$tmp" nix run .#kryonix -- home plan --taxonomy-suggestions
HOME="$tmp" nix run .#kryonix -- home manifest create --taxonomy-suggestions
HOME="$tmp" nix run .#kryonix -- home apply --dry-run

echo "=== tentar apply confirm em sandbox com conflito destino ==="
HOME="$tmp" nix run .#kryonix -- home apply --confirm || true

echo "=== verificar que destino não foi sobrescrito ==="
cat "$tmp/Documentos/Financeiro/Bancos/comprovante pix banco.pdf"

rm -rf "$tmp"
```

Critério:

- destino não pode ser sobrescrito;
- ação deve ser bloqueada ou pulada;
- arquivo existente deve permanecer com conteúdo `destino diferente`.

---

## Fase 12 — Home real não alterada

Execute:

```bash
if [ -d "$HOME/.local/state/kryonix/home-brain/audit" ]; then
  echo "ATENÇÃO: audit real existe. Não remover. Apenas reportar."
else
  echo "OK: nenhum audit real detectado."
fi

if [ -d "$HOME/.local/state/kryonix/home-brain/manifests" ]; then
  echo "ATENÇÃO: manifests reais existem. Não remover. Apenas reportar."
else
  echo "OK: nenhum manifest real detectado."
fi
```

Não remover nada.

---

## Fase 13 — Auditoria de secrets e escopo

Execute:

```bash
cd /etc/kryonix

echo "=== alterações contra origin/main ==="
git fetch origin
git diff --name-status origin/main...HEAD

echo "=== secrets no diff ==="
git diff origin/main...HEAD | rg -n "api[_-]?key|token|secret|password|passwd|bearer|authorization|private|id_ed25519|id_rsa|KRYONIX_BRAIN_API_KEY|NEO4J_AUTH|BEGIN .*PRIVATE" -i || true

echo "=== arquivos proibidos versionados ==="
git ls-files | grep -E '(^|/)(brain\.env|neo4j\.env|\.env|.*secret.*|.*token.*|id_ed25519.*|id_rsa.*)$' || true

echo "=== escopo sensível ==="
git diff --name-status origin/main...HEAD | rg -n "brain|neo4j|lightrag|wayvnc|hosts|modules|features|profiles" || true
```

Critérios:

- nenhum secret;
- nenhum arquivo proibido versionado;
- Brain/GraphRAG/Neo4j/WayVNC não alterados;
- se `modules/features/profiles` aparecerem, justificar ou marcar PARCIAL.

---

## Relatório final obrigatório

Entregar relatório neste formato:

```md
# Auditoria — Kryonix Home Brain Fase 3B Taxonomia

## Status
APROVADO / PARCIAL / REPROVADO

## Commits auditados
- superprojeto:
- kryonix-home:

## Isolamento
- flake.lock mudou somente kryonix-home?
- kryonix-brain-lightrag intacto?
- Brain/GraphRAG/Neo4j/WayVNC intactos?
- secrets ausentes?

## Funcionalidades validadas
- taxonomy fallback:
- taxonomy TOML custom:
- plan --taxonomy-suggestions:
- plan --rename-suggestions --taxonomy-suggestions:
- plan --why:
- explain:
- categories:
- manifest com categoria:
- apply dry-run:
- apply confirm sandbox:
- rollback sandbox:
- destination_exists:
- already_organized:

## Exemplos verificados
| Arquivo | Categoria | Destino | Nome final | Motivo |
|---|---|---|---|

## Edge cases
- conflito:
- baixa confiança:
- arquivo já organizado:
- destino existente:
- mídia:
- sem extensão:

## Segurança
- Home real alterada?
- apply confirm em Home real?
- secrets expostos?
- switch real executado?
- flake.lock fora de escopo alterado?
- delete implementado?
- overwrite permitido?

## Validações
- cargo fmt:
- clippy:
- cargo test:
- cargo build:
- nix build kryonix-home:
- nix build kryonix:
- nix flake check:
- sandbox taxonomy-only:
- sandbox taxonomy+rename:
- TOML custom:
- explain/why/categories:
- edge cases:
- destination_exists:

## Sugestões de melhoria
Separar em:
1. Correções obrigatórias antes de fechar;
2. Melhorias futuras;
3. Não fazer ainda.

## Veredito
Dizer se a Fase 3B pode ser considerada fechada.

## Próximo passo recomendado
Escolher uma:
1. criar tag de marco;
2. corrigir gaps;
3. Fase 3C IA local apenas como sugestão;
4. deduplicar system-path em branch separada.
```

---

## Sugestões de melhoria se tudo passar

Se a auditoria passar, sugerir como próximas melhorias, mas **não implementar nesta tarefa**:

### 1. `kryonix home taxonomy doctor`

Valida TOML, categorias duplicadas, dirs inválidos, keywords vazias e riscos inválidos.

### 2. `kryonix home taxonomy init`

Gera arquivo padrão:

```txt
~/.config/kryonix/home-taxonomy.toml
```

com base no fallback embutido.

### 3. `kryonix home quality`

Relatório da qualidade da organização:

- quantos arquivos em Downloads;
- quantos categorizáveis;
- quantos em baixa confiança;
- quantos conflitos;
- quantos já organizados;
- score geral de organização.

### 4. Feedback supervisionado sem IA

Criar:

```txt
~/.local/state/kryonix/home-brain/feedback/rules.jsonl
```

para registrar correções manuais futuras.

### 5. Fase 3C IA local

Somente depois:

- IA sugere título/categoria;
- nunca aplica diretamente;
- sempre entra como proposal;
- sempre passa por manifest;
- apply só com `--confirm`;
- rollback obrigatório.

---

## Critério final rígido

A Fase 3B só é **APROVADA** se:

```txt
- taxonomy é determinística;
- TOML custom funciona;
- fallback funciona;
- explain funciona;
- plan --why funciona;
- categories funciona;
- manifest registra justificativas;
- apply --dry-run não muta;
- apply --confirm só em HOME temporária;
- rollback restaura estado original;
- destino existente não é sobrescrito;
- Home real não é alterada;
- flake.lock muda só kryonix-home;
- Brain/GraphRAG/Neo4j/WayVNC intactos;
- não há secrets;
- testes e builds passam.
```
