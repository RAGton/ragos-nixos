# Guia de Instalação Declarativa NixOS com Layout Btrfs Manual — Glacier 🧊

Este documento descreve os passos exatos para realizar a instalação declarativa limpa do host **Glacier** sobre um layout Btrfs particionado manualmente, sem depender de scripts do `disko`, sem conflitos com o link simbólico `/var/lib/kryonix` e otimizando o uso de recursos de hardware para evitar congelamentos na ISO live.

---

## ⚠️ Precaução Crítica sobre Discos

Antes de rodar qualquer comando de formatação, certifique-se de identificar os discos corretamente via `lsblk` ou `blkid`.
* **Disco do Sistema**: `/dev/nvme0n1` (~238 GB) — Alvo de instalação.
* **Disco de Dados**: `/dev/nvme1n1` (~953 GB) — Armazenamento do RAG/Brain.
* **Pendrive de Boot/Ventoy**: `/dev/sda` — **NÃO TOCAR!** Qualquer comando destrutivo em `/dev/sda` corromperá sua mídia de instalação live.

---

## 1. Particionamento Manual

Inicie a ISO live do NixOS e execute o particionamento usando `gdisk`, `parted` ou utilitário equivalente.

### Disco `/dev/nvme0n1` (Sistema):
1. **Partição EFI**: `/dev/nvme0n1p1` (~1 GB), Tipo: `EF00` (EFI System).
2. **Partição Raiz (Btrfs)**: `/dev/nvme0n1p2` (Restante do disco), Tipo: `8300` (Linux filesystem).

### Disco `/dev/nvme1n1` (Dados):
1. **Partição Única (Btrfs)**: `/dev/nvme1n1p1` (Todo o disco), Tipo: `8300`.

---

## 2. Formatação das Partições

```bash
# Formatar partição EFI do sistema
sudo mkfs.fat -F 32 -n EFI /dev/nvme0n1p1

# Formatar partição raiz do sistema (Btrfs)
sudo mkfs.btrfs -L NIXOS -f /dev/nvme0n1p2

# Formatar partição de dados (Btrfs)
sudo mkfs.btrfs -L DATA -f /dev/nvme1n1p1
```

---

## 3. Criação de Subvolumes Btrfs

Para garantir um layout declarativo moderno com suporte a snapshots (`snapper`) e isolamento de logs, crie a seguinte estrutura de subvolumes:

```bash
# Montar partição raiz temporariamente
sudo mount /dev/nvme0n1p2 /mnt

# Criar subvolumes do sistema
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@log
sudo btrfs subvolume create /mnt/@snapshots

# Desmontar raiz temporária
sudo umount /mnt

# Montar partição de dados temporariamente
sudo mkdir -p /mnt-data
sudo mount /dev/nvme1n1p1 /mnt-data

# Criar subvolumes de dados dedicados
sudo btrfs subvolume create /mnt-data/@kryonix-state
sudo btrfs subvolume create /mnt-data/@ollama

# Desmontar dados temporários
sudo umount /mnt-data
sudo rmdir /mnt-data
```

---

## 4. Estrutura de Montagem de Instalação

Monte todos os subvolumes com as flags de otimização recomendadas para SSDs NVMe (`noatime`, `compress=zstd`):

