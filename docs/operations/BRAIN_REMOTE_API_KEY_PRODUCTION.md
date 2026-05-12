# Kryonix Brain Remote API Key — Produção

## Objetivo

Este documento detalha o funcionamento, a configuração e o Troubleshooting do acesso remoto seguro do cliente **Inspiron** à API do **Kryonix Brain** hospedada no servidor **Glacier** utilizando autenticação baseada em chaves de acesso via header `X-API-Key`.

## Arquitetura

```txt
Inspiron (Workstation/Cliente)
  └─► CLI: kryonix brain stats/search
        └─► Envia requisição com header "X-API-Key"
              └─► LAN / Tailscale (Porta 8000)
                    └─► Glacier (Servidor IA/Brain)
                          └─► Kryonix Brain API (:8000)
```

O servidor **Glacier** roda a API do Kryonix Brain que gerencia o LightRAG, o armazenamento semântico, o Vector DB e o acesso local ao Ollama. O cliente **Inspiron** consulta o servidor Glacier remotamente de forma autenticada.

---

## Arquivos de Configuração

### 1. Servidor (Glacier)

A chave canônica de produção reside em:
```txt
/etc/kryonix/brain.env
```

**Permissões Obrigatórias:**
* Proprietário/Grupo: `root:root`
* Permissão Física: `0600` (leitura/escrita apenas pelo root)

**Formato:**
```ini
KRYONIX_BRAIN_API_KEY=<sua_chave_de_64_caracteres_hex>
```

> [!IMPORTANT]
> Nunca versione, comite ou exponha o arquivo `brain.env` real. Ele é gerido localmente de forma declarativa ou emergencial direta no Glacier.

### 2. Cliente (Inspiron)

As credenciais do cliente para acesso remoto residem em:
```txt
~/.config/kryonix/brain-remote.env
```

**Permissões Obrigatórias:**
* Permissão Física: `0600` (privado ao usuário local)

**Formato:**
```ini
KRYONIX_ROLE=client
KRYONIX_BRAIN_MODE=remote
KRYONIX_BRAIN_URL=http://rve-glacier:8000
KRYONIX_REMOTE_BRAIN_URL=http://rve-glacier:8000
KRYONIX_BRAIN_API_KEY=<sua_chave_de_64_caracteres_hex>
```

---

## Comandos Oficiais da CLI

A CLI `kryonix` fornece subcomandos integrados para gerir o ciclo de vida da API Key:

```bash
# Verifica se o arquivo de ambiente existe e está correto
kryonix brain api-key status

# Gera uma nova chave de forma segura se nenhuma existir
kryonix brain api-key generate

# Rotaciona a chave atual (backup automático + gera nova + reinicia serviços)
kryonix brain api-key rotate

# Valida o funcionamento contra os endpoints /health e /stats locais
kryonix brain api-key validate
```

---

## Sincronização e Configuração Inicial do Cliente

Para configurar o cliente **Inspiron** com a chave ativa do **Glacier** de maneira segura e sem exibir ou imprimir o segredo no terminal:

```bash
# 1. Garanta a criação do diretório de configurações com permissão privada
mkdir -p ~/.config/kryonix
chmod 700 ~/.config/kryonix

# 2. Transfira a chave ativa de produção do Glacier com segurança
K="$(ssh glacier-public 'sudo sed -n "s/^KRYONIX_BRAIN_API_KEY=//p" /etc/kryonix/brain.env | tail -1')"

if [ -z "$K" ]; then
  echo "ERRO: Chave de API vazia no Glacier"
  exit 1
fi

# 3. Escreva o arquivo de ambiente do cliente
cat > ~/.config/kryonix/brain-remote.env <<EOF
KRYONIX_ROLE=client
KRYONIX_BRAIN_MODE=remote
KRYONIX_BRAIN_URL=http://rve-glacier:8000
KRYONIX_REMOTE_BRAIN_URL=http://rve-glacier:8000
KRYONIX_BRAIN_API_KEY=$K
EOF

# 4. Ajuste permissões do arquivo
chmod 600 ~/.config/kryonix/brain-remote.env
unset K
```

