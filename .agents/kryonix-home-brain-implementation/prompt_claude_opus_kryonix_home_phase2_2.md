# Prompt para Claude Opus — Kryonix Home Brain Fase 2.2

Você está em `/etc/kryonix` no projeto **Kryonix**.

## Papel

Atue como engenheiro sênior de NixOS, Rust, Bash e infraestrutura local.  
Seu objetivo é **corrigir a integração final da CLI `kryonix home` com a Fase 2 do Kryonix Home Brain**, sem misturar com outras tarefas.

Este projeto é sensível porque gerencia arquivos reais da Home do usuário. Toda mudança deve ser auditável, reversível e testada em sandbox.

---

## Contexto do projeto

O Kryonix é uma plataforma NixOS declarativa com:

- NixOS Flakes;
- CLI `kryonix`;
- hosts `inspiron` e `glacier`;
- Brain/RAG/GraphRAG;
- Neo4j;
- LightRAG;
- Home Brain em Rust;
- submódulos externos usando o padrão **Opção A**.

### Padrão Opção A

```txt
submódulo local = desenvolvimento/auditoria
flake input remoto = fonte oficial do build
flake.lock = versão pinada/reprodutível
```

Pacotes atuais nesse padrão:

```txt
packages/kryonix-home
packages/kryonix-brain-lightrag
```

---

## Estado atual confirmado

### Marco geral fechado

Já foram concluídos e validados:

```txt
✅ Kryonix CLI Premium
✅ kryonix all funcional
✅ Inspiron sincronizado
✅ Glacier sincronizado
✅ kryonix-home como submódulo + flake input remoto
✅ kryonix-brain-lightrag como flake input pinado
✅ Brain health OK
✅ Graph/Neo4j OK
✅ systemctl --failed = 0
✅ docs/operations/GRAPH_MAINTENANCE.md recriado
✅ docs/development/SUBMODULES.md atualizado
✅ docs/operations/REMOTE_DESKTOP_WAYVNC.md atualizado
```

### Fase 1 do Kryonix Home Brain

Status: **FECHADA**

Já existe no Rust:

```bash
kryonix home scan
kryonix home report
kryonix home duplicates
kryonix home plan --dry-run
kryonix home plan --json
```

A Fase 1 é somente leitura/planejamento:

```txt
não move
não renomeia
não deleta
não altera a Home real
```

### Fase 2 do Kryonix Home Brain

Status funcional no binário Rust: **FECHADA**

Commit no submódulo:

```txt
packages/kryonix-home
424c045 feat: implement phase 2 manifest, staging and rollback
```

Foram implementados:

```bash
kryonix-home manifest create
kryonix-home manifest show
kryonix-home apply --dry-run
kryonix-home apply --confirm
kryonix-home rollback
```

A auditoria sandbox mostrou:

```txt
✅ manifest create
✅ manifest show
✅ apply --dry-run
✅ apply --confirm em HOME temporária
✅ rollback em HOME temporária
✅ diff before vs after rollback idêntico
✅ nenhuma mutação na Home real
```

---

## Problema atual

O hotfix da CLI foi aplicado e os comandos reais da Fase 2 já funcionam via:

```bash
kryonix home manifest create
kryonix home manifest show
kryonix home apply --dry-run
kryonix home apply --confirm
kryonix home rollback
```

Porém ainda existe um achado menor:

```txt
kryonix home manifest --help
kryonix home apply --help
kryonix home rollback --help
```

estão mostrando o help genérico do wrapper shell em vez de delegar o `--help` para o binário Rust `kryonix-home`.

Diagnóstico provável:

No `packages/kryonix-cli/main.sh`, existe um detector global/focado de `--help` que intercepta qualquer `--help` em `extra_args` antes do dispatch para os subcomandos do Home Brain.

Trecho observado anteriormente:

```txt
linhas próximas de 264-270 em main.sh:
qualquer --help ou -h em extra_args é capturado pelo wrapper
```

Efeito:

```txt
kryonix home manifest --help
  -> wrapper shell mostra help genérico

comando esperado:
kryonix home manifest --help
  -> delega para kryonix-home manifest --help
```

