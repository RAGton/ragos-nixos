# Glacier Live ISO

## Objetivo
Testar o ambiente NixOS no hardware do Glacier sem realizar alterações permanentes (sem instalar).

## Localização do Arquivo
A ISO é gerada no Inspiron e copiada para:
`C:\Users\aguia\Documents\kryonix-artifacts\iso\kryonix-glacier-live.iso`

## Como gravar no pendrive
1. Utilize uma ferramenta como **Ventoy** (recomendado), **Rufus** ou **BalenaEtcher**.
2. No Ventoy, basta copiar o arquivo `.iso` para a partição de dados do pendrive.
3. No Rufus, selecione o pendrive e a ISO, e use o modo "DD" se solicitado.

## Como bootar
1. Reinicie o Glacier.
2. Pressione a tecla de boot menu da placa-mãe (Geralmente F11, F12 ou F8).
3. Selecione o pendrive USB.
4. Escolha a opção "Kryonix Glacier Live".

## Testes Recomendados no Ambiente Live
Uma vez dentro da ISO, abra um terminal e execute:

### 1. Conectividade e Rede
```bash
ip addr            # Verificar se a placa de rede 2.5Gb foi detectada
ping 1.1.1.1       # Testar saída para internet
tailscale status   # Verificar se o Tailscale está funcional
```

### 2. Hardware e GPU
```bash
lspci | grep -i nvidia   # Verificar se a RTX 4060 é listada
nvidia-smi               # Verificar se o driver básico carregou
btop                     # Monitorar recursos
```

### 3. Armazenamento (Modo Leitura)
```bash
lsblk                    # Listar discos NVMe
sudo mount /dev/nvme0n1p3 /mnt -o ro  # Montar partição Windows (read-only)
ls /mnt/Users/aguia/Documents/kryonix-backups
```

## REGRAS DE SEGURANÇA
- **NÃO** rode `nixos-install`.
- **NÃO** particione ou formate discos via `parted`, `fdisk` ou `disko`.
- **NÃO** tente restaurar o backup sobre os dados reais do Windows.

## Próxima Fase
Se a rede, GPU e discos forem detectados corretamente, o hardware é compatível e o plano de instalação real pode ser agendado.
