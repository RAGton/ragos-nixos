# Relatório de Backup e Plano de Teste Live ISO - Glacier

## 1. Status do Backup (Windows)
- **Data/Hora**: 2026-04-28 23:15
- **Local**: `/srv/kryonix-backups\2026-04-28_23-15`
- **Tamanho Total**: ~507 MB
- **Integridade**: Checksums gerados em `manifest.csv`.

### Arquivos Críticos Validados:
- [x] `storage/graph_chunk_entity_relation.graphml` (4.2 MB)
- [x] `storage/kv_store_text_chunks.json` (3.9 MB)
- [x] `storage/vdb_chunks.json` (20.0 MB)
- [x] `storage/kv_store_doc_status.json` (1.5 MB)
- [x] `config/ollama-models.txt` (Lista de modelos qwen2.5, qwen3.5, nomic-embed)
- [x] `vault/` (Cópia completa do Obsidian Vault)

---

## 2. Plano de Teste Live ISO (NixOS)

Este plano descreve como validar o hardware do Glacier usando uma ISO customizada sem realizar alterações nos discos.

### A. Geração da ISO
No host Inspiron (ou qualquer host NixOS):
```bash
cd /etc/kryonix
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```
A imagem será gerada em `./result/iso/nixos-*.iso`.

### B. Procedimento de Boot
1. Gravar a ISO em um pendrive (`ventoy` ou `dd`).
2. Bootar o Glacier via USB.
3. Selecionar "Kryonix Live Desktop".

### C. Checkpoint de Hardware (Pós-Boot)
Uma vez no ambiente Live, validar os seguintes itens:

#### 1. GPU NVIDIA (RTX 4060)
```bash
nvidia-smi
```
*Esperado*: Listagem da GPU e versão do driver.

#### 2. Rede (2.5Gb Ethernet)
```bash
ip addr
ping google.com
```
*Esperado*: Interface `enp14s0` (ou similar) com IP e conectividade.

#### 3. Tailscale
```bash
sudo tailscale up --authkey <authkey-temporaria>
tailscale status
```
*Esperado*: Glacier visível na malha Tailscale.

#### 4. Discos e BTRFS
```bash
lsblk
sudo mount /dev/nvme0n1p3 /mnt -o ro  # Montar Windows como read-only para teste
ls /mnt/Users/aguia/Documents/kryonix-backups
```
*Esperado*: Acesso aos arquivos de backup criados no Windows.

### D. Conclusão do Teste
Se todos os itens acima funcionarem, o blueprint do Glacier é considerado **Hardware Compatible**.
**NÃO RODAR `nixos-install` NESTA FASE.**
