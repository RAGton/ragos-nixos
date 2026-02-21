# 🚀 GUIA DE TESTES - Solução Sessão Wayland

## ✅ Passos para Validar a Solução

### 1. **Reconstruir o Sistema**

```bash
cd /home/rocha/GitHub/dotfiles-NixOs
nixos-rebuild switch --flake .#inspiron
```

> Leva ~5-10 minutos. O módulo PAM será recompilado.

---

### 2. **Fazer Reboot**

```bash
sudo reboot
```

---

### 3. **No Prompt de Login (greetd + tuigreet)**

- Digite seu **usuário** (ex: `rag` ou `rocha`)
- Digite sua **senha**
- Pressione ENTER

**NOVO COMPORTAMENTO ESPERADO**:

- Hiprland/DMS deve **iniciar automaticamente** ✅
- Compositor gráfico Wayland deve aparecer
- DMS shell deve ser visível

---

### 4. **Validar Sessão logind**

```bash
# Em outro terminal (ou após abrir um terminal no DMS)
loginctl session-status

# ESPERADO:
Session c1
     Type: wayland       ← CORRETO ✅ (antes: "tty")
    Class: user         ← CORRETO ✅ (antes: "manager")
    State: active
    Seat: seat0         ← CORRETO ✅ (antes: vazio)
```

---

### 5. **Verificar Variáveis de Ambiente**

```bash
# Ver que a sessão Wayland está correta
env | grep -E "XDG_SESSION|WAYLAND"

# ESPERADO:
XDG_SESSION_ID=c1
XDG_SESSION_TYPE=wayland  ← CRÍTICO ✅
XDG_SESSION_CLASS=user    ← CRÍTICO ✅
XDG_SEAT=seat0            ← CRÍTICO ✅
WAYLAND_DISPLAY=...
```

---

### 6. **Testar Hyprland**

```bash
# Dentro da sessão gráfica:
# - Mover mouse/teclado
# - Testar atalhos (ex: Super+D)
# - Abrir aplicativos (Ex: Super+T para terminal)

# Se tudo funciona → SOLUÇÃO VALIDADA ✅
```

---

## 🔴 Se Algo Não Funcionar

### Cenário A: Ainda recebe sessão "manager"

```bash
# Verificar se PAM foi recompilado
cat /etc/pam.d/greetd | grep pam_systemd

# Esperado: deve conter "class=user type=wayland"
# Se não está lá → reconstruir novamente com:
sudo nixos-rebuild switch --flake .#inspiron
```

### Cenário B: Hyprland falha ao iniciar

```bash
# Ver logs
journalctl -u greetd -n 50

# Procurar por erros de PAM ou compositor
# Se erro de seat → volta ao Cenário A

# Se erro de UWSM → pode ser config do Hyprland
# Testar sem UWSM:
sudo nano /home/rocha/.config/hypr/hyprland.conf
# E remover "uwsm app" dos exec-once
```

### Cenário C: Tela preta após login

```bash
# Pode ser que compositor está tentando iniciar mas falhando
# Pressione Ctrl+Alt+F2 para ir para TTY2 (terminal)
# Digite sua senha

# Então:
journalctl -n 100 | grep -i "hyprland\|wayland\|seat"

# Procure por erros e abra issue com os logs
```

---

## 📊 Comparação Antes/Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Tipo de Sessão | `tty` | `wayland` ✅ |
| Classe de Sessão | `manager` | `user` ✅ |
| Seat | (nenhum) | `seat0` ✅ |
| Hyprland Inicia | ❌ | ✅ |
| DMS Visível | ❌ | ✅ |

---

## 🎯 Sucesso Esperado

Após reboot e login:

1. ✅ **Sessão gráfica Wayland aparece**
2. ✅ **DMS shell é renderizada**
3. ✅ **Você consegue interagir com a interface**
4. ✅ **Sem erros no `journalctl`**

Se todos os itens acima são ✅, a solução está **funcionando corretamente**.

---

## 📝 Documentação de Referência

- `AUDIT_LOGIND_SESSION.md`: Análise do problema
- `SOLUTION_LOGIND_WAYLAND.md`: Detalhes técnicos da solução
- `modules/nixos/services/greetd-dms/default.nix`: Código da solução