### Validação por Hash (Sem vazar segredo)

Para provar que as chaves local e remota batem sem exibi-las em tela, execute:

```bash
# Hash local no Inspiron
K="$(sed -n 's/^KRYONIX_BRAIN_API_KEY=//p' ~/.config/kryonix/brain-remote.env | tail -1)"
printf '%s' "$K" | sha256sum | cut -c1-16
unset K

# Hash remoto no Glacier
ssh glacier-public '
K="$(sudo sed -n "s/^KRYONIX_BRAIN_API_KEY=//p" /etc/kryonix/brain.env | tail -1)"
printf "%s" "$K" | sha256sum | cut -c1-16
'
```

Os dois hashes SHA-256 parciais exibidos devem ser **idênticos**.

---

## Validação de Funcionamento Remoto

Do **Inspiron**, carregue o arquivo de ambiente e execute os testes:

```bash
# Carregar env
source ~/.config/kryonix/brain-remote.env
export KRYONIX_REMOTE_BRAIN_URL
export KRYONIX_BRAIN_API_KEY

# 1. Health público (sem auth)
curl -fsS "${KRYONIX_REMOTE_BRAIN_URL}/health"

# 2. Stats protegido (requer X-API-Key)
curl -fsS -H "X-API-Key: ${KRYONIX_BRAIN_API_KEY}" "${KRYONIX_REMOTE_BRAIN_URL}/stats" | jq .

# 3. Validação integrada via CLI
kryonix brain remote validate

# 4. Consulta de métricas via CLI
kryonix brain stats

# 5. Busca semântica RAG em produção
kryonix brain search "Kryonix Home Brain"
```

---

## Rotação Segura de Chave

Para rotacionar a chave sem downtime manual e sem expor credenciais:

1. **Gere e Ative no Glacier:**
   ```bash
   ssh glacier-public 'kryonix brain api-key rotate'
   ```
2. **Ressincronize o Cliente Inspiron:**
   Refaça o passo de **Sincronização e Configuração Inicial do Cliente** listado acima.
3. **Valide:**
   ```bash
   kryonix brain remote validate
   ```

---

## Troubleshooting

### 1. ERRO: HTTP 403 (Forbidden) ou Chave Inválida
* **Causa**: A chave configurada no cliente em `brain-remote.env` não condiz com a chave ativa no servidor `/etc/kryonix/brain.env`.
* **Solução**: Execute a validação por hash acima. Caso divirjam, refaça o processo de sincronização segura.
* **Aviso**: Garanta que a variável legada `KRYONIX_BRAIN_KEY` não está poluindo seu ambiente ativo (`unset KRYONIX_BRAIN_KEY`).

### 2. curl /health funciona, mas stats ou search falham com 403
* **Causa**: O header `X-API-Key` não foi preenchido ou a variável `KRYONIX_BRAIN_API_KEY` não está exportada/definida no shell ativo.
* **Solução**: Certifique-se de que rodou `source ~/.config/kryonix/brain-remote.env` e que exportou as variáveis se estiver chamando ferramentas diretas como curl.

### 3. Falha de conexão ("Bad hostname" ou timeout)
* **Causa**: O host `rve-glacier` não pôde ser resolvido pelo DNS local do Inspiron ou a VPN Tailscale está inativa.
* **Solução**: Verifique a conectividade de rede com `ping rve-glacier`. Certifique-se de que a máquina Glacier está online e que o serviço systemd `kryonix-brain-api.service` está rodando no Glacier (`systemctl status kryonix-brain-api`).

---

## Diretrizes de Segurança Invioláveis
1. **Nunca versione `brain.env` ou `brain-remote.env`** no Git. Ambos estão adicionados ao `.gitignore` global.
2. **Nunca use a variável legada `KRYONIX_BRAIN_KEY`**. Use única e exclusivamente `KRYONIX_BRAIN_API_KEY`.
3. **Nunca coloque valores literais de chaves secretas** em derivations ou arquivos de configuração do Nix NixOS que acabam legíveis publicamente no `/nix/store`.
