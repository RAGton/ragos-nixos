# CAG / Context Cache do Kryonix Brain

Status: Roadmap / Arquitetura proposta

## Definição

CAG/cache não substitui RAG. Ele armazena contexto estável e frequente para reduzir latência e repetição.

## Contextos bons para CAG

```txt
arquitetura do projeto
mapa de hosts
serviços conhecidos
comandos de validação
políticas de segurança
estrutura do flake
índice de módulos NixOS
```

## Chave de cache

```txt
normalized_query
retrieval_profile
model_name
embedding_model
index_version
repo_commit
vault_snapshot_hash
top_k
schema_version
chunking_version
```

## Invalidação

Invalidar quando mudar:

```txt
git commit
flake.lock
arquivos indexados
hash do vault
modelo de embedding
schema Neo4j
config de chunking
perfil de retrieval
```

## Diretórios

```txt
/var/lib/kryonix/brain/cag/context-cache
/var/lib/kryonix/brain/cag/prompt-cache
/var/lib/kryonix/brain/cag/invalidation
```
