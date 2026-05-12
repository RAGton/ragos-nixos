# Workflow 02 — Rollback

## Antes de mexer no storage

```bash
cd /etc/kryonix

ts="$(date +%Y%m%d-%H%M%S)"
mkdir -p "/var/lib/kryonix-backups/$ts"

cp -a /var/lib/kryonix \
  "/var/lib/kryonix-backups/$ts/kryonix"
```

## Rollback Git

```bash
git status --short
git log --oneline --decorate -10
git revert <commit>
```

## Rollback NixOS

```bash
sudo nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback
```

ou no boot, selecionar geração anterior no GRUB/systemd-boot.

## Rollback systemd services

```bash
sudo systemctl stop kryonix-brain-api || true
sudo systemctl stop kryonix-lightrag || true
sudo systemctl stop ollama || true
```

## Restaurar storage

Somente se necessário e com Brain parado:

```bash
sudo systemctl stop kryonix-brain-api kryonix-lightrag || true
rm -rf /var/lib/kryonix
cp -a /var/lib/kryonix-backups/<TS>/kryonix \
  /var/lib/kryonix
```
