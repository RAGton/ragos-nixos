# Skill: Obsidian Memory

## Objetivo

Documentar e operar a camada de memória local do usuário sem confundir app desktop, CLI e Headless Sync.

## Quando usar

- notas locais
- operação de vault
- integração entre repositório e conhecimento externo do usuário
- documentação de fluxo para agentes

## Entradas

- vault alvo ou ausência de confirmação
- superfície desejada: desktop, CLI ou headless
- objetivo operacional

## Passos

1. confirmar qual superfície está em jogo
2. não assumir vault ou path sem evidência
3. usar referências oficiais do Obsidian para CLI/URI/Headless
4. separar conhecimento do usuário do conteúdo do repositório
5. registrar runbook curto se o fluxo for recorrente

## Comandos de validação

```bash
obsidian://choose-vault
obsidian read path="<arquivo>"
ob sync-status --path <vault>
```

## Critérios de saída

- distinção clara entre desktop, CLI e headless
- nenhum path inventado
- fluxo reproduzível documentado

## Riscos

- tratar vault pessoal como se fosse arquivo do repo
- afirmar suporte headless sem instalação correspondente
