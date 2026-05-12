# Kryonix License Audit

## Objetivo

Auditar a transição do ecossistema Kryonix para a licença **Source Available / Proprietária** e garantir que as fronteiras com softwares de terceiros e licenças de software livre (MIT, Apache, etc.) foram respeitadas e preservadas.

## Escopo auditado

- Repositório raiz: `LICENSE`, `README.md`, `README-en.md`, `flake.nix`.
- Submódulos autorais: `packages/kryonix-home`, `packages/kryonix-brain-lightrag`, `.ai/kryonix-vault`.
- Pacotes Nix: `packages/*.nix`.
- Políticas de governança: `docs/development/LICENSING_POLICY.md`.

## Arquivos de licença encontrados

- `/LICENSE` (Raiz)
- `/.ai/kryonix-vault/LICENSE`
- `/packages/kryonix-home/LICENSE`
- `/packages/kryonix-brain-lightrag/LICENSE`

## Repositório raiz

O repositório principal foi atualizado para a **Kryonix Proprietary Source-Available License**. Menções à licença anterior (MIT) foram removidas ou classificadas como históricas.

## Submódulos próprios

- **kryonix-home**: 100% autoral (Rust), distribuído sob licença proprietária.
- **kryonix-brain-lightrag**: Wrapper orquestrador em Python. Utiliza a biblioteca `lightrag` como dependência externa, mas o código de integração e lógica de negócio é autoral e proprietário.
- **.ai/kryonix-vault**: Base de conhecimento técnica protegida pela licença proprietária.

## Componentes de terceiros preservados

Os seguintes componentes mantêm suas licenças originais e não foram afetados pela mudança:

- **NixOS / nixpkgs**: MIT.
- **Home Manager**: MIT.
- **LightRAG Core**: MIT.
- **Ollama**: Apache 2.0.
- **Neo4j**: GPLv3 / Comercial.
- **Dependências (Crates/Python packages)**: Mantidas via gerenciadores de pacotes (`cargo`, `uv`).

## Ocorrências restantes de MIT/Open Source

As ocorrências de "MIT" ou "Open Source" no repositório agora se limitam a:
1.  Isenções de responsabilidade (disclaimers) padrão dentro do novo texto de licença.
2.  Referências em documentação técnica ao ecossistema Open Source onde o Kryonix se insere.
3.  Documentação histórica sobre o período em que o projeto era MIT.

## Metadados Nix

Todos os pacotes definidos em `packages/*.nix` foram atualizados para incluir:
```nix
meta.license = lib.licenses.unfree;
```
Isso garante que o ecossistema Nix reconheça o status proprietário e exija `NIXPKGS_ALLOW_UNFREE=1` para avaliação/build.

## Riscos

- **Risco**: Relicenciamento acidental de código derivado de terceiros.
- **Mitigação**: O submódulo `kryonix-brain-lightrag` foi auditado e não contém código fonte do upstream, apenas chamadas de API e wrappers.

## Validações executadas

- [x] `nix build .#kryonix`
- [x] `nix flake check --keep-going`
- [x] `doc-audit.sh` (integridade de documentação)
- [x] `git diff --check`
- [x] Audit de strings via `rg` e `find`.

## Conclusão

A auditoria confirma que a transição foi realizada de forma limpa e legalmente coerente. O IP da Kryonix está protegido, enquanto os créditos e licenças de software livre de terceiros permanecem intactos.

---
*Relatório gerado em 12/05/2026 pelo Antigravity AI Agent.*
