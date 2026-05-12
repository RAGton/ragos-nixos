# Virtualização (KVM / libvirt / virt-manager) — PT-BR

Este documento cobre o setup declarativo de virtualização neste repositório e como resolver o erro do virt-manager:

> "Não foi possível detectar um hipervisor padrão"

## O que este repo configura

### Sistema (NixOS)

- Módulo: `modules/virtualization/kvm.nix`
- O que ele faz:
  - Habilita `virtualisation.libvirtd.enable = true`
  - Habilita QEMU/KVM via `virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm`
  - Habilita `swtpm` (TPM virtual)
  - Instala pacotes úteis (`virt-manager`, `virt-viewer`, SPICE, etc.)
  - Adiciona o usuário aos grupos `libvirtd` e `kvm`
  - Confia a interface `virbr0` no firewall

### Usuário (Home Manager)

- Módulo: `modules/home-manager/programs/virt-manager/default.nix`
- O que ele faz:
  - Tenta configurar o virt-manager para auto-conectar em `qemu:///system` (via dconf) quando em Linux.

Além disso, em `modules/home-manager/common/default.nix` existe:

- `LIBVIRT_DEFAULT_URI = "qemu:///system";`

## Validação rápida

Rode estes comandos (zsh):

```sh
systemctl status libvirtd --no-pager
virsh -c qemu:///system list --all
lsmod | grep -E 'kvm|kvm_intel|kvm_amd' || true
```

Resultados esperados:

- `libvirtd` deve estar **active (running)**
- `virsh` deve listar (mesmo que vazio)
- `kvm_intel` ou `kvm_amd` devem aparecer conforme sua CPU

## Virt-manager: erro "não detectou hipervisor"

### Causa mais comum

O virt-manager abre sem uma conexão configurada. Ele precisa de uma conexão do tipo:

- `QEMU/KVM` → URI: `qemu:///system`

### Como resolver na UI (manual)

1. Abra o virt-manager
2. Menu: **Arquivo → Adicionar conexão**
3. Marque **Conectar automaticamente**
4. Hypervisor: **QEMU/KVM**
5. Conexão: **Sistema** (`qemu:///system`)

### Se ainda falhar

Checklist:

- Virtualização habilitada na BIOS/UEFI (Intel VT-x / AMD-V)
- Seu usuário está nos grupos:
  - `libvirtd`
  - `kvm`
- O serviço está ativo:
  - `systemctl status libvirtd`

Logs úteis:

```sh
journalctl -u libvirtd --no-pager -n 200
sudo dmesg | grep -i kvm | tail -n 50
```

## Dicas

- `qemu:///session` (rootless) costuma limitar rede/bridges. O recomendado aqui é `qemu:///system`.
- Se você usa Windows 11 em VM, `swtpm` é necessário para o TPM virtual.

