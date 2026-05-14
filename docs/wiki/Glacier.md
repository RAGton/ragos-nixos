# Glacier

Status: Implementado (host principal)

## Resumo
🧊 Glacier é o host principal do Kryonix para IA local, gaming e virtualização. Ele hospeda Ollama, Brain API, LightRAG e Neo4j.

## Papel do host
- Workstation diária + gaming.
- Servidor de IA (Ollama + Brain API + LightRAG).
- Virtualização (KVM/libvirt).

## Rede e acesso
- SSH: porta `2224`.
- IP alvo: `10.0.0.2` (LAN).
- Acesso preferido: LAN/Tailscale.

## Storage operacional
- Base: `/srv/ragenterprise`.
- Subpastas: `images`, `iso`, `templates`, `snippets`, `backups`.

## Quando usar
Para validar runtime de IA e operações server-side.

## Comandos relevantes
```sh
kryonix check --host glacier
kryonix rebuild --host glacier
kryonix test --host glacier
kryonix brain doctor --local
```

## Riscos
- Não usar `disko`/`disks.nix` no host já instalado.
- Serviços de IA dependem de `/etc/kryonix/brain.env`.

## Links relacionados
- [Hosts](Hosts)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [WayVNC / Acesso Remoto](WayVNC-Acesso-Remoto)
