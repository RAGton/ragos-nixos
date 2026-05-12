# Pipeline de Ingestão do Kryonix Brain

Status: Roadmap / Arquitetura proposta

## Objetivo

Fazer o Brain aprender/indexar o projeto inteiro, incluindo arquivos `.nix`, sem indexar secrets.

## Comandos alvo

```bash
kryonix brain ingest repo --path /etc/kryonix
kryonix brain ingest vault
kryonix brain ingest all
```

## Inclusões

```txt
.nix
.md
.py
.rs
.toml
.json
.yaml
.yml
.sh
.service
.conf
.env.example
```

## Exclusões

```txt
.git/
result
result-*
.direnv/
node_modules/
target/
__pycache__/
*.pyc
*.png
*.jpg
*.jpeg
*.webp
*.mp4
*.iso
*.qcow2
.env
brain.env
id_ed25519*
*.key
*.pem
*.secret
```

## Chunking `.nix`

Dividir por estrutura:

```txt
imports
options/mkOption
config/mkIf
systemd.services
services.*
environment.systemPackages
networking.*
firewall
hardware
attrsets grandes
comentários de módulo
```

## Manifesto incremental

Cada arquivo/chunk deve ter hash. Se o hash não mudou, não reindexar.

Manifestos em:

```txt
/var/lib/kryonix/brain/rag/manifests
```
