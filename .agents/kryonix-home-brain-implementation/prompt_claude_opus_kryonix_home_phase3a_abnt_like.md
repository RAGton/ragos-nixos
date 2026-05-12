# Prompt para Claude Opus — Kryonix Home Brain Fase 3A

Você está em `/etc/kryonix` no projeto **Kryonix**.

## Papel

Atue como engenheiro sênior de Rust, NixOS, Bash, CLI design e segurança de dados locais.

Seu objetivo é implementar a **Fase 3A do Kryonix Home Brain**: sugestões determinísticas de renomeação de arquivos com perfil **Kryonix ABNT-like Naming Profile**, sempre via `plan -> manifest -> apply -> rollback`.

Esta fase **não usa IA/LLM** e **não executa mutações na Home real durante validação**.

---

## Estado atual confirmado

A Fase 2.2 foi aprovada.

### Fase 1 — fechada

```txt
✅ scan
✅ report
✅ duplicates
✅ plan --dry-run
✅ plan --json
✅ scanner seguro
✅ SHA256 para duplicatas exatas
✅ sem mutação
```

### Fase 2 — fechada

```txt
✅ manifest create
✅ manifest show
✅ apply --dry-run
✅ apply --confirm em sandbox
✅ rollback em sandbox
✅ audit logs
✅ diff before vs after rollback idêntico
```

### Fase 2.2 — fechada

```txt
✅ kryonix home manifest --help delegado ao Rust/clap
✅ kryonix home apply --help delegado ao Rust/clap
✅ kryonix home rollback --help delegado ao Rust/clap
✅ nenhuma mutação na Home real
✅ nenhum flake.lock alterado no hotfix
✅ nenhum switch real executado
```

Commits conhecidos:

```txt
e25274d chore(flake): update kryonix-home flake input
cef372f fix(home): route phase 2 commands to kryonix-home
fcb30e2 fix(home): delegate phase 2 help to kryonix-home
```

Antes de iniciar esta tarefa, garanta que a branch `fix/home-cli-phase2-routing` esteja mergeada na `main`.

---

## Objetivo da Fase 3A

Adicionar sugestões determinísticas de renomeação de arquivos, inspiradas em organização acadêmica/profissional.

Não declarar conformidade oficial com ABNT.  
O nome correto do perfil é:

```txt
Kryonix ABNT-like Naming Profile
```

A ideia é gerar nomes limpos, rastreáveis e padronizados.

Exemplos conceituais:

```txt
Antes:
Downloads/trabalho final joao versão boa.pdf

Sugestão:
2026-05-09_Trabalho_Final_Joao_v1.pdf
```

```txt
Antes:
Downloads/comprovante (1).txt

Sugestão:
2026-05-09_Comprovante_v1.txt
```

```txt
Antes:
Downloads/asdf.pdf

Sugestão:
2026-05-09_Documento_Revisar_v1.pdf
```

---

## Regras obrigatórias de segurança

1. Não usar IA.
2. Não usar LLM.
3. Não ler conteúdo profundo de PDF/DOCX nesta fase.
4. Não mover, renomear ou deletar arquivos da Home real durante validação.
5. Não rodar `apply --confirm` na Home real.
6. `apply --confirm` só pode rodar com `HOME="$(mktemp -d)"`.
7. Não deletar nada.
8. Não sobrescrever destino existente.
9. Não tocar pastas ocultas.
10. Não tocar:
   - `.config`
   - `.local`
   - `.cache`
   - `.ssh`
   - `.gnupg`
   - repositórios Git
   - flakes
   - `Cargo.toml`
   - `package.json`
11. Não mexer em Brain.
12. Não mexer em GraphRAG.
13. Não mexer em Neo4j.
14. Não mexer em WayVNC.
15. Não mexer em LightRAG.
16. Não mexer em deduplicação system-path.
17. Não atualizar inputs globais.
18. Se atualizar `flake.lock`, atualizar somente `kryonix-home`.
19. Commits pequenos.
20. Tudo precisa passar por:
    - plan
    - manifest
    - apply --dry-run
    - apply --confirm em sandbox
    - rollback em sandbox

---

## Escopo permitido

No submódulo:

```txt
/etc/kryonix/packages/kryonix-home
```

Arquivos prováveis:

```txt
src/naming.rs
src/planner.rs
src/manifest.rs
src/apply.rs
src/rollback.rs
src/cli.rs
src/main.rs
Cargo.toml
Cargo.lock
```

