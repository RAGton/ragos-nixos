# KRYONIX_VALIDATION

Status: Implementado

## Checklist antes de commit
- `bash -n packages/kryonix-cli/*.sh`
- `nix build .#kryonix --no-link`
- `git diff --check`
- scan de segredos no diff

## Checklist antes de switch
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link -L --show-trace`
- `nh os build .#<host> -L --show-trace`
- validar riscos de rede/boot/firewall/GPU

## Checklist depois de switch
- `kryonix doctor`
- `systemctl --failed`
- smoke dos comandos críticos do host

## Validação Inspiron (cliente)
- `nix run .#kryonix -- brain health`
- `nix run .#kryonix -- brain stats`
- `nix run .#kryonix -- brain cag`
- esperado: `brain health --local` => `LOCAL_DISABLED`

## Validação Glacier (servidor)
- `systemctl status kryonix-brain-api ollama neo4j --no-pager -l`
- `curl -fsS http://127.0.0.1:8000/health`
- `curl -fsS -H "X-API-Key: ..." http://127.0.0.1:8000/stats`
- `curl -fsS -H "X-API-Key: ..." http://127.0.0.1:8000/cag/status`

## Validação Brain/CAG/Neo4j
- Brain storage esperado: `/var/lib/kryonix/brain/storage`
- CAG esperado: `/var/lib/kryonix/brain/cag`
- Neo4j esperado local-only: `127.0.0.1:7474/7687`
- script: `sudo /etc/kryonix/scripts/kryonix-neo4j-doctor.sh`

## Validação de segredos
- nunca commitar `brain.env`, `neo4j.env`, `.env`, chaves privadas
- rodar grep de padrões sensíveis no `git diff`

## Rollback básico
- reverter alterações locais não aplicadas: `git restore <arquivo>`
- rollback de geração NixOS: selecionar geração anterior no bootloader ou `nixos-rebuild --rollback` (com aprovação)