---

## Tarefa principal

Implementar a **Fase 2.2 — Correção de help delegado da CLI Home Brain**.

Objetivo:

```txt
Todos os subcomandos do Home Brain devem ser delegados ao binário Rust `kryonix-home`,
incluindo quando usam --help ou -h.
```

Subcomandos Home Brain obrigatórios:

```txt
scan
report
duplicates
plan
manifest
apply
rollback
```

---

## Regras obrigatórias

### Segurança

1. Não rodar `kryonix all` sem `--dry`.
2. Não rodar `nixos-rebuild switch`.
3. Não rodar `home-manager switch`.
4. Não rodar `apply --confirm` na Home real.
5. `apply --confirm` só pode ser testado com `HOME="$(mktemp -d)"`.
6. Não apagar arquivos reais.
7. Não apagar arquivos untracked.
8. Não imprimir secrets.
9. Não ler ou imprimir conteúdo de:
   - `brain.env`
   - `neo4j.env`
   - `.env`
   - tokens
   - chaves SSH

### Escopo proibido

Não mexer em:

```txt
Brain
GraphRAG
Neo4j
WayVNC
LightRAG
kryonix-home Rust
flake.lock
submódulos
features/development.nix
features/gaming.nix
profiles/dev/default.nix
modules/nixos/common/default.nix
modules/home-manager/common/default.nix
```

### Escopo permitido

Alterar somente se necessário:

```txt
packages/kryonix-cli/home.sh
packages/kryonix-cli/main.sh
packages/kryonix-cli.nix
```

Preferência:

```txt
corrigir somente packages/kryonix-cli/main.sh ou home.sh
```

Não misturar com deduplicação de pacotes.

---

## Situação de branch e dirty tree

Atenção: o repositório pode estar na branch:

```txt
chore/nix-deduplicate-system-path
```

E pode haver alterações não relacionadas em:

```txt
features/development.nix
features/gaming.nix
modules/home-manager/common/default.nix
modules/nixos/common/default.nix
profiles/dev/default.nix
packages/kryonix-home
```

Essas alterações pertencem a outra tarefa.  
Não misture com este hotfix.

Antes de editar, faça auditoria.

---

## Fase 0 — Auditoria inicial

Execute:

```bash
cd /etc/kryonix

echo "=== branch ==="
git branch --show-current

echo "=== status ==="
git status --short

echo "=== staged ==="
git diff --name-status --staged

echo "=== unstaged ==="
git diff --name-status

echo "=== diff stat ==="
git diff --stat

echo "=== submodules ==="
git submodule status --recursive

echo "=== kryonix-home submodule ==="
git -C packages/kryonix-home status --short
git -C packages/kryonix-home log --oneline -3
```

Se houver mudanças não relacionadas, **não apagar**.

Crie backup textual:

```bash
mkdir -p /tmp/kryonix-backups

git status --short \
  > /tmp/kryonix-backups/status-before-home-help-routing-$(date +%Y%m%d-%H%M%S).txt

git diff \
  > /tmp/kryonix-backups/diff-before-home-help-routing-$(date +%Y%m%d-%H%M%S).diff
```

Se estiver em branch de deduplicação com arquivos sujos, escolha uma das abordagens:

### Opção preferida

Criar branch limpa a partir da `main` para este hotfix:

```bash
git switch main
git pull --ff-only origin main
git switch -c fix/home-cli-help-routing
```

### Se não puder trocar de branch

Alterar e commitar **somente** os arquivos da CLI permitidos.  
Não incluir outros arquivos no commit.

---

## Fase 1 — Inspeção do roteamento atual

Execute:

```bash
cd /etc/kryonix

echo "=== home.sh ==="
sed -n '1,240p' packages/kryonix-cli/home.sh

echo "=== main.sh home/help routing ==="
rg -n "home\)|kryonix_home|manifest|apply|rollback|scan|report|duplicates|plan|--help|-h|nh home|home-manager" \
  packages/kryonix-cli packages/kryonix-cli.nix

echo "=== help atual ==="
nix run .#kryonix -- home --help || true
nix run .#kryonix -- home manifest --help || true
nix run .#kryonix -- home apply --help || true
nix run .#kryonix -- home rollback --help || true
```

