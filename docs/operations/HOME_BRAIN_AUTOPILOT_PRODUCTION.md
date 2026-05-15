# Kryonix Home Brain — Autopilot de Produção

> Documentação operacional do fluxo **Safe Autonomous Autopilot** para organização declarativa, segura e auditável da HOME do usuário.

---

## 1. Visão Geral

O **Kryonix Home Brain Autopilot** é o subsistema autônomo responsável por organizar arquivos soltos na HOME do usuário de forma segura, previsível e reversível.

O autopilot opera em ciclo:
```
Scan → Classificação → Plano → Manifesto → Dry-Run → [Aprovação] → Apply → Auditoria → [Rollback]
```

**Princípios fundamentais:**
- **Dry-run por padrão** — nenhuma ação é executada sem flag explícita
- **Enabled = false** — o autopilot vem desabilitado de fábrica
- **Confiança mínima de 95%** — hardfloor incondicional para `AutoMoveCertified`
- **Risk == low obrigatório** — itens com risco != low jamais são auto-movidos
- **Manifesto antes de apply** — toda ação passa por manifesto formal
- **Rollback 100% fiel** — reversão completa via audit log
- **Multi-host seguro** — apenas workstations cliente executam o autopilot

---

## 2. Hosts e Multi-Host Policy

### Hosts Permitidos
| Host | Permitido | Motivo |
|------|-----------|--------|
| `inspiron` | ✅ | Workstation cliente principal |
| `inspiron-nina` | ✅ | Workstation cliente secundária |
| `glacier` | ❌ | Servidor IA/Brain — não organiza HOME |
| Outros | ❌ | Desconhecido — bloqueado por padrão |

> **Exceção para desenvolvimento:** Hostnames `unknown` (sandbox/CI) são permitidos para testes.

### Gate de Hostname
O autopilot verifica o hostname da máquina antes de qualquer operação. Se o host não for permitido, a execução é abortada com mensagem clara:

```
❌ BLOQUEADO: O autopilot de Home não pode ser executado no host 'glacier'.
```

---

## 3. Política de Segurança Declarativa

### 3.1 Arquivo de Configuração

```
~/.config/kryonix/home-autopilot.toml
```

#### Exemplo Seguro (Padrão Recomendado)
```toml
[autopilot]
enabled = false           # Desabilitado por padrão
min_confidence = 0.95     # Mínimo 95% de confiança
max_actions = 100         # Máximo de ações por run
dry_run = true            # Sempre simula primeiro
staging_only = false      # Não usa staging intermediário
```

#### Configuração para Produção
```toml
[autopilot]
enabled = true
min_confidence = 0.95
max_actions = 50
dry_run = true
staging_only = false

# Extensões proibidas (além das padrão)
blacklist_extensions = [
  "exe", "msi", "sh", "bat", "ps1", "bin", "run",
  "qcow2", "vmdk", "vdi", "vhd", "vhdx",
  "sqlite", "db", "sqlite3",
  "env", "token", "secret", "key", "pem"
]

# Pastas proibidas
blacklist_folders = [
  "Obsidian Vault", ".ssh", ".gnupg", ".config",
  ".env", ".password-store", ".pki",
  "VMs", "libvirt",
  ".local/share/gnome-boxes", ".local/share/libvirt"
]
```

### 3.2 Blacklists Padrão (hardcoded)

#### Extensões Bloqueadas
| Categoria | Extensões |
|-----------|-----------|
| Executáveis | `exe`, `msi`, `sh`, `bat`, `ps1`, `bin`, `run` |
| Máquinas Virtuais | `qcow2`, `vmdk`, `vdi`, `vhd`, `vhdx` |
| Bancos de Dados | `sqlite`, `db`, `sqlite3` |
| Secrets/Chaves | `env`, `token`, `secret`, `key`, `pem` |

#### Pastas Bloqueadas
| Pasta | Motivo |
|-------|--------|
| `.ssh` | Chaves SSH |
| `.gnupg` | Chaves GPG |
| `.config` | Configurações de aplicativos |
| `.password-store` | Password manager |
| `.pki` | Certificados PKI |
| `Obsidian Vault` | Base de conhecimento |
| `VMs` / `libvirt` | Máquinas virtuais |
| `.local/share/gnome-boxes` | VMs GNOME Boxes |
| `.local/share/libvirt` | VMs libvirt |

### 3.3 Proteções Adicionais (em código)

Além das blacklists configuráveis, o planner e o apply aplicam proteções em profundidade:

- **Paths protegidos** (`metadata.rs`): `.ssh`, `.gnupg`, `.config`, `.local`, `.cache`, `.mozilla`, `.thunderbird`, `.var`, toolchain managers
- **Secret files** (`ignore.rs`): `.env`, `brain.env`, `neo4j.env`, `id_rsa`, `id_ed25519`, extensões `.key`, `.pem`, `.secret`, `.token`
- **Scanner directory pruning** (`ignore.rs`): Poda automática de `.git`, `node_modules`, `target`, `.cache`, etc.
- **Projetos Git/Rust/Nix**: Bloqueados por detecção de marcadores de projeto

