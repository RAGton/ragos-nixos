# Framework Leda — Arquitetura e Engenharia de Agentes Autônomos

Status: Fonte de conhecimento para agentes
Fonte: material estruturado para Obsidian sobre arquitetura, dados, orquestração, prompts e integrações de agentes autônomos.

## Objetivo

Registrar o Framework Leda como referência conceitual para desenhar agentes autônomos, fluxos de automação, CRMs com IA, integrações omnichannel e prompts estruturados.

Este documento é fonte de conhecimento. Ele não declara que o Kryonix implementa todos os componentes abaixo.

## Ideia central

Agentes autônomos modernos substituem automações estáticas baseadas em árvores rígidas por sistemas cognitivos capazes de:

- receber eventos externos;
- recuperar estado;
- injetar contexto em LLMs;
- classificar intenção;
- atualizar banco de dados;
- acionar canais de comunicação;
- preservar histórico e auditabilidade.

## Arquitetura macro

```txt
Captação / Evento
  -> Webhook / Trigger
  -> Triagem e filtros
  -> Busca de estado
  -> Roteamento condicional
  -> LLM / Brain
  -> Atualização de estado
  -> Ação final
```

## Camada de captação

Landing pages, formulários, Typebot, Instagram, WhatsApp, e-mail ou sistemas internos podem iniciar o fluxo.

Boas práticas:

- domínio profissional;
- HTTPS/SSL obrigatório;
- rastreamento por pixel/API de conversões quando aplicável;
- CTA claro;
- páginas leves;
- design responsivo;
- prova social e FAQ para reduzir fricção.

## Camada de dados

O banco de dados deixa de ser apenas armazenamento e vira memória operacional do agente.

| Ferramenta | Uso típico | Força principal |
| --- | --- | --- |
| Supabase/PostgreSQL | SaaS, CRM, RAG, autenticação | SQL, RLS, pgvector |
| Airtable | CRM visual, gestão ágil, Custom GPT Actions | API simples e views |
| Baserow | WhatsApp, estado de conversa, low-code self-host | Relacional open-source |
| Google Sheets | Prototipagem, cold email, dumps de scraping | Simplicidade |
| Notion | Laboratório criativo, briefing e colaboração | Metadados ricos e colaboração |

## Supabase, RLS e pgvector

Para aplicações SaaS ou multiusuário, Supabase/PostgreSQL pode combinar:

- tabelas tipadas;
- `uuid` para entidades;
- `user_id` para multi-tenancy;
- `created_at` com timezone;
- colunas de inferência como `ai_insight`, `summary` ou `analysis_content`;
- coluna `status` para gatilhos;
- Row Level Security para isolamento entre usuários;
- `pgvector` para busca semântica.

Exemplo de uso semântico:

```txt
Usuário: procuro uma casa tranquila para trabalhar e com espaço pet.
Sistema: transforma intenção em embedding e busca imóveis semanticamente próximos, mesmo sem match literal por palavras-chave.
```

## Memória de curto prazo em bancos low-code

Em fluxos de WhatsApp ou DM, uma tabela pode armazenar:

```txt
telefone / identificador
nome
status
histórico de chat
última mensagem
score
próxima ação
```

O campo `histórico de chat` atua como memória de curto prazo quando é recuperado e reinjetado no prompt a cada interação.

## Orquestração com Make.com ou n8n

Topologia típica:

```txt
Trigger
  -> Filtros de segurança
  -> Search/Get Record
  -> Router
  -> LLM
  -> Update Record
  -> Send Message / Send Email / Webhook Response
```

### Filtros obrigatórios

- bloquear mensagens enviadas pelo próprio bot;
- validar existência de texto útil;
- ignorar grupos quando o canal for WhatsApp privado;
- impedir loops infinitos;
- tratar mídias não suportadas;
- validar e-mails antes de cold email;
- limitar custo de tokens.

## Engenharia de prompt

Separar prompt em duas camadas:

### System Prompt

Define:

- papel do agente;
- objetivo;
- tom;
- limites;
- formato de saída;
- regras negativas;
- o que fazer em caso de falta de contexto.

### User Prompt

Carrega dados dinâmicos:

