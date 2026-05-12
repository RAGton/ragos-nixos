# Relatório de Auditoria de Licenciamento — Kryonix

**Data:** 12 de Maio de 2026
**Status:** ✅ APROVADO
**Versão Alvo:** v0.4.2

## 1. Resumo da Transição

O projeto Kryonix migrou formalmente de **MIT** para **Source Available / Proprietário**. Esta auditoria valida que a transição foi executada respeitando as fronteiras de terceiros e a integridade legal.

## 2. Arquivos de Licença Auditados

| Arquivo | Estado | Observação |
| :--- | :--- | :--- |
| `LICENSE` (raiz) | ✅ Atualizado | Source Available / Todos os direitos reservados |
| `README.md` | ✅ Atualizado | Seção "Licença" reflete o novo status |
| `README-en.md` | ✅ Atualizado | Seção "License" reflete o novo status |
| `docs/development/LICENSING_POLICY.md` | ✅ Criado | Define as regras de escopo e contribuição |

## 3. Submódulos e Pacotes Autorais

Todos os pacotes criados especificamente para o ecossistema Kryonix foram auditados:

- **kryonix-home**: `license-file = "LICENSE"` no `Cargo.toml` + LICENSE própria (Source Available).
- **kryonix-brain-lightrag**: LICENSE própria (Source Available).
- **Metadados Nix**: Todos os pacotes em `packages/*.nix` agora utilizam `license = lib.licenses.unfree`.

## 4. Fronteiras de Terceiros (Preservados)

Os seguintes componentes foram verificados para garantir que suas licenças originais **NÃO** foram alteradas:

- **NixOS / nixpkgs**: Mantido como `lib.licenses.mit` (upstream).
- **Home Manager**: Mantido como `lib.licenses.mit` (upstream).
- **LightRAG Core**: O wrapper Kryonix é proprietário, mas as dependências externas e o motor base permanecem sob suas licenças originais (MIT/Apache 2.0).
- **Ollama / Neo4j**: Integrados como serviços, sem alteração de licenciamento.

## 5. Histórico MIT

Ficou explicitamente documentado no `README.md` e na `LICENSING_POLICY.md` que versões antigas publicadas sob MIT continuam regidas por tais termos para aqueles commits específicos. A mudança é válida apenas para o desenvolvimento futuro do projeto.

## 6. Conclusão

A auditoria confirma que o Kryonix agora possui uma estrutura legal sólida para proteção de IP, sem violar as licenças de software livre das quais depende.

---
*Assinado: Antigravity AI Agent (Kryonix Governance)*
