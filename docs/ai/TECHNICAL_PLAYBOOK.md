# Technical Playbook: Kryonix Distributed Operations

Este guia consolida as melhores práticas para operação do ecossistema distribuído Kryonix, integrando o Brain (LightRAG) e o fluxo via Tailscale.

## 1. Fluxo Operacional (CLI)

Use a CLI `kryonix` para todas as operações. O comando `kryonix` foi descontinuado em favor do `kryonix`.

### Sincronização e Deploy
- **`kryonix pull`**: Sincroniza o repositório local com o remoto (rebase) e atualiza submodules.
- **`kryonix sync`**: Atalho para `pull` + `check` + `switch`. É o comando recomendado para atualização diária.
- **`kryonix doctor`**: Diagnóstico completo do sistema, incluindo rede Tailscale e saúde do Brain.

## 2. Kryonix Brain (RAG)

O Brain é o motor de conhecimento do projeto.

### Comandos Principais
- **`kryonix brain search "pergunta"`**: Consulta o grafo de conhecimento distribuído.
- **`kryonix brain stats`**: Verifica a integridade e o tamanho do grafo (entidades/relações).
- **`kryonix brain health`**: Valida a conectividade com o servidor RAG remoto.

### Segurança de Secrets
- **NUNCA** commite o arquivo `brain.env`.
- No Inspiron (Client), mantenha a key em `/etc/kryonix/brain.env` com permissão `600`.
- No Glacier (Server), a key é injetada via variável de ambiente de máquina.

## 3. Rede e Conectividade (Tailscale)

- **Acesso Remoto**: Todo o tráfego Ollama e Brain API deve passar pelo Tailscale.
- **IPs Fixos**:
  - Glacier: `100.108.71.36`
  - Inspiron: `100.91.45.6`
- **Firewall**: O script `NixOS firewall module` endurece o Glacier restringindo acesso ao range `100.64.0.0/10`.

## 4. Troubleshooting

### Falha no Brain Search
1. Verifique `kryonix doctor`.
2. Confirme se o Tailscale está `active`.
3. Teste `curl http://100.108.71.36:8000/health`.
4. Verifique se a `KRYONIX_BRAIN_KEY` no `/etc/kryonix/brain.env` coincide com a do servidor.

### Erros de Avaliação Nix
1. Rode `kryonix check` para encontrar erros de sintaxe ou opções inexistentes.
2. Use `kryonix rebuild` para validar o build sem aplicar mudanças.

---
*Gerado via Kryonix Brain & Antigravity AI*
