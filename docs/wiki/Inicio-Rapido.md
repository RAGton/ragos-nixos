# Início Rápido

Status: Implementado (guia base)

## Resumo
Guia mínimo para inspecionar o repo e executar validações seguras sem aplicar mudanças no sistema.

## Pré-requisitos
- Git instalado.
- Acesso ao checkout do Kryonix (`/etc/kryonix` no host instalado).

## Passos
1. Clone o repositório (se ainda não existir no host):
   ```sh
   git clone https://github.com/RAGton/kryonix kryonix
   ```
2. Acesse o checkout canônico:
   ```sh
   cd /etc/kryonix
   ```
3. Execute o checklist inicial:
   ```sh
   kryonix git-status
   kryonix doctor
   kryonix check
   kryonix test
   ```

## Quando NÃO usar `switch`/`boot`
- Quando a validação não passou.
- Quando o Glacier estiver offline e você depende de runtime server-side.
- Quando houver mudanças de disco/boot sem plano de rollback.

## Checklist inicial
- [ ] `kryonix git-status` sem pendências inesperadas.
- [ ] `kryonix doctor` sem erros críticos.
- [ ] `kryonix check` sem falhas de flake.
- [ ] `kryonix test` com status coerente para o host.

## Comandos relevantes
```sh
cd /etc/kryonix
kryonix git-status
kryonix doctor
kryonix check
kryonix test
```

## Riscos
- `kryonix switch` e `kryonix boot` são ações destrutivas.
- Não use `disko`, `mkfs` ou `install-system` sem aprovação explícita.

## Links relacionados
- [Operações](Operacoes)
- [Testes e Validação](Testes-e-Validacao)
- [Segurança](Seguranca)
