# Governança Vibecode

Este documento define os limites e as obrigações para o uso de "vibecode" (desenvolvimento rápido guiado por IA) no repositório Kryonix.

## O que é Vibecode?
Vibecode é o processo de permitir que agentes de IA tomem decisões de implementação rápidas baseadas em contexto e "vibe" do projeto, visando velocidade.

## Regras de Governança

### 1. Vibecode é Permitido
Agentes podem e devem usar sua capacidade criativa e técnica para implementar soluções rapidamente, desde que respeitem os guardrails do projeto.

### 2. Merge sem Evidência é Proibido
Nenhuma alteração, por mais trivial que pareça, pode ser considerada "pronta" ou sofrer merge sem que haja evidência real de funcionamento (logs de teste, screenshots, builds bem-sucedidos).

### 3. Implementação vs. Estado
- Agentes podem acelerar a **implementação**.
- Agentes **não podem inventar** estados, funcionalidades prontas ou documentação de features inexistentes.

### 4. Concordância entre Docs e Runtime
Documentação técnica e comportamento em tempo real devem estar em sincronia. Se o runtime mudar, a doc deve ser atualizada imediatamente.

### 5. Requisitos de Saída
Todo output gerado via vibecode que resulte em alterações permanentes deve incluir:
- **Plano:** O que foi feito.
- **Diff:** As mudanças exatas.
- **Teste:** Como foi validado.
- **Risco:** O que pode dar errado.
- **Rollback:** Como voltar atrás.

## Conclusão
O vibecode no Kryonix é uma ferramenta de produtividade, não uma desculpa para falta de rigor técnico. A engenharia controlada, testável e governada é o objetivo final.
