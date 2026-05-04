# Guia de Rebuild Seguro do Glacier

Este documento descreve o procedimento canônico e seguro para realizar o rebuild do host **Glacier** (servidor de IA/RAG) no ecossistema Kryonix.

## ⚠️ Avisos Importantes

- **Glacier** é o host de infraestrutura de IA (`10.0.0.2`).
- O rebuild deve ser feito preferencialmente via **Inspiron** (workstation) através da rede (LAN ou Tailscale).
- Nunca use `nixos-rebuild switch` diretamente sem antes validar a configuração.

---

## Procedimento Passo a Passo

### 1. Diagnóstico e Preparação
Certifique-se de que o repositório está limpo e sincronizado antes de qualquer alteração:
```bash
cd /etc/kryonix
git status --short
git submodule status --recursive
```

### 2. Validação do Sistema (Build)
Sempre realize o build sem aplicar as mudanças primeiro para detectar erros de avaliação ou conflitos de pacotes:
```bash
kryonix rebuild --host glacier
```
Se este comando falhar, corrija os erros de Nix antes de prosseguir.

### 3. Aplicação (Switch)
Após a confirmação de que o build passou, aplique as mudanças de configuração:
```bash
kryonix switch --host glacier
```

### 4. Verificação de Pós-Instalação
Verifique se os serviços críticos subiram corretamente:
```bash
kryonix brain doctor --remote
```

---

## Troubleshooting

### Falha de GPU (NVIDIA)
Se o driver NVIDIA falhar após o rebuild:
1. Verifique `journalctl -u nvidia-control-devices`.
2. Verifique se `hardware.nvidia.package` está alinhado com o kernel.

### Brain API Offline
Se o serviço `kryonix-brain` não subir:
1. Verifique o status: `systemctl status kryonix-brain`.
2. Verifique os logs: `journalctl -u kryonix-brain -n 100`.
3. Certifique-se de que o storage em `/var/lib/kryonix/storage` tem as permissões corretas (`kryonix-brain:kryonix-brain`).

### Glacier Offline
Se você perder acesso SSH:
1. Tente acessar via IP local direto (`10.0.0.2` ou `10.0.0.68`).
2. Use o terminal físico se disponível.
3. O rollback pode ser feito no menu do GRUB/Systemd-boot selecionando a geração anterior.

---

## Referências
- `hosts/glacier/default.nix`
- `modules/nixos/services/brain.nix`
- `AGENTS.md`
