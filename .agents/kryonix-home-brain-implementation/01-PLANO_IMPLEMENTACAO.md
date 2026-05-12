# 01 — Plano de Implementação: Kryonix Home Brain

## 1. Objetivo técnico

Implementar o comando:

```bash
kryonix home
```

para organizar, auditar, pesquisar e indexar os arquivos da Home do usuário de forma segura.

A visão final é:

```txt
Home do usuário
  -> scanner Rust
  -> planner determinístico
  -> análise IA local
  -> manifesto auditável
  -> staging/rollback
  -> Brain/RAG/CAG/Neo4j
  -> busca semântica via CLI
```

## 2. Princípios obrigatórios

### Segurança

- Nunca apagar arquivo na Fase 1.
- Nunca mover arquivo sem `--apply`.
- `--dry-run` deve ser o padrão.
- Duplicata só é idêntica com SHA256 igual.
- Arquivo parecido não é duplicata segura.
- Toda ação futura deve gerar manifesto.
- Toda ação futura deve ter rollback.
- Pastas ocultas e de configuração devem ser ignoradas.

### Auditabilidade

Cada execução deve ter:

```txt
run_id
timestamp
host
user
root escaneado
arquivos encontrados
arquivos ignorados
ações propostas
hashes
riscos
motivos
```

### Declaratividade

O serviço persistente deve nascer depois via módulo NixOS/Home Manager.

Primeiro implementar CLI manual.

## 3. Fases

## Fase 1 — Scanner determinístico seguro

### Objetivo

Mapear arquivos sem alterar nada.

### Comandos

```bash
kryonix home scan
kryonix home report
kryonix home duplicates
kryonix home plan --dry-run
```

### Recursos

- percorrer diretórios permitidos;
- ignorar pastas ocultas;
- ignorar config/cache/secrets;
- detectar extensão;
- detectar MIME quando possível;
- calcular tamanho;
- calcular SHA256 opcional ou incremental;
- detectar duplicatas exatas;
- gerar relatório;
- gerar plano determinístico.

### Não fazer

- não chamar LLM;
- não mover arquivos;
- não renomear arquivos;
- não apagar arquivos;
- não indexar no Brain ainda.

## Fase 2 — Manifesto, staging e rollback

### Objetivo

Preparar execução segura.

### Recursos

- gerar `manifest.json`;
- gerar `rollback.json`;
- mover para staging antes de destino final;
- permitir `kryonix home rollback <run-id>`;
- permitir quarentena de duplicatas idênticas.

### Diretórios

```txt
~/Arquivos/Kryonix-Staging/<run-id>/
~/Arquivos/Quarentena/<run-id>/
~/.local/state/kryonix/home-brain/
```

## Fase 3 — IA local para classificação e nome

### Objetivo

Usar Ollama/Brain para sugerir:

- categoria;
- título curto;
- descrição;
- tags;
- nome normalizado;
- pasta destino;
- risco;
- confiança.

### Política

A IA apenas sugere. O executor Rust valida.

## Fase 4 — RAG/CAG

### Objetivo

Transformar arquivos em conhecimento consultável.

### Recursos

- extrair texto;
- gerar chunks;
- embeddings;
- resumo curto para CAG;
- busca semântica.

### Comando

```bash
kryonix home learn
```

## Fase 5 — Neo4j/GraphRAG

### Objetivo

Criar relações estruturais:

```cypher
(:File)-[:BELONGS_TO]->(:Category)
(:File)-[:HAS_TAG]->(:Tag)
(:File)-[:MENTIONS]->(:Entity)
(:File)-[:DUPLICATE_OF]->(:File)
(:File)-[:MOVED_BY]->(:Action)
(:File)-[:RELATED_TO]->(:Project)
```

## Fase 6 — Daemon declarativo

### Objetivo

Criar serviço systemd user:

```txt
kryonix-home-daemon.service
kryonix-home-scan.timer
kryonix-home-index.timer
```

## 4. Diretórios permitidos por padrão

```txt
~/Downloads
~/Documentos
~/Imagens
~/Vídeos
~/Músicas
~/Área de Trabalho
~/Desktop
~/Pictures
~/Videos
~/Music
```

## 5. Diretórios proibidos por padrão

```txt
~/.*
~/.config
~/.local
~/.cache
~/.ssh
~/.gnupg
~/.mozilla
~/.thunderbird
~/.var
~/.nix-profile
qualquer diretório contendo .git
qualquer diretório contendo flake.nix
qualquer diretório contendo Cargo.toml
qualquer diretório contendo pyproject.toml
```

## 6. Categorias iniciais

```txt
Documentos/Academico
Documentos/Pessoal
Documentos/Trabalho
Documentos/Financeiro
Documentos/Juridico
Documentos/Tecnico
Documentos/Kryonix

Midia/Imagens/Fotos
Midia/Imagens/Screenshots
Midia/Imagens/Wallpapers
Midia/Videos
Midia/Audio
Midia/Musicas

Arquivos/Compactados
Arquivos/ISOs
Arquivos/Executaveis
Arquivos/Revisar
Arquivos/Duplicatas
Arquivos/Quarentena

Projetos/Rust
Projetos/Python
Projetos/NixOS
Projetos/IA
Projetos/Kryonix
```

## 7. Padrão de nome

Nome:

```txt
AAAA-MM-DD__ORIGEM__TITULO-CURTO__TIPO__v01.ext
```

Exemplo:

```txt
2026-05-08__Kryonix__Plano-Home-Brain__Nota-Tecnica__v01.md
2026-04-30__Banco-Inter__Comprovante-Pagamento-Internet__Comprovante__v01.pdf
```

## 8. Riscos

| Risco | Mitigação |
|---|---|
| Apagar arquivo errado | Não deletar automaticamente |
| Mover projeto/código | Ignorar `.git`, `flake.nix`, `Cargo.toml`, `pyproject.toml` |
| Vazamento de segredo | Ignorar `.env`, chaves, `.ssh`, config |
| IA alucinar categoria | IA sugere, Rust valida |
| Renomear arquivo importante errado | Manifesto + rollback |
| Quebrar workflow do usuário | Dry-run obrigatório |

## 9. Resultado esperado da Fase 1

```bash
kryonix home scan
```

Saída exemplo:

```txt
Kryonix Home Scan

Root: /home/rocha
Arquivos analisados: 842
Arquivos ignorados: 1293
Tamanho total: 34.7 GiB

Tipos:
  PDF: 83
  Imagens: 421
  Vídeos: 38
  Áudio: 12
  Compactados: 51
  Desconhecidos: 19

Duplicatas exatas:
  7 grupos

Nenhuma alteração foi feita.
```