No superprojeto, somente depois do submódulo aprovado:

```txt
flake.lock
packages/kryonix-home
```

CLI shell somente se necessário:

```txt
packages/kryonix-cli/home.sh
packages/kryonix-cli/main.sh
```

Evitar mexer na CLI shell se `kryonix home plan --rename-suggestions` já delegar corretamente ao Rust.

---

## Escopo proibido

Não alterar:

```txt
features/*
modules/*
hosts/*
profiles/*
packages/kryonix-brain-lightrag
Brain
GraphRAG
Neo4j
WayVNC
LightRAG
.agents/*
flake.nix, salvo se absolutamente necessário
flake.lock de outros inputs
```

---

## Fase 0 — Confirmar main e hotfix anterior

Execute no superprojeto:

```bash
cd /etc/kryonix

echo "=== branch ==="
git branch --show-current

echo "=== status ==="
git status --short

echo "=== últimos commits ==="
git log --oneline --decorate -8

echo "=== conferir Fase 2.2 ==="
nix run .#kryonix -- home manifest --help || true
nix run .#kryonix -- home apply --help || true
nix run .#kryonix -- home rollback --help || true
```

Se `manifest/apply/rollback --help` não forem delegados ao Rust/clap, parar.  
Não iniciar Fase 3A.

---

## Fase 1 — Criar branch no submódulo

```bash
cd /etc/kryonix/packages/kryonix-home

git switch main
git pull --ff-only origin main
git status --short

git switch -c feat/abnt-like-renaming
```

---

## Fase 2 — Implementação Rust

Criar novo módulo:

```txt
src/naming.rs
```

Adicionar no `main.rs`:

```rust
mod naming;
```

