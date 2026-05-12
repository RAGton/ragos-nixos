# RISK_AREAS

## Auth e acesso

- Tailscale usa `authKeyFile` e nao deve expor chave.
- SSH, GPG, Git signing e tokens GitHub devem ficar fora do repo.
- Autologin/direct login reduz seguranca fisica e exige decisao explicita.

## Secrets

- Nunca commitar secrets.
- Nunca colocar secrets em derivations, logs ou Nix store.
- Caminhos sensiveis conhecidos:
  - `/root/tailscale-authkey.secret`
  - `.ssh/*`
  - `.gnupg/*`
  - tokens de CI/CD

## Migrations e rename

- `kryonix.*` e ativo; `rag.*` e alias temporario.
- `kryonix` e CLI primaria; `kryonix` e wrapper legado.
- Remover compatibilidade cedo pode quebrar hosts instalados, scripts e docs.

## Deploy e aplicacao

- `kryonix switch` altera o sistema ativo.
- `kryonix boot` e mais seguro para mudancas arriscadas.
- `kryonix test` testa sem persistir como default.
- `kryonix sync`/`deploy` mexem em checkout instalado e devem ser usados com cuidado.

## Billing/pagamento

Nao ha billing/pagamento detectado no repo.

## Dados de cliente

Nao ha dados de cliente detectados. Ha dados pessoais e operacionais do mantenedor, usuarios e hosts; trate nomes, emails, chaves publicas e paths como contexto sensivel quando expostos.

## Nix, systemd, firewall e discos

- `hosts/*/hardware-configuration.nix`: alto impacto.
- `hosts/*/disks.nix`: alto risco.
- `hosts/glacier/disks.nix`: nao usar no host instalado atual.
- `hosts/glacier/ragenterprise-disko.nix`: apenas disco extra de virtualizacao.
- `modules/nixos/installer/*`: pode afetar ISO/instalacao.
- `networking.firewall`, bridges, libvirt, Tailscale e SSH podem cortar acesso.
- `boot.loader`, kernel, NVIDIA, initrd e systemd podem impedir boot/session.

## Virtualizacao

- `glacier` usa `/srv/ragenterprise` para imagens, ISOs, templates, snippets e backups.
- Mudancas em libvirt/KVM/bridges podem quebrar VMs ou rede.
- Docker, Podman e VirtualBox podem conflitar com KVM ou aumentar superficie de ataque.

## Comandos perigosos

Nao executar sem aprovacao humana explicita:

```sh
sudo nixos-rebuild switch
kryonix switch
kryonix deploy
kryonix sync
make format-full ALLOW_DANGEROUS=1
make format-system ALLOW_DANGEROUS=1
make install-system ALLOW_DANGEROUS=1
disko
mkfs.*
parted
fdisk
wipefs
nixos-install
rm -rf /
```

## Areas com complexidade acumulada

- `desktop/hyprland/user.nix`
- `packages/kryonix-cli.nix`
- docs historicas divergentes de Kryonix/Kryonix
- overlays temporarios que dependem de estado upstream
