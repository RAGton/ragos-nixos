# KRYONIX COMMAND CONTRACT

Este documento é a **fonte de verdade canônica** para a operação da CLI Kryonix.
Qualquer comando sugerido ou executado deve seguir rigorosamente estas regras.

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

## 2. Opções Globais

| Opção | Descrição |
| :--- | :--- |
| `--host <host>` | (Obrigatório para operações de host) Define o host alvo. |
| `--flake <path>` | Caminho para o flake (default: `/etc/kryonix`). |
| `--user <user>` | Usuário alvo para comandos `home`. |
| `--json` | Saída em formato JSON puro para integrações. |
| `--verbose` | Aumenta o nível de log (direcionado para stderr). |
| `--dry` | Simulação sem aplicar alterações. |

## 3. Garantia de Operação

1. **Check First**: Sempre execute `kryonix check --host <host>` antes de um switch.
2. **Test Before Switch**: Use `kryonix test --host <host>` para validar o boot e serviços antes de tornar a mudança permanente.
3. **Logs**: Todos os logs operacionais são direcionados para `stderr`. `stdout` é reservado para o resultado final ou JSON.