```bash
# Opções padrão de montagem Btrfs para SSD/NVMe
BTRFS_OPTS="noatime,compress=zstd,ssd,space_cache=v2"

# 1. Montar a raiz principal (@) em /mnt
sudo mount -o subvol=@,${BTRFS_OPTS} /dev/nvme0n1p2 /mnt

# 2. Criar diretórios para os outros subvolumes
sudo mkdir -p /mnt/{boot,home,nix,var/log,.snapshots}

# 3. Montar subvolumes do sistema
sudo mount -o subvol=@home,${BTRFS_OPTS} /dev/nvme0n1p2 /mnt/home
sudo mount -o subvol=@nix,${BTRFS_OPTS} /dev/nvme0n1p2 /mnt/nix
sudo mount -o subvol=@log,${BTRFS_OPTS} /dev/nvme0n1p2 /mnt/var/log
sudo mount -o subvol=@snapshots,${BTRFS_OPTS} /dev/nvme0n1p2 /mnt/.snapshots

# 4. Montar a partição EFI (/boot)
sudo mount /dev/nvme0n1p1 /mnt/boot

# 5. Criar pontos de montagem para os volumes de dados dedicados
sudo mkdir -p /mnt/var/lib/kryonix/ollama

# 6. Montar subvolumes do disco de dados (/dev/nvme1n1p1)
sudo mount -o subvol=@kryonix-state,${BTRFS_OPTS} /dev/nvme1n1p1 /mnt/var/lib/kryonix
sudo mount -o subvol=@ollama,${BTRFS_OPTS} /dev/nvme1n1p1 /mnt/var/lib/kryonix/ollama
```

---

## 5. Criação Preventiva de Swap (RAM Guard)

Com 16 GB de RAM física, rodar processos do Nix ou carregar serviços pesados em ambiente live sem swap pode travar a sessão ou estourar a memória (OOM). Crie um swapfile temporário no disco de dados para garantir estabilidade:

```bash
# Criar diretório seguro para o swap
sudo mkdir -p /mnt/var/lib/kryonix/swap
sudo chmod 700 /mnt/var/lib/kryonix/swap

# No Btrfs, swapfiles exigem NOCOW (No Copy-on-Write)
sudo chattr +C /mnt/var/lib/kryonix/swap

# Criar arquivo de swap de 8 GiB
sudo dd if=/dev/zero of=/mnt/var/lib/kryonix/swap/swapfile bs=1M count=8192 status=progress
sudo chmod 600 /mnt/var/lib/kryonix/swap/swapfile

# Inicializar e ativar swap
sudo mkswap /mnt/var/lib/kryonix/swap/swapfile
sudo swapon /mnt/var/lib/kryonix/swap/swapfile
```

---

## 6. Clonagem do Repositório e Geração do Hardware-Config

Clone o repositório **Kryonix** diretamente na árvore montada para prosseguir com a instalação limpa:

```bash
# Criar diretório de configuração do NixOS
sudo mkdir -p /mnt/etc/kryonix

# Clonar o repositório
git clone --recurse-submodules https://github.com/RAGton/kryonix /mnt/etc/kryonix

# Gerar a configuração de hardware do instalador live
sudo nixos-generate-config --root /mnt

# Copiar o hardware-configuration.nix gerado para a pasta correspondente no host Glacier
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/kryonix/hosts/glacier/hardware-configuration.nix

# Aplicar permissões adequadas
sudo chown -R 1000:100 /mnt/etc/kryonix
```

---

## 7. Compilação e Instalação (Sem Freezes)

Para compilar e instalar o sistema sem riscos de estouro de memória no live-boot, execute o comando limitando o número de threads e jobs de compilação simultâneos:

```bash
cd /mnt/etc/kryonix

# Instalar o NixOS usando o flake com limites explícitos de CPU/Jobs
sudo nixos-install --flake /mnt/etc/kryonix#glacier \
  --show-trace \
  --max-jobs 2 \
  --cores 2
```

---

## 8. Pós-Instalação: Inserindo Credenciais e Chaves IA

Após reiniciar no Glacier instalado:
1. **Desative o Swap Temporário** se preferir usar uma partição ou zram dedicada permanente declarada nas configurações Nix.
2. **Chave do Brain API**: Certifique-se de rodar o comando de geração para criar o arquivo canônico com permissões restritas em `/etc/kryonix/brain.env`:
   ```bash
   kryonix brain api-key generate
   ```
3. O diretório `/var/lib/kryonix` receberá corretamente todos os bancos e dados de embeddings diretamente no subvolume `@kryonix-state` no disco NVMe secundário de alto desempenho.
