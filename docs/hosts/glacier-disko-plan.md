# Glacier — Plano de Layout Btrfs para Reinstalação Futura

> ⚠️ **Este documento é apenas um PLANO.** Não rodar `disko`, `nixos-install` ou formatação no Glacier já instalado.
> O Glacier operacional usa `hosts/glacier/hardware-configuration.nix` como fonte real.

---

## Motivação

O Glacier é o servidor IA/Brain/Ollama/LightRAG/Vault/Neo4j do Kryonix.
Em uma reinstalação futura, o layout de disco precisa ser cuidadosamente estruturado para:

- separar sistema, dados de IA e backups em subvolumes Btrfs independentes;
- permitir snapshots e rollback por subvolume sem afetar dados de runtime;
- preservar dados de `/home/storage`, Neo4j, Ollama e Vault mesmo em reinstalação do sistema.

---

## Hardware alvo

| Disco | Tipo | Uso |
|---|---|---|
| `nvme0n1` ou equivalente | NVMe | SO, Nix, Var, Log |
| disco secundário (se disponível) | SSD/HDD | Storage IA, backups |

---

## Layout de partições (alvo)

```
nvme0n1
├── p1  ESP/FAT32   1G       → /boot           (fmask=0077 dmask=0077)
└── p2  Btrfs       restante → subvolumes abaixo
```

---

## Subvolumes Btrfs (alvo)

| Subvolume | Mountpoint | Opções | Pode formatar? |
|---|---|---|---|
| `@root` | `/` | `compress=zstd,noatime` | ✅ sim |
| `@nix` | `/nix` | `compress=zstd,noatime` | ✅ sim |
| `@var` | `/var` | `compress=zstd,noatime` | ⚠️ cuidado com `/var/lib` |
| `@log` | `/var/log` | `compress=zstd,noatime` | ✅ sim |
| `@home` | `/home` | `compress=zstd,noatime,autodefrag` | ❌ preservar |
| `@storage` | `/home/storage` | `compress=zstd,noatime` | ❌ preservar (modelos, vault, dados Brain) |
| `@kryonix` | `/var/lib/kryonix` | `compress=zstd,noatime` | ❌ preservar (Brain storage, LightRAG) |
| `@ollama` | `/var/lib/ollama` | `compress=zstd,noatime` | ❌ preservar (modelos Ollama) |
| `@neo4j` | `/var/lib/neo4j` | `compress=zstd,noatime` | ❌ preservar (grafo) |
| `@backups` | `/var/backups/kryonix` | `compress=zstd,noatime` | ❌ preservar |
| `@snapshots` | `/.snapshots` | `compress=zstd,noatime` | ✅ sim |

> Subvolumes marcados como ❌ devem ser **snapshottados antes de qualquer operação destrutiva**.

---

## Disko alvo (esboço)

```nix
# hosts/glacier/disks.nix (FUTURO — não usar no host atual)
{ ... }:
{
  disko.devices = {
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
              extraArgs = [ "-f" "-L" "GLACIER-SYSTEM" ];
              subvolumes = {
                "@root"     = { mountpoint = "/";                    mountOptions = [ "compress=zstd" "noatime" ]; };
                "@nix"      = { mountpoint = "/nix";                 mountOptions = [ "compress=zstd" "noatime" ]; };
                "@log"      = { mountpoint = "/var/log";             mountOptions = [ "compress=zstd" "noatime" ]; };
                "@home"     = { mountpoint = "/home";                mountOptions = [ "compress=zstd" "noatime" "autodefrag" ]; };
                "@storage"  = { mountpoint = "/home/storage";        mountOptions = [ "compress=zstd" "noatime" ]; };
                "@kryonix"  = { mountpoint = "/var/lib/kryonix";     mountOptions = [ "compress=zstd" "noatime" ]; };
                "@ollama"   = { mountpoint = "/var/lib/ollama";      mountOptions = [ "compress=zstd" "noatime" ]; };
                "@neo4j"    = { mountpoint = "/var/lib/neo4j";       mountOptions = [ "compress=zstd" "noatime" ]; };
                "@backups"  = { mountpoint = "/var/backups/kryonix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                "@snapshots"= { mountpoint = "/.snapshots";          mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
```

---

## Checklist pós-instalação (após `nixos-install`)

### Rede e acesso

- [ ] SSH porta `2224` funcional
- [ ] Tailscale conectado e autenticado
- [ ] IP LAN alvo `10.0.0.2` configurado (estático ou DHCP reservado)

### Secrets (gerados manualmente, fora do Git)

- [ ] `/etc/kryonix/brain.env` criado com `KRYONIX_BRAIN_API_KEY` (ver README.md)
- [ ] `/etc/kryonix/neo4j.env` criado com `NEO4J_AUTH` e `NEO4J_PASSWORD`
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
sudo btrfs subvolume snapshot /var/lib/ollama     /var/backups/kryonix/pre-install-ollama
sudo btrfs subvolume snapshot /var/lib/neo4j      /var/backups/kryonix/pre-install-neo4j
sudo btrfs subvolume snapshot /home/storage       /var/backups/kryonix/pre-install-storage
```

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
