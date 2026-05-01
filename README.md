# Kryonix

Kryonix é a plataforma NixOS declarativa para workstation, gaming, virtualização, estudo e desenvolvimento.

- Repositório principal: `https://github.com/RAGton/kryonix`
- Vault de conhecimento: `https://github.com/RAGton/kryonix-vault.git`
- Posicionamento público: **Kryonix**
- Idioma: PT-BR | [English](README-en.md)

## O que este projeto é

Este repositório já não é apenas uma coleção de dotfiles. Ele é uma plataforma NixOS declarativa para uso real, com foco em:

- workstation principal
- gaming
- virtualização pessoal com KVM/libvirt
- estudo e desenvolvimento
- branding consistente
- base futura para ISOs instaláveis do Kryonix

## Estado atual

O flake publica hoje:

- `nixosConfigurations` para `inspiron`, `inspiron-nina`, `glacier` e `iso`
- `homeConfigurations` para `rocha@inspiron`, `rocha@glacier` e `nina@inspiron-nina`
- overlays reutilizáveis
- formatter, checks e pacotes `kryonix` e `ragos` compat

O host principal de produto neste momento é o `glacier`, tratado como:

- workstation AMD + NVIDIA
- host gamer
- host de VMs
- laboratório do próprio Kryonix

## Fluxo diário

O fluxo operacional padrão agora é a CLI `kryonix`, instalada no PATH do sistema. A CLI antiga `ragos` continua disponível temporariamente como alias e emite `ragos is deprecated, use kryonix`.

```sh
kryonix switch
kryonix switch --update
kryonix boot --update
kryonix home
kryonix diff
kryonix doctor
kryonix check
kryonix fmt
kryonix iso
```

Ela usa `nh`, `nix`, `nvd` e o hostname atual para reduzir atrito operacional no dia a dia.

## Quick start

Se quiser clonar já com o naming novo:

```sh
git clone https://github.com/RAGton/kryonix kryonix
cd kryonix
```

Inspecionar a flake:

```sh
nix flake show --all-systems
nix flake check --keep-going
```

Aplicar o host atual:

```sh
kryonix switch
```

Aplicar explicitamente um host:

```sh
kryonix switch --host glacier
```

## Glacier

O `glacier` usa o `hardware-configuration.nix` restaurado como fonte real de boot, root e home. O `disks.nix` fica reservado para provisionamento e **não** deve ser usado de forma destrutiva no host instalado atual.

Além do storage base, o host mantém um storage operacional para virtualização em:

- `/srv/ragenterprise`
- `/srv/ragenterprise/images`
- `/srv/ragenterprise/iso`
- `/srv/ragenterprise/templates`
- `/srv/ragenterprise/snippets`
- `/srv/ragenterprise/backups`

## Branding

O projeto já padroniza o branding do Kryonix no:

- `Plymouth`
- `GRUB`
- `GDM`
- wallpaper do desktop
- `/etc/os-release` e `/etc/issue`

O produto é apresentado publicamente como **Kryonix**. O nome antigo permanece apenas como compatibilidade temporária de CLI/opções/caminho.

## IA Local e Serviços do Brain

O `glacier` agora conta com serviços de Inteligência Artificial nativos (Ollama, LightRAG, Kryonix Brain API). Antes de ativar a infraestrutura pela primeira vez, é obrigatório gerar uma chave de segurança para acesso à API:

1. Gere uma chave segura aleatória:
```sh
python3 -c "import secrets; print(secrets.token_hex(32))"
```

2. Crie ou injete no arquivo de ambiente `/etc/kryonix/brain.env` que fica fora do controle de versão:
```sh
KRYONIX_BRAIN_KEY="<chave_gerada_aqui>"
LIGHTRAG_VERBOSE="1"
```

Se esse arquivo não existir, o Systemd se recusará a subir as units `kryonix-brain-api` e `kryonix-lightrag` no momento do `kryonix switch`.

## Documentação

- [Operação diária e CLI](docs/OPERATIONS.md)
- [Papel do host glacier](docs/GLACIER.md)
- [Índice da documentação](docs/INDEX.md)

## Observações de segurança operacional

- não use `disko`, `format-*` ou `install-system` no `glacier` já instalado
- não trate `hosts/glacier/disks.nix` como verdade do hardware atual
- prefira `kryonix test` e `kryonix boot` antes de mudanças de maior risco

## Licença

MIT. Veja [LICENSE](LICENSE).
