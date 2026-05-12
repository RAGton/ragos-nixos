# AI Skill

## Escopo

Guia para agentes que forem atuar neste repositório em tarefas de documentação, refactor e organização arquitetural.

## Quando usar

- síntese de documentação
- atualização de roadmap
- consolidação de arquitetura atual
- limpeza de resíduos de migração
- ajustes de energia/idle
- melhorias específicas do host `glacier`

## Objetivos

1. refletir o estado real do código
2. reduzir contradições documentais
3. preparar refactors seguros e incrementais
4. manter notebook sem lock/suspend automático indesejado
5. tratar `glacier` como host principal para virtualização e gaming

## Método

### Diagnóstico

- verificar primeiro o código
- tratar docs antigas como históricas quando divergirem do código
- registrar gaps reais e não problemas já resolvidos

### Execução

- preferir mudanças pequenas e coesas
- documentar antes e depois quando a mudança altera arquitetura
- usar overrides por host/usuário para comportamentos específicos

### Focos técnicos

- desktop = `rag.desktop.environment`
- rice = `rag.rice.*`
- feature = `rag.features.*`
- DMS não é desktop separado
- Hyprland é o desktop real atual

## Entregáveis úteis

- `docs/CURRENT_STATE.md`
- `docs/ROADMAP.md`
- prompt pronto para coding agent
- commits curtos e objetivos