---

## Fase 2 — Comportamento esperado

Implementar este comportamento:

```txt
kryonix home
  -> sem argumentos: manter comportamento legado atual de Home Manager, se existir

kryonix home --help
kryonix home -h
  -> mostrar help do wrapper principal atualizado

kryonix home scan --help
kryonix home report --help
kryonix home duplicates --help
kryonix home plan --help
kryonix home manifest --help
kryonix home apply --help
kryonix home rollback --help
  -> delegar para `kryonix-home "$@"`

kryonix home scan ...
kryonix home report ...
kryonix home duplicates ...
kryonix home plan ...
kryonix home manifest ...
kryonix home apply ...
kryonix home rollback ...
  -> delegar para `kryonix-home "$@"`

kryonix home switch
kryonix home build
kryonix home dry
  -> manter fluxo legado de Home Manager, se existir
```

Regra técnica:

```txt
Se o primeiro argumento depois de `home` for um subcomando do Home Brain,
não interceptar --help globalmente.
Delegar direto para o binário Rust.
```

Pseudocódigo esperado:

```bash
case "${1:-}" in
  scan|report|duplicates|plan|manifest|apply|rollback)
    kryonix-home "$@"
    ;;
  --help|-h|"")
    show_home_help
    ;;
  switch|build|dry)
    fluxo_home_manager "$@"
    ;;
  *)
    # manter comportamento existente, mas não deixar subcomando Brain cair no nh home
    ...
    ;;
esac
```

---

## Fase 3 — Atualizar help

Atualizar `kryonix home --help` para listar todos os comandos:

```txt
Uso:
  kryonix home [subcomando]

Subcomandos Home Brain:
  scan                 Escaneia diretórios seguros da Home
  report               Mostra relatório do último scan
  duplicates           Lista duplicatas exatas por SHA256
  plan --dry-run       Gera plano de organização sem mutação
  plan --json          Gera plano em JSON
  manifest create      Cria manifesto auditável do plano
  manifest show        Mostra resumo do manifesto mais recente
  apply --dry-run      Simula manifesto sem alterar arquivos
  apply --confirm      Aplica ações seguras com auditoria
  rollback             Reverte último apply auditado

Home Manager:
  kryonix home switch  Aplica Home Manager
```

Adicionar aviso de segurança:

```txt
apply --confirm nunca deve ser usado sem revisar o manifesto.
```

---

## Fase 4 — Validações sem mutação real

Execute:

```bash
cd /etc/kryonix

echo "=== syntax ==="
bash -n packages/kryonix-cli/*.sh

echo "=== diff check ==="
git diff --check

echo "=== builds ==="
nix build .#kryonix --no-link
nix build .#kryonix-home --no-link

echo "=== help ==="
nix run .#kryonix -- home --help
nix run .#kryonix -- home scan --help || true
nix run .#kryonix -- home plan --help || true
nix run .#kryonix -- home manifest --help || true
nix run .#kryonix -- home apply --help || true
nix run .#kryonix -- home rollback --help || true
```

Critério:

```txt
manifest/apply/rollback --help não podem mostrar apenas o help genérico do wrapper.
Devem vir do Rust/clap ou pelo menos não cair no nh home.
```

---

## Fase 5 — Teste sandbox obrigatório

Não usar Home real.

Execute:

