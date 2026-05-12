# Configuração do Cliente Remoto (Inspiron)

Status: Implementado / Produção (V1)

Este documento detalha o funcionamento, as variáveis de configuração e os procedimentos operacionais para utilizar o **Inspiron** como cliente remoto do **Kryonix Brain** que roda no servidor **Glacier**.

---

## 1. Visão Geral da Arquitetura

Para manter o Inspiron leve e evitar a duplicação de índices pesados de GraphRAG no notebook, toda a indexação, armazenamento e consultas de RAG são centralizados no Glacier. O Inspiron se comunica de forma estritamente remota através de chamadas HTTP autenticadas na Brain API do Glacier.

```txt
       [ Inspiron (Client) ]
                 |
                 | (Túnel SSH ou LAN/Tailscale)
                 v
       [ Glacier (Server) ]
                 |
        +--------+--------+
        |                 |
        v                 v
   [ Brain API ]     [ Ollama ]
    (Porta 8000)    (Porta 11434)
```

---

## 2. Variáveis de Controle

A CLI `kryonix brain` se comporta de forma estritamente remota com base nas seguintes variáveis de ambiente:

| Variável | Valor Recomendado | Descrição |
| :--- | :--- | :--- |
| `KRYONIX_ROLE` | `client` | Força o papel de cliente (desativa fallbacks locais silenciosos). |
| `KRYONIX_BRAIN_MODE` | `remote` | Garante que consultas passem pelo endpoint HTTP remoto. |
| `KRYONIX_REMOTE_BRAIN_URL` | `http://127.0.0.1:18000` | URL do endpoint da API remota (porta redirecionada localmente). |
| `KRYONIX_BRAIN_API_KEY` | *(Sua chave)* | Chave de segurança para autenticar requisições protegidas. |
| `KRYONIX_TRACE` | `1` | (Opcional) Define para depuração detalhada e trace de comandos. |

> [!WARNING]
> Com `KRYONIX_ROLE=client` ou `KRYONIX_BRAIN_MODE=remote` ativados, a CLI do Kryonix **proíbe estritamente** o fallback silencioso para o RAG local para preservar a consistência operacional e evitar corrupção de índices.

---

## 3. Configurando o Túnel de Portas SSH

O método preferencial e mais seguro para acessar a API do Glacier de fora da rede local é encapsulando o tráfego em um túnel SSH seguro.

### Criando o Túnel
No **Inspiron**, execute o seguinte comando em background ou em um terminal dedicado:
```bash
ssh -N -L 18000:127.0.0.1:8000 glacier-publico
```

Isso mapeia a porta local `18000` do Inspiron diretamente para a porta remota `8000` (onde a API está ouvindo localmente no Glacier).

---

## 4. Diagnóstico e Validação

Para certificar-se de que a conexão remota está operando corretamente, execute os seguintes passos no cliente:

### 1. Definir as Variáveis
```bash
export KRYONIX_ROLE=client
export KRYONIX_BRAIN_MODE=remote
export KRYONIX_REMOTE_BRAIN_URL="http://127.0.0.1:18000"
export KRYONIX_BRAIN_API_KEY="sua_chave_de_api_aqui"
```

### 2. Smoke Test de Conectividade
```bash
# Consultar endpoint público de saúde
curl -s http://127.0.0.1:18000/health

# Executar busca remota via CLI do Kryonix
kryonix brain search "Como funciona a arquitetura do Glacier?"
```

Se o endpoint remoto estiver protegido e a chave fornecida for inválida ou ausente, a CLI interceptará o retorno de forma robusta e exibirá de forma legível:
```txt
ERRO: endpoint remoto protegido. Defina KRYONIX_BRAIN_API_KEY.
```
