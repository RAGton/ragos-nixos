# Filosofia do Kryonix

Status: Implementado (princípios operacionais)

## Resumo
Kryonix prioriza segurança, rastreabilidade e verdade operacional. A documentação nunca deve prometer o que o código não entrega.

## Princípios
1. **Repo como fonte de verdade:** o código real vence documentação histórica.
2. **Sistema declarativo:** mudanças pequenas, auditáveis e reversíveis.
3. **Segurança antes de automação:** validar antes de aplicar.
4. **IA com grounding real:** sem alucinação; use fontes do repo.
5. **Documentação honesta:** implementado ≠ roadmap.
6. **Separação de papéis:** Glacier é servidor; Inspiron é cliente.
7. **Validação obrigatória:** se não foi testado, não está pronto.

## Quando usar
Quando precisar justificar decisões técnicas ou revisar mudanças de alto impacto.

## Comandos relevantes
```sh
kryonix doctor
kryonix check
kryonix test
nix flake show --all-systems
```

## Riscos
- Pular validações gera drift e falhas silenciosas.
- Misturar responsabilidades de cliente/servidor quebra a arquitetura.

## Links relacionados
- [Visão Geral](Visao-Geral)
- [Arquitetura](Arquitetura)
- [Testes e Validação](Testes-e-Validacao)
