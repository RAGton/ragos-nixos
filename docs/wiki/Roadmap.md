# Roadmap

Status: Roadmap

## Resumo
Este documento consolida o que ainda não está plenamente implementado ou validado. Não trate itens abaixo como prontos.

## Fonte canônica
Este resumo reflete o conteúdo de `docs/ROADMAP.md`. Para detalhes completos e status oficial, consulte o documento canônico no repositório.

## Resumo de alto nível (intencionalmente curto)
- **Brain API / MCP remoto:** Parcial, com validações pendentes.
- **Glacier autônomo (server IA):** Parcial.
- **ISO instalável:** Parcial.
- **Automação avançada (web research, geração de pacotes, autocuradoria):** Não implementado.

## Milestones detalhados
Consulte `docs/ROADMAP.md` para versões, critérios e evidências atualizadas.

## Quando usar
Para alinhar expectativas antes de prometer funcionalidades.

## Comandos relevantes
```sh
systemctl status kryonix-brain-api.service --no-pager
curl -fsS http://127.0.0.1:8000/health
kryonix mcp doctor
```

## Riscos
- Prometer features não implementadas.
- Tratar itens de roadmap como entregues.

## Links relacionados
- [Arquitetura](Arquitetura)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [Testes e Validação](Testes-e-Validacao)
