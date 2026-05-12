# Glacier — Plano de Layout Btrfs para Reinstalação Futura

> ⚠️ **Este documento é apenas um PLANO.** Não rodar `disko`, `nixos-install` ou formatação no Glacier já instalado.
> O Glacier operacional usa `hosts/glacier/hardware-configuration.nix` como fonte real.

---

## Motivação

O Glacier é o servidor IA/Brain/Ollama/LightRAG/Vault/Neo4j do Kryonix.
Em uma reinstalação futura, o layout de disco precisa ser cuidadosamente estruturado para:

- separar sistema, dados de IA e backups em subvolumes Btrfs independentes;
- permitir snapshots e rollback por subvolume sem afetar dados de runtime;
- preservar dados de `/var/lib/kryonix`, Neo4j, Ollama e Vault mesmo em reinstalação do sistema;
- **evitar symlinks** como `/var/lib/kryonix -> /some/other/path` — o layout final deve montar cada path direto no disco correto.

---

## Decisão arquitetural: `/var` no disco maior

O design anterior usava symlinks para mapear dados pesados do `/var/lib` para o disco de storage.
Na reinstalação, essa indireção não deve ser necessária.

**Regra:** todo path que precise de storage pesado deve ter seu subvolume montado diretamente no disco maior via Disko/fstab. Sem symlinks.

Em particular:
- `/var` inteiro fica **no disco maior**, não no NVMe pequeno.
- O NVMe fica com `/`, `/nix` e `/boot` — dados que se beneficiam de velocidade e são recriáveis.

---

## Hardware alvo

| Disco | Tipo | Capacidade | Uso |
|---|---|---|---|
| `nvme0n1` | NVMe | menor | SO, Nix, Boot, Log |
| `sda` (ou equivalente) | SSD/HDD | maior | `/var`, `/home`, Storage IA, backups |

> Confirmar IDs reais com: `lsblk -o NAME,TYPE,MODEL,SERIAL,SIZE` e `ls -la /dev/disk/by-id/`

---

## Layout de partições (alvo)

### NVMe (disco rápido, sistema)

```
nvme0n1
├── p1  ESP/FAT32   1G       → /boot           (fmask=0077 dmask=0077)
└── p2  Btrfs       restante → subvolumes de sistema
```

### Disco maior (storage IA/dados)

```
sda (ou equivalente)
└── p1  Btrfs       100%     → subvolumes de dados
```

---

## Subvolumes Btrfs (alvo)

### NVMe — subvolumes de sistema

| Subvolume | Mountpoint | Opções | Formatável? |
|---|---|---|---|
| `@root` | `/` | `compress=zstd,noatime` | ✅ sim |
| `@nix` | `/nix` | `compress=zstd,noatime` | ✅ sim |
| `@snapshots` | `/.snapshots` | `compress=zstd,noatime` | ✅ sim |

### Disco maior — subvolumes de dados

| Subvolume | Mountpoint | Opções | Formatável? |
|---|---|---|---|
| `@var` | `/var` | `compress=zstd,noatime` | ⚠️ cuidado com `/var/lib` |
| `@log` | `/var/log` | `compress=zstd,noatime` | ✅ sim |
| `@home` | `/home` | `compress=zstd,noatime,autodefrag` | ❌ preservar |
| `@kryonix` | `/var/lib/kryonix` | `compress=zstd,noatime` | ❌ preservar (Brain storage, LightRAG) |
| `@ollama` | `/var/lib/ollama` | `compress=zstd,noatime` | ❌ preservar (modelos Ollama ~50GB+) |
| `@neo4j` | `/var/lib/neo4j` | `compress=zstd,noatime` | ❌ preservar (grafo) |
| `@backups` | `/var/backups/kryonix` | `compress=zstd,noatime` | ❌ preservar |

> Subvolumes marcados como ❌ devem ser **snapshottados antes de qualquer operação destrutiva**.

> `/var/log` é um subvolume separado dentro do mesmo disco para permitir limpeza/snapshot independente dos logs.

---

## Disko alvo (esboço)

