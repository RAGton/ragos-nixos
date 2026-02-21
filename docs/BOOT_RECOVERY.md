# Boot Recovery — Initrd Emergency Mode

## Diagnóstico

### Sintoma

O sistema para na inicialização com:

```
Timed out waiting for device /dev/disk/by-partlabel/disk-nvme0n1-system
Dependency failed for Initrd Root Device
```

### Causa Raiz

O módulo `disko` gera automaticamente entradas `fileSystems` usando **PARTLABEL**
no formato `disk-<diskname>-<partname>`. Para a partição raiz:

```
device = "/dev/disk/by-partlabel/disk-nvme0n1-system"
```

Se o disco foi formatado fora do disko, reformatado com outra ferramenta, ou o
PARTLABEL foi perdido, essa entrada deixa de existir e o initrd entra em modo
de emergência.

A solução é sobrescrever a entrada gerada pelo disko com **UUID**, que é criado
pelo `mkfs.btrfs` e persiste enquanto o filesystem existir.

---

## PASSO 1 — Analisar a Configuração Atual

Arquivo relevante: `hosts/inspiron/hardware-configuration.nix`

| Ponto de montagem | Dispositivo esperado (antes do fix) | Tipo |
|---|---|---|
| `/boot` | `/dev/disk/by-partlabel/disk-nvme0n1-ESP` | vfat |
| `/` | `/dev/disk/by-partlabel/disk-nvme0n1-system` | btrfs subvol=@ |
| `/nix` | `/dev/disk/by-partlabel/disk-nvme0n1-system` | btrfs subvol=@nix |
| `/home` | `/dev/disk/by-partlabel/disk-nvme0n1-home` | btrfs subvol=@home |
| `/RAG-DATA` | `/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785682AEA-part1` | btrfs |

O sistema usa **PARTLABEL** para tudo gerado pelo disko e **by-id** para o SDA.

---

## PASSO 2 — Descobrir os UUIDs Reais (Live ISO)

Boot pelo NixOS Live ISO e execute os comandos abaixo para mapear as partições
reais:

```bash
# Visão geral das partições e UUIDs
lsblk -f

# Detalhes completos (inclui UUID, PARTLABEL, PARTUUID, TYPE)
blkid

# UUID do EFI (p1)
blkid /dev/nvme0n1p1

# UUID do SISTEMA btrfs (p3) — será o mesmo para /, /nix, /log, etc.
blkid /dev/nvme0n1p3

# UUID do HOME btrfs (p4)
blkid /dev/nvme0n1p4

# Listar by-uuid disponíveis
ls -l /dev/disk/by-uuid/

# Listar by-partlabel disponíveis (para confirmar se existem ou não)
ls -l /dev/disk/by-partlabel/

# Listar by-partuuid disponíveis
ls -l /dev/disk/by-partuuid/
```

### Como identificar a partição raiz

A saída do `blkid /dev/nvme0n1p3` terá a forma:

```
/dev/nvme0n1p3: LABEL="NIXOS-SYSTEM" UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" TYPE="btrfs" ...
```

Copie o valor do campo `UUID=`.

---

## PASSO 3 — Patch Aplicado

O arquivo `hosts/inspiron/hardware-configuration.nix` já contém os UUIDs reais
confirmados pelo `lsblk -f` executado no Live ISO:

| Partição | UUID | Ponto de montagem |
|---|---|---|
| nvme0n1p1 (EFI) | `4509-A31C` | `/boot` |
| nvme0n1p3 (btrfs NIXOS-SYSTEM) | `9d31dd94-2893-4c2a-bc47-bb2c4a8d55fc` | `/` (e subvolumes) |

```nix
# EFI /boot
fileSystems."/boot" = lib.mkForce
  { device = "/dev/disk/by-uuid/4509-A31C";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

# Raiz /
fileSystems."/" = lib.mkForce
  { device = "/dev/disk/by-uuid/9d31dd94-2893-4c2a-bc47-bb2c4a8d55fc";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };
```

---

## PASSO 4 — Reconstruir e Verificar o Boot (Live ISO)

Execute os passos abaixo **no Live ISO**, após editar o arquivo com o UUID real:

```bash
# 1. Montar a partição raiz (btrfs, subvol @)
mount -o subvol=@,compress=zstd,noatime /dev/disk/by-uuid/<UUID-de-nvme0n1p3> /mnt

# 2. Montar as demais partições necessárias para o nixos-enter
mount -o subvol=@nix,compress=zstd,noatime  /dev/disk/by-uuid/<UUID-de-nvme0n1p3> /mnt/nix
mount /dev/disk/by-uuid/<UUID-de-nvme0n1p1> /mnt/boot

# 3. Entrar no ambiente do sistema instalado
nixos-enter --root /mnt

# 4. Navegar até o repositório (ajuste o caminho conforme necessário)
cd /home/rocha/dotfiles-NixOs   # ou onde o repo estiver clonado

# 5. Editar o hardware-configuration.nix com os UUIDs reais (se ainda não feito)
# nano hosts/inspiron/hardware-configuration.nix

# 6. Gerar uma nova entrada de boot SEM ativar imediatamente
nixos-rebuild boot --flake .#inspiron

# 7. Sair do nixos-enter
exit

# 8. Desmontar e reiniciar
umount -R /mnt
reboot
```

> **Por que `nixos-rebuild boot` e não `switch`?**
>
> O `boot` gera uma nova entrada no bootloader (GRUB) para a próxima
> inicialização, mas mantém o sistema atual rodando. Isso evita que uma
> configuração errada quebre o sistema em execução. Só use `switch` depois
> de confirmar que o novo boot funciona.

---

## Referência Rápida — Estrutura do Disco

```
NVMe (SM2P41C3 ADATA 512GB)
├── p1  EFI   1G    /boot        vfat
├── p2  swap  16G               swap
├── p3  btrfs 260G  NIXOS-SYSTEM
│   ├── @         →  /
│   ├── @nix      →  /nix
│   ├── @log      →  /var/log
│   ├── @cache    →  /var/cache
│   ├── @containers → /var/lib/containers
│   ├── @libvirt  →  /var/lib/libvirt
│   ├── @snapshots →  /.snapshots
│   ├── @persist  →  /persist
│   └── @tmp      →  /tmp
└── p4  btrfs ~200G NIXOS-HOME
    └── @home     →  /home

SDA (Kingston SA400S37 240G)  ← NUNCA FORMATAR
└── sda1 btrfs  /RAG-DATA
```

Todos os subvolumes em p3 compartilham o **mesmo UUID**. Basta um UUID para
corrigir todos eles.
