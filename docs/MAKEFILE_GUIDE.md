# 📖 Como Usar o Makefile

## 🎯 Solução Sessão Wayland (inspiron)

### Quick Start: Uma Linha

```bash
make wayland-session-fix
```

Isso:
1. Reconstrói o NixOS com a solução implementada
2. Faz reboot automático
3. Você faz login normalmente após reboot
4. Hyprland deve iniciar ✅

### Validar Depois do Reboot

```bash
make wayland-session-test
```

Mostra:
- Tipo de sessão logind (deve ser `wayland`, não `tty`)
- Classe de sessão (deve ser `user`, não `manager`)
- Seat (deve ser `seat0`, não vazio)

---

## 📦 Instalação (Primeira Vez)

### Instalar Nix (se não tiver)
```bash
make install-nix
```

### Instalar nix-darwin (macOS)
```bash
make install-nix-darwin
```

### Ou ambos (macOS)
```bash
make bootstrap-mac
```

---

## 🔨 Reconstrução Padrão

### Reconstruir NixOS Atual
```bash
make nixos-rebuild
```
(usa o hostname atual via `HOSTNAME ?= $(shell hostname)`)

### Reconstruir Host Específico
```bash
make nixos-rebuild HOSTNAME=inspiron
```

### Reconstruir Darwin (macOS)
```bash
make darwin-rebuild
```

### Aplicar Home Manager
```bash
make home-manager-switch
```

---

## 🛠️ Utilidades

### Verificar Flake (sintaxe Nix)
```bash
make flake-check
```

### Atualizar Inputs
```bash
make flake-update
```

### Limpar Garbage Collection
```bash
make nix-gc
```

---

## 📋 Ver Todos os Targets

```bash
make help
```

Mostra todos os targets disponíveis com descrições.

---

## 💡 Exemplos Comuns

### Exemplo 1: Ativar Solução Wayland
```bash
cd /home/rocha/GitHub/dotfiles-NixOs
make wayland-session-fix
# Espere reboot...
# Faça login
# Hyprland deve iniciar ✅
```

### Exemplo 2: Reconstruir Outro Host
```bash
make nixos-rebuild HOSTNAME=Glacier
```

### Exemplo 3: Validar Solução
```bash
make wayland-session-test

# Esperado:
# Session c1
#      Type: wayland
#     Class: user
#     State: active
#     Seat: seat0
```

### Exemplo 4: Limpeza Completa
```bash
make flake-check
make nix-gc
```

---

## ⚙️ Variáveis

Pode sobrescrever:

```bash
# Usar host específico
make nixos-rebuild HOSTNAME=inspiron

# Usar flake específica
make nixos-rebuild FLAKE=.#inspiron

# Usar target Home Manager específico
make home-manager-switch HOME_TARGET=.#rag@inspiron
```

---

## 📝 Notas

- Todos os targets que modificam sistema usam `sudo`
- `make help` mostra ajuda completa
- Use `make` sem argumentos para ver ajuda padrão