### Estruturas sugeridas

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenameSuggestion {
    pub old_path: PathBuf,
    pub suggested_filename: String,
    pub suggested_relative_path: PathBuf,
    pub confidence: f32,
    pub risk: RiskLevel,
    pub reason: String,
    pub rules_applied: Vec<String>,
    pub naming_profile: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NamingProfile {
    pub name: String,
}
```

Usar perfil:

```txt
kryonix-abnt-like-v1
```

### Regras de nomeação v1

Formato base:

```txt
YYYY-MM-DD_Titulo_Normalizado_vN.ext
```

Nesta fase, não inventar autor.  
Não tentar extrair autor de PDF/DOCX.  
Não usar IA.

Data:

1. usar data de modificação do arquivo;
2. se indisponível, usar data atual;
3. registrar no `reason` qual data foi usada.

Extensão:

- preservar extensão original;
- normalizar extensão para lowercase;
- se não houver extensão, manter sem extensão e marcar `needs_review`.

Normalização:

- remover caracteres problemáticos:
  - `/`
  - `\`
  - `:`
  - `*`
  - `?`
  - `"`
  - `<`
  - `>`
  - `|`
- converter espaços, hífens repetidos e parênteses em `_`;
- compactar múltiplos `_`;
- remover `_` no começo/fim;
- limitar tamanho do nome final;
- evitar nome vazio.

Termos ruins para limpar ou reduzir:

```txt
final_final
versao boa
versão boa
copia
cópia
copy
download
novo
sem titulo
sem título
arquivo
documento
(1)
(2)
```

Se após limpeza o título ficar genérico demais:

```txt
Documento_Revisar
```

Versão:

- detectar `v1`, `v2`, `versao 2`, `versão 2`;
- se não detectar, usar `v1`;
- preservar número detectado quando confiável.

Extensões suportadas inicialmente:

```txt
.pdf
.txt
.md
.doc
.docx
.odt
.xls
.xlsx
.csv
.ppt
.pptx
.jpg
.jpeg
.png
```

Política de risco:

```txt
txt/md/csv: medium
pdf/doc/docx/odt/xls/xlsx/ppt/pptx: medium + needs_review true
jpg/jpeg/png: medium/high + needs_review true
sem extensão: high + needs_review true
```

Não usar risco `low` para rename ainda, a menos que o caso seja trivial e muito confiável.

---

## Fase 3 — Integração com planner

Adicionar flags ao comando `plan`:

Preferido:

```bash
kryonix-home plan --rename-suggestions
kryonix-home plan --json --rename-suggestions
```

Opcional:

```bash
kryonix-home plan --json --rename-suggestions --naming-profile kryonix-abnt-like-v1
```

O JSON do plano deve incluir propostas com action `rename`:

```json
{
  "action": "rename",
  "risk": "medium",
  "confidence": 0.72,
  "old_path": "/tmp/home/Downloads/trabalho final joao versão boa.txt",
  "new_filename": "2026-05-09_Trabalho_Final_Joao_v1.txt",
  "reason": "Nome normalizado pelo perfil kryonix-abnt-like-v1",
  "needs_review": true,
  "rules_applied": [
    "date_from_modified_time",
    "removed_noise_terms",
    "normalized_separators",
    "preserved_extension"
  ],
  "naming_profile": "kryonix-abnt-like-v1"
}
```

### Regra importante

A Fase 3A deve gerar sugestões de rename, mas **não deve remover as propostas de move existentes**.

Se houver move + rename para o mesmo arquivo, o planner deve ser claro:

Opção aceitável A:

```txt
gerar apenas uma proposta combinada move+rename
```

Opção aceitável B:

```txt
gerar proposta rename separada e documentar que apply atual trata separadamente
```

Preferência: **proposta combinada** se o modelo atual suportar.

Se o modelo atual não suportar bem, implementar rename isolado primeiro e marcar conflito/needs_review quando houver move simultâneo.

---

## Fase 4 — Manifesto

`manifest create` deve aceitar propostas `rename`.

Registrar no manifesto:

```txt
action_type = rename
old_path
new_path
old_filename
new_filename
sha256_before
size
mime
reason
rules_applied
naming_profile
risk
confidence
status = planned
```

Se destino já existir no momento do manifesto:

```txt
status = blocked
reason = destination_exists
```

Ou manter planned e bloquear no apply. Preferência: bloquear no apply e avisar no manifest show.

---

## Fase 5 — Apply

### apply --dry-run

Para rename:

- validar que origem existe;
- validar SHA256 antes;
- validar destino não existe;
- mostrar operação planejada;
- não alterar nada.

### apply --confirm

Para rename:

- validar que origem existe;
- validar SHA256 antes;
- validar destino não existe;
- criar diretório destino se necessário;
- executar rename/move com `std::fs::rename`;
- registrar em audit log;
- se falhar, marcar failed/skipped;
- nunca sobrescrever;
- nunca deletar.

---

## Fase 6 — Rollback

Rollback deve reverter renames usando audit log:

- localizar arquivo atual;
- validar se caminho antigo está livre;
- não sobrescrever;
- mover de volta;
- registrar resultado;
- se falhar, reportar e continuar de forma segura.

---

## Fase 7 — Testes unitários obrigatórios

Adicionar testes para:

1. normalização de nome simples;
2. remoção de caracteres perigosos;
3. preservação de extensão;
4. fallback para `Documento_Revisar`;
5. geração de data;
6. detecção de versão;
7. serialização de rename suggestion em JSON;
8. destino existente bloqueia apply;
9. rollback de rename restaura caminho original;
10. mídia recebe `needs_review = true`.

Rodar:

```bash
cd /etc/kryonix/packages/kryonix-home

cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
cargo build
```

---

## Fase 8 — Teste sandbox via cargo

Não usar Home real.

```bash
cd /etc/kryonix/packages/kryonix-home

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos"

printf "texto
" > "$tmp/Downloads/trabalho final joao versão boa.txt"
printf "texto2
" > "$tmp/Downloads/comprovante (1).txt"

echo "=== HOME TEMP: $tmp ==="

HOME="$tmp" cargo run -- scan
HOME="$tmp" cargo run -- plan --json --rename-suggestions > /tmp/kryonix-home-rename-plan.json
jq . /tmp/kryonix-home-rename-plan.json >/dev/null

HOME="$tmp" cargo run -- manifest create
HOME="$tmp" cargo run -- manifest show
HOME="$tmp" cargo run -- apply --dry-run

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/before.txt

HOME="$tmp" cargo run -- apply --confirm

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/after-confirm.txt

HOME="$tmp" cargo run -- rollback

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/after-rollback.txt

diff -u /tmp/before.txt /tmp/after-rollback.txt

rm -rf "$tmp"
```

Critério:

```txt
diff before vs after-rollback idêntico
```

---

## Fase 9 — Commit no submódulo

```bash
cd /etc/kryonix/packages/kryonix-home

git status --short
git add .
git commit -m "feat(home): add abnt-like rename suggestions"
git push -u origin feat/abnt-like-renaming
```

Não fazer merge no `main` do submódulo sem aprovação se o fluxo pedir PR.  
Se o fluxo atual for push direto em main, confirmar antes.

---

## Fase 10 — Atualizar superprojeto somente depois de aprovado

Depois do submódulo estar em `main` ou commit aprovado:

```bash
cd /etc/kryonix

git switch main
git pull --ff-only origin main

nix flake lock --update-input kryonix-home
git submodule update --init --recursive

nix build .#kryonix-home --no-link
nix build .#kryonix --no-link
```

Validar que somente `kryonix-home` mudou no lock:

```bash
git diff -- flake.lock
nix flake metadata | rg -n "kryonix-home|kryonix-brain-lightrag"
```

---

## Fase 11 — Teste sandbox via CLI principal

Não usar Home real.

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos"

printf "texto
" > "$tmp/Downloads/trabalho final joao versão boa.txt"
printf "texto2
" > "$tmp/Downloads/comprovante (1).txt"

echo "=== HOME TEMP: $tmp ==="

HOME="$tmp" nix run .#kryonix -- home scan
HOME="$tmp" nix run .#kryonix -- home plan --json --rename-suggestions > /tmp/kryonix-home-rename-plan-cli.json
jq . /tmp/kryonix-home-rename-plan-cli.json >/dev/null

HOME="$tmp" nix run .#kryonix -- home manifest create
HOME="$tmp" nix run .#kryonix -- home manifest show
HOME="$tmp" nix run .#kryonix -- home apply --dry-run

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/kryonix-before.txt

HOME="$tmp" nix run .#kryonix -- home apply --confirm

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/kryonix-after-confirm.txt

HOME="$tmp" nix run .#kryonix -- home rollback

find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort > /tmp/kryonix-after-rollback.txt

diff -u /tmp/kryonix-before.txt /tmp/kryonix-after-rollback.txt

rm -rf "$tmp"
```

---

## Fase 12 — Commit no superprojeto

```bash
cd /etc/kryonix

git status --short
git add flake.lock packages/kryonix-home
git commit -m "chore(home): update kryonix-home rename suggestions"
```

Não incluir:

```txt
features/*
modules/*
profiles/*
.agents/*
packages/kryonix-brain-lightrag
```

---

## Critério de conclusão

A tarefa só está concluída se:

```txt
✅ plan gera sugestões de rename com --rename-suggestions
✅ manifest registra rename
✅ apply --dry-run valida rename sem mutar
✅ apply --confirm funciona somente em HOME temporária
✅ rollback restaura estado original em HOME temporária
✅ nenhum apply confirm foi feito na Home real
✅ nenhum delete foi implementado
✅ nenhum sobrescrever é permitido
✅ testes Rust passam
✅ nix build .#kryonix-home passa
✅ nix build .#kryonix passa
✅ flake.lock atualiza somente kryonix-home
✅ Brain/GraphRAG não foram alterados
```

---

## Relatório final obrigatório

Entregar:

```md
# Kryonix Home Brain — Fase 3A Renomeação ABNT-like

## Status
APROVADO / PARCIAL / REPROVADO

## Commits
- submódulo:
- superprojeto:

## O que foi implementado
- ...

## Exemplos de nomes gerados
| Antes | Depois |
|---|---|

## Segurança
- Home real alterada? sim/não
- apply confirm apenas em sandbox? sim/não
- rollback validado? sim/não
- sobrescrita bloqueada? sim/não
- delete implementado? deve ser não

## Validações
- cargo fmt:
- clippy:
- cargo test:
- cargo build:
- nix build .#kryonix-home:
- nix build .#kryonix:
- sandbox via cargo:
- sandbox via CLI:

## Riscos restantes
- nomes são heurísticos
- não há IA ainda
- mídia exige revisão
- documentos genéricos exigem revisão

## Próxima fase recomendada
Fase 3B — sugestões de título com IA local, ainda sem mutação direta e sempre via manifesto.
```

---

## Observação final

Não avance para Fase 3B nesta tarefa.

A sequência correta é:

```txt
Fase 3A: rename determinístico ABNT-like
Fase 3B: IA local sugere título melhor
Fase 4: dedupe semântico
Fase 5: ingestão Brain/RAG/CAG
```