```txt
Lead: {{Nome}}
Empresa: {{Empresa}}
Setor: {{Setor}}
Histórico: {{Historico}}
Nova mensagem: {{NovaMensagem}}
```

O User Prompt não deve redefinir as regras principais. Ele injeta payload.

## Saída estruturada

Sempre que o próximo nó precisa tomar decisão, preferir JSON validável.

Exemplo:

```json
{
  "status_qualificacao": "HOT",
  "score_0_a_10": 8,
  "resumo_do_lead": "Busca implementação imediata e possui dor de falta de tempo"
}
```

Isso permite roteamento como:

```txt
se score_0_a_10 > 7
  -> avisar humano
senão
  -> seguir nutrição automática
```

## Few-shot prompting

Para relatórios, mapeamentos e respostas com estilo específico, usar exemplos de entrada e saída.

Objetivo:

- estabilizar formato;
- preservar tom;
- reduzir variação indesejada;
- melhorar consistência em escala.

## Custom GPT Actions e OpenAPI

Custom GPT Actions permitem que uma interface conversacional execute operações CRUD em APIs externas.

Padrão recomendado:

- Personal Access Token com escopos mínimos;
- autenticação Bearer;
- OpenAPI 3.1.0 bem definido;
- paths explícitos;
- schemas com campos obrigatórios;
- sem credenciais em texto visível.

Exemplo conceitual de payload Airtable:

```json
{
  "fields": {
    "Nome": "Roberto",
    "WhatsApp": "11988887777",
    "Email": "robertovendas@dominio.com"
  }
}
```

## Omnicanalidade

Canais comuns:

- WhatsApp via Evolution API;
- Instagram DMs;
- Typebot;
- Gmail/SMTP;
- Webhooks próprios;
- CRMs e bancos low-code.

### WhatsApp / Evolution API

Fluxo típico:

```txt
WhatsApp
  -> Evolution API
  -> Webhook MESSAGES_UPSERT
  -> n8n/Make
  -> busca estado
  -> LLM
  -> atualiza histórico
  -> envia resposta
```

Regras:

- ignorar grupos quando o bot for para atendimento privado;
- bloquear mensagens do próprio bot;
- registrar histórico;
- não expor tokens;
- manter logs auditáveis.

## Verticais práticas

### 1. Cold Email B2B

Fluxo:

```txt
Lista de empresas
  -> scraping/Firecrawl/Apify
  -> Markdown limpo
  -> LLM avalia ICP
  -> score
  -> e-mail personalizado
  -> envio controlado
```

### 2. Imobiliário high-ticket

Uso forte de embeddings e pgvector para buscar intenção semântica, não só palavras-chave.

### 3. Análise contábil/CRM

Uso de Airtable/CRM + modelo RFM:

- Recência;
- Frequência;
- Valor monetário.

O agente sugere reengajamento, upsell ou tarefas.

### 4. Extração documental/OCR

Deve ser tratada com cuidado:

- OCR é caro e frágil;
- documentos legais exigem alta precisão;
- sempre preservar fonte e revisão humana.

## Aplicação no Kryonix

O Framework Leda inspira especialmente:

- memória de agentes;
- orquestração por eventos;
- ingestão controlada;
- respostas com JSON estruturado;
- ações por ferramentas;
- separação entre Brain, banco, eventos e canais;
- observabilidade e auditoria.

Não deve ser misturado diretamente com runtime NixOS sem adaptação. Para o Kryonix, a tradução correta é:

```txt
Eventos/CLI/API
  -> Kryonix Brain
  -> RAG/CAG/GraphRAG
  -> Executor seguro
  -> Logs/auditoria
  -> Resposta fundamentada
```

## Riscos

- loops infinitos;
- vazamento de tokens;
- resposta sem grounding;
- escrita indevida no banco;
- automação sem aprovação humana;
- custo excessivo de tokens;
- prompt injection vindo de conteúdo externo;
- falsa sensação de autonomia.

## Critérios de uso seguro

Antes de transformar uma ideia Leda em implementação Kryonix:

1. definir fonte de verdade;
2. definir estado persistente;
3. definir permissões;
4. definir logs;
5. definir rollback;
6. definir validação;
7. definir o que precisa de aprovação humana.