---

## 4. Classificações de Decisão

| Classe | Significado | Auto-Apply? |
|--------|------------|-------------|
| `AutoMoveCertified` | Confiança ≥ 95%, risk = low, multi-source evidence | ✅ (se enabled) |
| `NeedsHumanReview` | Confiança < 95% ou risco != low | ❌ Requer `review` |
| `BlockedUnsafe` | Proteção ativa (secret, script, projeto, vault) | ❌ Permanente |
| `IgnoreNoise` | Arquivo temporário ou irrelevante | ❌ Ignorado |
| `KeepInPlace` | Já no local correto | ❌ Nada a fazer |

### Requisitos para `AutoMoveCertified`
Todos devem ser verdadeiros **simultaneamente**:
- `confidence >= 0.95` (hardfloor interno incondicional)
- `risk == "low"`
- `auto_apply_allowed == true`
- `blocked_from_apply == false`
- `needs_review == false`
- Pelo menos 2 fontes de evidência independentes
- Destino não contém `Revisar`, `Baixa_Confianca`, `Conflitos`
- Categoria não é `Incerto`
- Não é path protegido, projeto, vault, script ou overwrite

---

## 5. Fluxo Operacional

### 5.1 Dry-Run (Recomendado)

```bash
# Scan + dry-run padrão
kryonix home autopilot --dry-run

# Dry-run focado no inbox
kryonix home autopilot --dry-run --inbox

# Dry-run com confiança personalizada
kryonix home autopilot --dry-run --min-confidence 0.98

# Dry-run com limite de ações
kryonix home autopilot --dry-run --max-actions 10
```

O dry-run:
- Gera relatório visual no terminal
- Salva JSON estruturado em `~/.local/state/kryonix/home-brain/dry-run/`
- **Nunca** move arquivos

### 5.2 Execução Controlada

```bash
# Executar após dry-run satisfatório
kryonix home autopilot --execute
```

Requisitos para `--execute`:
1. Config `enabled = true` em `~/.config/kryonix/home-autopilot.toml`
2. Host permitido (inspiron, inspiron-nina)
3. Manifesto gerado automaticamente
4. Audit log salvo automaticamente

### 5.3 Rollback

```bash
# Reverter a última execução
kryonix home autopilot --undo-last
# ou
kryonix home rollback
```

O rollback:
- Lê o último audit log
- Reverte apenas ações com `status == "executed"`
- Verifica se o arquivo ainda está no destino
- Verifica se o local original não foi ocupado
- Salva um log de rollback separado

---

## 6. Auditoria

### Locais de Armazenamento

| Tipo | Caminho |
|------|---------|
| Manifestos | `~/.local/state/kryonix/home-brain/manifests/` |
| Audit logs (apply) | `~/.local/state/kryonix/home-brain/audit/` |
| Dry-run reports | `~/.local/state/kryonix/home-brain/dry-run/` |
| Relatórios MD | `~/.local/share/kryonix/home/reports/` |

### Formato do Dry-Run Audit (JSON)

```json
{
  "type": "dry_run_audit",
  "timestamp": "2026-05-15T19:00:00Z",
  "hostname": "inspiron",
  "run_id": "scan-20260515-190000",
  "summary": {
    "auto_move_certified": 3,
    "needs_human_review": 12,
    "blocked_unsafe": 5,
    "total_actions": 20
  },
  "certified_items": [...],
  "blocked_items": [...]
}
```

---

## 7. Validação e Testes

### Validação Completa
```bash
cd /etc/kryonix/packages/kryonix-home
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
cargo build
```

### Nix Build
```bash
cd /etc/kryonix
nix build .#kryonix-home --no-link
nix build .#kryonix --no-link
```

### Sandbox Test
```bash
cd /etc/kryonix/packages/kryonix-home
bash test_sandbox.sh
HOME="$(mktemp -d)" nix run .#kryonix -- home autopilot --dry-run
```

---

## 8. Matriz de Decisão Resumida

```
Arquivo em .ssh/?         → BlockedUnsafe (proteção de path)
Arquivo .env?             → BlockedUnsafe (blacklist extensão)
Arquivo .qcow2?           → BlockedUnsafe (blacklist extensão)
Arquivo .sqlite?          → BlockedUnsafe (blacklist extensão)
Projeto Git?              → BlockedUnsafe (detecção de projeto)
Obsidian Vault?           → BlockedUnsafe (vault protegido)
Executável/script?        → BlockedUnsafe (segurança)
Confiança < 95%?          → NeedsHumanReview
Risco != low?             → NeedsHumanReview
Destino "Revisar"?        → NeedsHumanReview
Confiança >= 95% + low?   → AutoMoveCertified
Host = glacier?           → EXECUÇÃO BLOQUEADA
```

---

*Documento gerado como parte da Issue #18 — Kryonix Home Brain Autopilot Seguro.*
*Última atualização: 2026-05-15*