```nix
# hosts/glacier/disks.nix (FUTURO — não usar no host atual)
{ ... }:
{
  disko.devices = {
    # ── Disco 1: NVMe (sistema) ──────────────────────────────────
    disk."nvme0n1" = {
      type = "disk";
      device = "/dev/disk/by-id/<id-nvme-glacier>";  # confirmar com: lsblk -o NAME,TYPE,MODEL,SERIAL
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0077" "dmask=0077" ];
            };
          };
          system = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "GLACIER-NVME" ];
              subvolumes = {
                "@root"      = { mountpoint = "/";          mountOptions = [ "compress=zstd" "noatime" ]; };
                "@nix"       = { mountpoint = "/nix";       mountOptions = [ "compress=zstd" "noatime" ]; };
                "@snapshots" = { mountpoint = "/.snapshots"; mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };

    # ── Disco 2: Storage (dados IA / persistência) ───────────────
    disk."storage" = {
      type = "disk";
      device = "/dev/disk/by-id/<id-storage-glacier>";  # confirmar com: lsblk -o NAME,TYPE,MODEL,SERIAL
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "GLACIER-DATA" ];
              subvolumes = {
                "@var"      = { mountpoint = "/var";                 mountOptions = [ "compress=zstd" "noatime" ]; };
                "@log"      = { mountpoint = "/var/log";             mountOptions = [ "compress=zstd" "noatime" ]; };
                "@home"     = { mountpoint = "/home";                mountOptions = [ "compress=zstd" "noatime" "autodefrag" ]; };
                "@kryonix"  = { mountpoint = "/var/lib/kryonix";     mountOptions = [ "compress=zstd" "noatime" ]; };
                "@ollama"   = { mountpoint = "/var/lib/ollama";      mountOptions = [ "compress=zstd" "noatime" ]; };
                "@neo4j"    = { mountpoint = "/var/lib/neo4j";       mountOptions = [ "compress=zstd" "noatime" ]; };
                "@backups"  = { mountpoint = "/var/backups/kryonix"; mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
```

### Ordem de montagem

O kernel/fstab monta na ordem correta automaticamente por profundidade de path. A hierarquia resultante:

```
/                          ← NVMe  @root
├── boot/                  ← NVMe  ESP
├── nix/                   ← NVMe  @nix
├── var/                   ← DISCO MAIOR  @var
│   ├── lib/
│   │   ├── kryonix/       ← DISCO MAIOR  @kryonix
│   │   ├── ollama/        ← DISCO MAIOR  @ollama
│   │   └── neo4j/         ← DISCO MAIOR  @neo4j
│   ├── log/               ← DISCO MAIOR  @log
│   └── backups/kryonix/   ← DISCO MAIOR  @backups
├── home/                  ← DISCO MAIOR  @home
└── .snapshots/            ← NVMe  @snapshots
```

> Nenhum symlink. Cada path é um subvolume montado diretamente.

---

## Checklist pós-instalação (após `nixos-install`)

### Rede e acesso

- [ ] SSH porta `2224` funcional
- [ ] Tailscale conectado e autenticado
- [ ] IP LAN alvo `10.0.0.2` configurado (estático ou DHCP reservado)

### Secrets (gerados via CLI, fora do Git)

```bash
# Gerar e validar Brain API key
kryonix brain api-key generate
kryonix brain api-key validate
```

- [ ] `/etc/kryonix/brain.env` criado com `KRYONIX_BRAIN_API_KEY` (via `kryonix brain api-key generate`)
- [ ] `/etc/kryonix/neo4j.env` criado com `NEO4J_AUTH` e `NEO4J_PASSWORD` (manual)
- [ ] Permissões `root:root 600` em ambos

### Serviços

- [ ] `systemctl status ollama.service` — ativo
- [ ] `systemctl status kryonix-brain-api.service` — ativo
- [ ] `systemctl status kryonix-lightrag.service` — ativo (se separado)
- [ ] `systemctl status neo4j.service` — ativo
- [ ] `curl -fsS http://127.0.0.1:8000/health` — retorna `{"status":"ok"}`

### Dados preserváveis (migração)

Antes de formatar, fazer snapshot ou backup de:

```bash
# Subvolumes críticos
sudo btrfs subvolume snapshot /var/lib/kryonix    /var/backups/kryonix/pre-install-kryonix
```

---

## Anti-padrões a evitar

| Anti-padrão | Por quê | Correto |
|---|---|---|
| `/var/lib/kryonix -> /mnt/data/kryonix` | Symlinks quebram em reinstalação, confundem serviços e complicam backups | Subvolume `@kryonix` montado diretamente em `/var/lib/kryonix` |
| `/var` no NVMe pequeno | Modelos Ollama (~50GB+), Neo4j e Brain storage enchem o disco | `/var` no disco maior |
| Tudo num único subvolume | Impossível fazer snapshot/rollback seletivo | Um subvolume por serviço pesado |

---

## Notas de segurança

- `hosts/glacier/disks.nix` atual pode divergir do hardware real — sempre confirmar com `lsblk -f` antes.
- Não usar `disko --mode disko` no host já instalado sem snapshot prévio.
- Tailscale auth key é um secret — não colocar no Git.
- GPU NVIDIA: driver declarado em `hosts/glacier/nvidia.nix` (ou equivalente) — não remover sem testar boot.

---

## Referências

- [Layout Inspiron](inspiron.md)
- [Disko Inspiron](../../hosts/inspiron/disks.nix)
- [Hardware Glacier](../../hosts/glacier/hardware-configuration.nix) — fonte real do host atual
- [README — setup API Key](../../README.md#ia-local-e-serviços-do-brain)
- [API Key Rotation](../operations/API_KEY_ROTATION.md)
