# Embeddings vs Grafos no Kryonix Brain

Status: Referência arquitetural
Fonte: aula/consolidação sobre por que grafos complementam embeddings vetoriais em memória de agentes.

## Ideia central

```txt
Embeddings encontram coisas semanticamente parecidas.
Grafos explicam como essas coisas estão conectadas.
```

Para memória de longo prazo de agentes, embedding puro não basta.

## O que embeddings fazem bem

Embeddings são fortes para busca semântica.

Exemplo:

```txt
consulta: cliente financeiro de alto risco
```

Uma busca vetorial pode encontrar um texto como:

```txt
cliente com score de risco elevado e revisão de conformidade pendente
```

Mesmo sem as mesmas palavras, a similaridade semântica aproxima os conceitos.

Embeddings são bons para:

- similaridade;
- busca aproximada;
- perguntas vagas;
- recuperação semântica;
- RAG por significado.

## Limitações de embedding puro

Embedding puro costuma tratar cada item como um ponto isolado no espaço vetorial.

Ele não representa nativamente:

- relações explícitas;
- travessia multi-hop;
- causalidade;
- validade temporal;
- proveniência;
- estrutura entre entidades.

Exemplo de pergunta ruim para vetor puro:

```txt
Mostre o cliente, todas as contas dele, as transações de cada conta,
a organização onde ele trabalha e flags de compliance dessa organização.
```

Com banco vetorial puro, a aplicação teria que fazer buscas separadas e juntar tudo manualmente.

## Por que grafo ajuda

No Neo4j, relações viram primeira classe.

Exemplo conceitual:

```cypher
MATCH (c:EntityPerson {name: "Jessica Norris"})
  -[:OWNS]->(a:EntityObject)
  -[:HAS_TRANSACTION]->(t:EntityEvent)
WITH c, a, collect(t) AS transactions
MATCH (c)-[:WORKS_AT]->(org:EntityOrganization)
  -[:HAS_FLAG]->(flag:EntityObject {type: "compliance"})
RETURN c.name, a.name, transactions, org.name, flag.description
```

O grafo permite responder em uma travessia:

```txt
cliente -> conta -> transações
cliente -> organização -> flag de compliance
```

## Validade temporal

Relações podem carregar propriedades temporais.

Pergunta:

```txt
Quem era o proprietário desta conta no terceiro trimestre de 2025?
```

Exemplo:

```cypher
MATCH (person:EntityPerson)-[r:OWNS]->(account:EntityObject {id: $account_id})
WHERE r.valid_from <= date("2025-09-30")
  AND (r.valid_to IS NULL OR r.valid_to >= date("2025-07-01"))
RETURN person.name, r.valid_from, r.valid_to
```

Isso permite raciocínio temporal mais robusto do que metadata solta em chunks.

## Melhor arquitetura

Não é vetor contra grafo.

É:

```txt
vector search + graph traversal
```

Fluxo recomendado:

```txt
pergunta
  -> embedding da pergunta
  -> busca vetorial encontra entidades/chunks candidatos
  -> grafo expande relações relevantes
  -> resposta usa contexto com proveniência
```

## Aplicação no Kryonix

Embedding puro responde melhor perguntas como:

```txt
ache coisas parecidas com erro no Ollama
```

Grafo responde melhor perguntas como:

```txt
qual host roda Ollama?
qual serviço depende dele?
qual porta ele usa?
qual arquivo declara esse serviço?
qual comando valida?
qual issue anterior envolveu isso?
qual correção funcionou?
```

Exemplo de subgrafo Kryonix:

```txt
(:Host {name: "glacier"})-[:RUNS]->(:Service {name: "ollama"})
(:Service {name: "ollama"})-[:LISTENS_ON]->(:Port {number: 11434})
(:File {path: "hosts/glacier/services/ollama.nix"})-[:DECLARES]->(:Service {name: "ollama"})
(:Command {command: "systemctl status ollama"})-[:VALIDATES]->(:Service {name: "ollama"})
(:Issue {title: "Ollama não responde"})-[:AFFECTS]->(:Service {name: "ollama"})
```

Com isso, uma pergunta como:

```txt
Por que o Brain não conecta no Ollama?
```

pode recuperar:

- serviço `ollama`;
- serviço `kryonix-brain`;
- host `glacier`;
- porta `11434`;
- arquivo Nix declarativo;
- dependências systemd;
- comandos de diagnóstico;
- incidentes anteriores.

## Regras de segurança

Text2Cypher gerado por LLM deve ser read-only por padrão.

Bloquear:

```txt
CREATE
MERGE
DELETE
DETACH DELETE
SET
REMOVE
CALL dbms.*
CALL apoc.*
LOAD CSV
```

Permitir inicialmente:

```txt
MATCH
OPTIONAL MATCH
WHERE
RETURN
WITH
ORDER BY
LIMIT
```

Exigir:

- `LIMIT` obrigatório;
- timeout;
- usuário read-only;
- logs de auditoria;
- proveniência de documentos, chunks e entidades.

## Relação com outros documentos

- `docs/brain/GRAPH_RAG_ARCHITECTURE.md`
- `docs/brain/NEO4J_SCHEMA.md`
- `docs/brain/lightrag.md`
- `docs/brain/README.md`
