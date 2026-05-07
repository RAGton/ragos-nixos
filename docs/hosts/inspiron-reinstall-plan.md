# Inspiron — Plano de Reinstalação

> ⚠️ **Este documento é apenas um PLANO.** Não rodar `disko`, `nixos-install` ou formatação sem backup.

**Status:** VALIDADO contra o sistema real em 2026-05-07.

---

## Fontes canônicas

- [`hosts/inspiron/hardware-configuration.nix`](../../hosts/inspiron/hardware-configuration.nix) — UUIDs e mounts reais
- [`hosts/inspiron/disks.nix`](../../hosts/inspiron/disks.nix) — layout Disko para formatação

---

## Hardware

| Disco | ID | Tipo | Capacidade |
|---|---|---|---|
| `nvme0n1` | `nvme-SM2P41C3_NVMe_ADATA_512GB_DM382UX7D58F` | NVMe | 477G |
| `sda` | `ata-KINGSTON_SA400S37240G_50026B7785682AEA` | SATA SSD | 224G |

**CPU:** Intel Core i5-8265U  
**GPU:** Intel UHD 620 (i915) + AMD Radeon (amdgpu)

---

## Layout validado

### NVMe (`nvme0n1`) — gerenciado pelo Disko

```
nvme0n1
├── p1  ESP/FAT32   1G       → /boot           UUID: 4509-A31C
├── p2  swap       16G                          UUID: 8b6df5d3-...
├── p3  Btrfs     260G       → subvolumes de sistema
│   ├── @           → /
│   ├── @nix        → /nix
│   ├── @log        → /var/log
│   ├── @cache      → /var/cache
│   ├── @containers → /var/lib/containers
│   ├── @libvirt    → /var/lib/libvirt
│   ├── @snapshots  → /.snapshots
│   ├── @persist    → /persist
│   └── @tmp        → /tmp
└── p4  Btrfs     177G       → @home → /home   UUID: a8b6794b-...
```

### SATA Kingston (`sda`) — NÃO gerenciado pelo Disko

```
sda
└── sda1  Btrfs             → /RAG-DATA (NUNCA FORMATAR)
```

---

## Opções Btrfs

Todas as montagens usam: `compress=zstd,noatime`  
`/home` adiciona: `autodefrag`

---

## Checklist pré-reinstalação

### Backup obrigatório

```bash
# HOME é preservável (partição separada), mas backup é prudente
sudo btrfs subvolume snapshot /home /home/.snapshot-pre-install

# RAG-DATA nunca é tocado pelo disko, mas confirme
lsblk -f /dev/sda1
```

### Confirmar IDs dos discos

```bash
ls -la /dev/disk/by-id/ | grep -E "nvme-SM2P41C3|KINGSTON"
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT
```

---

## Reinstalação

```bash
# No Live CD / USB NixOS:
sudo nix run github:nix-community/disko -- --mode disko ./hosts/inspiron/disks.nix
sudo nixos-install --flake .#inspiron
```

> ⚠️ Isto formata p1, p2, p3 do NVMe. A p4 (home) e sda1 (RAG-DATA) **não são tocados**.

---

## Checklist pós-reinstalação

- [ ] Boot via GRUB/systemd-boot funcional
- [ ] Todos os subvolumes montados (`findmnt -t btrfs`)
- [ ] `/home` preservado com dados do usuário
- [ ] `/RAG-DATA` acessível
- [ ] Swap ativo (`cat /proc/swaps`)
- [ ] UUIDs conferem com `hardware-configuration.nix`
- [ ] Hyprland/Caelestia session funcional
- [ ] Tailscale conectado
- [ ] SSH funcional

---

## Referências

- [Glacier layout plan](glacier-disko-plan.md)
- [Hardware config](../../hosts/inspiron/hardware-configuration.nix)
- [Disks config](../../hosts/inspiron/disks.nix)
