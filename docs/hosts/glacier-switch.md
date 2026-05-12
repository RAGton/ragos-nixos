# Guia de Operação: Glacier Switch

Este documento descreve o procedimento canônico para aplicar mudanças de configuração no host **Glacier**.

## 🛑 Regra de Ouro

**Nunca use `nh os switch`, `nixos-rebuild switch` ou a sintaxe `.#host` diretamente.**

Use sempre o comando unificado `kryonix` com a flag `--host`. Isso garante que:
1. O repositório em `/etc/kryonix` seja a fonte de verdade.
2. Os logs de ativação sejam indexados pelo Brain.
3. O mapeamento de hostname (`glacier`) seja respeitado.
4. **Sintaxes proibidas** como `kryonix switch .#glacier` sejam bloqueadas para evitar inconsistências.

| Operação | Comando Correto | Comando Proibido |
| :--- | :--- | :--- |
| Switch | `kryonix switch --host glacier` | `kryonix switch .#glacier` |
| Build | `kryonix rebuild --host glacier` | `kryonix build .#glacier` |
| Test | `kryonix test --host glacier` | `sudo kryonix test` |

## 🛠️ Procedimento Canônico

### 1. Diagnóstico e Preparação
Certifique-se de que o repositório está limpo e sincronizado antes de qualquer alteração:
```bash
cd /etc/kryonix
git status --short
git submodule status --recursive
```

### 2. Validação (Build)
Sempre valide a configuração antes de aplicar para evitar downtime no servidor de IA:
```bash
kryonix rebuild --host glacier
```
Se este comando falhar, **não prossiga**. Corrija os erros de Nix primeiro.

### 3. Aplicação (Switch)
Se o build passou, aplique a configuração:
```bash
kryonix switch --host glacier
```

### 4. Verificação de Saúde
Após o switch, verifique se os serviços críticos (Ollama, Brain API) subiram corretamente:
```bash
kryonix brain doctor --remote
```

## 🚑 Rollback e Emergência

Se o Glacier ficar inacessível via rede:
1. Acesse via console físico ou IPMI (se disponível).
2. Use as gerações do Grub/Systemd-boot para dar boot na configuração anterior.
3. Se o SSH estiver quebrado mas o sistema estiver vivo, use o IP de fallback ou Tailscale.

---

> [!IMPORTANT]
> O Glacier é o coração da infraestrutura de IA. Mudanças no `hardware-configuration.nix` ou `nvidia.nix` devem ser testadas com cautela redobrada.
