# Kora — Segurança

## Padrão local-first

A Kora opera inteiramente local por padrão:

| Recurso | Local |
|---|---|
| Áudio | Local (futuro) |
| Imagem | Local (futuro) |
| LLM | Local via Ollama |
| Memória | Local |
| Grafo | Local Neo4j |
| Vault | Local Obsidian |
| Automações | LAN/Tailscale |
| Cloud | Opt-in, nunca padrão |

## Autenticação

A Kora usa chaves separadas para garantir isolamento:

| Chave | Propósito | Arquivo |
|---|---|---|
| `KORA_API_KEY` | Protege a API pública da Kora | `/etc/kryonix/kora.env` |
| `KRYONIX_BRAIN_API_KEY` | Acesso interno Kora → Brain | `/etc/kryonix/brain.env` |

**Por quê separar?** Se o token de interface (Web/Desktop/Mobile) vazar, não compromete automaticamente o acesso direto ao Brain.

### Geração de chave

```bash
KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
tmp="$(mktemp)"
printf "KORA_API_KEY=%s\n" "$KEY" > "$tmp"
sudo install -m 600 -o root -g root "$tmp" /etc/kryonix/kora.env
rm -f "$tmp"
unset KEY
```

## Portas

| Serviço | Porta | Bind |
|---|---|---|
| Kora API | 8787 | `127.0.0.1` (LAN/Tailscale via firewall) |
| Brain API | 8000 | `127.0.0.1` (LAN/Tailscale via firewall) |
| Ollama | 11434 | `127.0.0.1` |
| Neo4j HTTP | 7474 | `127.0.0.1` |
| Neo4j Bolt | 7687 | `127.0.0.1` |
| Home Assistant | 8123 | LAN/Tailscale (futuro) |

Nenhuma porta exposta publicamente por padrão.

## Secrets

Nunca colocar em:
- Código fonte / Git
- Derivations Nix / `/nix/store`
- Logs
- Stdout de serviços
- Variáveis inline no systemd
- README, walkthrough, issues ou commits

## Anti-alucinação

A Kora implementa grounding obrigatório para:
- Kryonix (estado do sistema)
- Comandos NixOS
- Diagnóstico de serviços
- Automações físicas
- Segurança
- Dados financeiros
- Saúde
- Ações destrutivas

Respostas sem fonte usam: "Não tenho grounding suficiente para afirmar isso."

## Controle de comandos (futuro shell_guard)

| Nível | Exemplos |
|---|---|
| **Livre** | `git status`, `systemctl status`, `df -h`, `nvidia-smi`, `kryonix doctor` |
| **Confirmação** | `kryonix switch`, `systemctl restart`, firewall, HA automations |
| **Proibido** | `disko`, `mkfs`, `wipefs`, `rm -rf`, `git reset --hard` |