```bash
cd /etc/kryonix

tmp="$(mktemp -d)"
mkdir -p "$tmp/Downloads" "$tmp/Documentos" "$tmp/Imagens"

printf "documento teste\n" > "$tmp/Downloads/documento_teste.txt"
printf "documento teste\n" > "$tmp/Downloads/documento_teste_copia.txt"

echo "=== HOME TEMP: $tmp ==="

echo "--- scan ---"
HOME="$tmp" nix run .#kryonix -- home scan

echo "--- plan json ---"
HOME="$tmp" nix run .#kryonix -- home plan --json > /tmp/kryonix-home-temp-plan.json
jq . /tmp/kryonix-home-temp-plan.json >/dev/null

echo "--- manifest create ---"
HOME="$tmp" nix run .#kryonix -- home manifest create

echo "--- manifest show ---"
HOME="$tmp" nix run .#kryonix -- home manifest show

echo "--- apply dry-run ---"
HOME="$tmp" nix run .#kryonix -- home apply --dry-run

echo "--- before confirm ---"
find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-before-confirm.txt
cat /tmp/kryonix-home-before-confirm.txt

echo "--- apply confirm sandbox ---"
HOME="$tmp" nix run .#kryonix -- home apply --confirm

echo "--- after confirm ---"
find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-after-confirm.txt
cat /tmp/kryonix-home-after-confirm.txt

echo "--- rollback sandbox ---"
HOME="$tmp" nix run .#kryonix -- home rollback

echo "--- after rollback ---"
find "$tmp" -maxdepth 5 -type f -not -path "*/.local/*" -print | sort \
  > /tmp/kryonix-home-after-rollback.txt
cat /tmp/kryonix-home-after-rollback.txt

echo "--- diff before vs after rollback ---"
diff -u /tmp/kryonix-home-before-confirm.txt /tmp/kryonix-home-after-rollback.txt

rm -rf "$tmp"
```

Critérios:

```txt
- não aparece erro homeConfigurations.rocha@inspiron
- não chama nh home
- apply --confirm só roda na HOME temporária
- rollback restaura o estado original
- diff before vs after-rollback idêntico
```

---

## Fase 6 — Verificar Home real

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

## Fase 7 — Commit pequeno

Se tudo passar, fazer commit pequeno.

```bash
git status --short

git add packages/kryonix-cli/home.sh packages/kryonix-cli/main.sh packages/kryonix-cli.nix

git commit -m "fix(home): delegate phase 2 help to kryonix-home"
```

Adicionar somente arquivos realmente alterados.

Não adicionar:

```txt
flake.lock
features/*
modules/*
profiles/*
packages/kryonix-home
.agents/*
```

Se algum desses aparecer, parar e reportar.

---

## Relatório final obrigatório

Entregar:

```md
# Hotfix CLI — Kryonix Home Fase 2.2

## Status
APROVADO / PARCIAL / REPROVADO

## Problema corrigido
Explique que `kryonix home manifest/apply/rollback --help` era interceptado pelo wrapper shell.

## Arquivos alterados
- ...

## Validações
- bash -n:
- git diff --check:
- nix build .#kryonix:
- nix build .#kryonix-home:
- home --help:
- manifest --help:
- apply --help:
- rollback --help:
- manifest create sandbox:
- apply dry-run sandbox:
- apply confirm sandbox:
- rollback sandbox:
- diff before vs after rollback:

## Segurança
Confirmar:
- nenhum apply --confirm na Home real;
- nenhum secret exposto;
- nenhum flake.lock alterado;
- nenhum switch real executado;
- nenhuma alteração de deduplicação misturada.

## Estado da Fase 2
Dizer se:
- Fase 2 Rust está fechada;
- Fase 2 CLI está fechada;
- Fase 2.2 help delegado está fechada.

## Próximo passo recomendado
Não iniciar Fase 3 sem aprovação.
Próximo passo possível:
- Fase 3 — renomeação ABNT baseada no manifesto;
ou
- deduplicação system-path em branch separada.
```

---

## Veredito esperado

A tarefa só é considerada concluída se:

```txt
kryonix home manifest --help
kryonix home apply --help
kryonix home rollback --help
```

não forem tratados como Home Manager e não retornarem erro de `homeConfigurations.rocha@inspiron`.

Depois disso, a Fase 2 estará fechada completamente:

```txt
Fase 2 Rust: ✅
Fase 2 CLI comandos reais: ✅
Fase 2 CLI help: ✅
Fase 2 sandbox: ✅
Fase 2 rollback: ✅
```
