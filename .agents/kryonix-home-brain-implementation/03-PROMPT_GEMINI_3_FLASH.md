# 03 — Prompt para Gemini 3 Flash / Antigravity

Use este prompt inteiro.

```txt
Você está em /etc/kryonix no projeto Kryonix.

Tarefa: implementar a Fase 1 do módulo Kryonix Home Brain.

Objetivo:
Criar uma CLI segura chamada `kryonix home` para escanear, relatar, detectar duplicatas e gerar plano dry-run de organização de arquivos pessoais da Home.

Contexto:
O Kryonix é uma plataforma NixOS declarativa.
O projeto deve priorizar Rust para core/CLI/daemon e NixOS para configuração declarativa.
O objetivo futuro é integrar com Kryonix Brain, RAG, CAG, Ollama e Neo4j, mas nesta tarefa a Fase 1 deve ser 100% determinística, sem LLM e sem mutações.

Antes de modificar qualquer arquivo, leia:
- README.md
- flake.nix
- AGENTS.md, se existir
- .ai/PROJECT_CONTEXT.md, se existir
- .ai/PROJECT_MEMORY_CURRENT.md, se existir
- packages/
- modules/
- hosts/
- home/

Regras obrigatórias:
1. Não apagar nenhum arquivo.
2. Não mover nenhum arquivo.
3. Não renomear nenhum arquivo.
4. Não chamar LLM.
5. Não usar Ollama ainda.
6. Não indexar no Brain ainda.
7. Não escrever no Neo4j ainda.
8. Não mexer em pastas ocultas.
9. Não mexer em ~/.config, ~/.local, ~/.cache, ~/.ssh, ~/.gnupg, ~/.mozilla, ~/.var.
10. Não mexer em repositórios Git.
11. Ignorar qualquer diretório que contenha `.git`.
12. Ignorar qualquer diretório que contenha `flake.nix`, `Cargo.toml` ou `pyproject.toml`.
13. Não ler nem imprimir secrets.
14. Não ler nem commitar `.env`, `brain.env`, `neo4j.env`, tokens ou chaves SSH.
15. Toda saída deve deixar claro que nenhuma alteração foi feita.
16. `plan` deve ser dry-run por padrão.
17. Duplicata exata só pode ser marcada quando SHA256 for igual.
18. Arquivos parecidos não devem ser marcados como duplicata exata.
19. Não rodar `nixos-rebuild switch`.
20. Não alterar `flake.lock` sem necessidade explícita.
21. Fazer commit pequeno e focado.

Implementar comandos:

- `kryonix home scan`
- `kryonix home report`
- `kryonix home duplicates`
- `kryonix home plan --dry-run`
- `kryonix home plan --json`

Comportamento esperado:

## `kryonix home scan`

Escanear diretórios permitidos da Home:
- Downloads
- Documentos
- Imagens
- Vídeos
- Músicas
- Área de Trabalho
- Desktop
- Pictures
- Videos
- Music

Coletar:
- path
- filename
- extension
- MIME aproximado
- size
- modified_at
- created_at, se disponível
- SHA256, se seguro/viável
- status: analyzed/ignored/error

Salvar resultado em:
`~/.local/state/kryonix/home-brain/latest-scan.json`

Também salvar por run:
`~/.local/state/kryonix/home-brain/runs/<run-id>/scan.json`

## `kryonix home report`

Ler o último scan e mostrar:
- total de arquivos
- total por categoria
- tamanho total
- extensões mais comuns
- maiores arquivos
- arquivos ignorados
- possíveis duplicatas exatas
- sugestões gerais

## `kryonix home duplicates`

Listar grupos com SHA256 igual.

Não deletar.
Não mover.
Não criar quarentena ainda.

## `kryonix home plan --dry-run`

Gerar plano de organização por regra determinística:

- PDF/documentos -> Documentos/Revisar
- imagens -> Midia/Imagens
- vídeos -> Midia/Videos
- áudio/música -> Midia/Audio
- compactados -> Arquivos/Compactados
- ISO/img -> Arquivos/ISOs
- executáveis -> Arquivos/Executaveis
- desconhecidos -> Arquivos/Revisar

O plano deve conter:
- ação sugerida
- path atual
- path sugerido
- motivo
- risco
- confiança
- se depende de revisão manual

Não mover nada.

## `kryonix home plan --json`

Emitir JSON válido.

Estrutura Rust sugerida:
packages/kryonix-home/
  Cargo.toml
  src/
    main.rs
    cli.rs
    scanner.rs
    ignore.rs
    metadata.rs
    hashing.rs
    planner.rs
    report.rs
    audit.rs
    error.rs

Crates sugeridos:
- clap
- serde
- serde_json
- walkdir
- anyhow
- thiserror
- sha2
- hex
- mime_guess
- chrono
- dirs

Integração:
Se o projeto já possui uma CLI `kryonix` baseada em shell, integrar o subcomando `home` chamando o binário Rust.
Não quebrar comandos existentes.

Validações obrigatórias:
cd /etc/kryonix

git status --short
nix fmt . || true
git diff --check
cargo fmt --all || true
cargo clippy --all-targets --all-features || true
cargo test --all || true
nix build .#kryonix --no-link

nix run .#kryonix -- home scan
nix run .#kryonix -- home report
nix run .#kryonix -- home duplicates
nix run .#kryonix -- home plan --dry-run
nix run .#kryonix -- home plan --json

Critério de conclusão:
- build passa
- comandos funcionam
- nenhuma mutação real ocorre
- saída informa claramente modo seguro
- pastas proibidas são ignoradas
- secrets não aparecem
- duplicatas só são por hash idêntico
- commit pequeno

Commit sugerido:
feat(home): add safe file scanning and organization planning
```
