# KRYONIX COMMAND CONTRACT

Este documento é a **fonte de verdade canônica** para a operação da CLI Kryonix.
Qualquer comando sugerido ou executado deve seguir rigorosamente estas regras. O comportamento real da CLI é definido no `registry.sh` e exposto via `kryonix commands`.

## 1. Sintaxe Fundamental

O comando `kryonix` é um wrapper declarativo. Ele **NÃO** deve ser usado com referências diretas de flake (sintaxe `.#`).

### ✅ Permitido (Canônico)
Sempre use a flag `--host` para especificar o alvo da configuração.

```bash
kryonix <comando> --host <hostname>
```

**Exemplos Válidos:**
- `kryonix check --host glacier`
- `kryonix test --host glacier`
- `kryonix build --host glacier`
- `kryonix switch --host glacier`
- `kryonix home --host glacier`
- `kryonix diff --host glacier`

### ❌ Proibido (Bloqueado)
Estas sintaxes são consideradas inseguras, misturam camadas de abstração ou são redundantes.

| Comando Proibido | Motivo |
| :--- | :--- |
| `kryonix switch .#glacier` | Sintaxe de flake ref (`.#`) é bloqueada no wrapper. |
| `sudo kryonix switch ...` | O wrapper gerencia o escalonamento de privilégios internamente. |
| `nh os switch .#glacier` | Comando de baixo nível. Use o wrapper `kryonix`. |
| `nixos-rebuild switch ...` | Comando manual não-declarativo. Use `kryonix`. |

## 4. Registry v2 e Grounding (Brain)

A CLI Kryonix expõe seus metadados operacionais via `kryonix commands --json`. Este contrato (v2) é a fonte de verdade para o Knowledge Graph do Brain.

### Metadados por Comando
- **Risk Level**: `low`, `medium`, `high`, `critical`.
- **Requires Host**: `any`, `glacier`, `inspiron`.
- **Requires Runtime**: Array de dependências (ex: `ollama`, `neo4j`).
- **Category**: Agrupamento lógico (ex: `ai`, `system`, `git`).
- **Examples**: Lista de exemplos de uso prático.

### Ingestão no Grafo
A ingestão deve ocorrer exclusivamente no host **Glacier** para garantir a integridade dos artefatos:

```bash
kryonix graph ingest-registry --dry-run
kryonix graph ingest-registry --apply <manifest_id>
```

## 5. Garantia de Operação

1. **Check First**: Sempre execute `kryonix check --host <host>` antes de um switch.
2. **Test Before Switch**: Use `kryonix test --host <host>` para validar o boot e serviços antes de tornar a mudança permanente.
3. **Graph Sync**: Após alterações significativas na CLI ou configuração de serviços, sincronize o Registry com o Knowledge Graph via `kryonix graph ingest-registry`.
4. **Logs**: Todos os logs operacionais são direcionados para `stderr`. `stdout` é reservado para o resultado final ou JSON.
