# RagOS Incremental Migration Checklist

**Versão**: v1 → v2  
**Modo**: Migração Incremental (1 step at a time)  
**Data Início**: 2026-02-18

---

## 🎯 Regras Obrigatórias

- [x] **NUNCA** aplicar 2 etapas ao mesmo tempo
- [ ] **SEMPRE** rodar `nix flake check` após mudança
- [ ] **SEMPRE** manter boot funcional (rollback disponível)
- [ ] **SEMPRE** commit após cada etapa bem-sucedida

---

## 📊 Progresso Geral

```
Fase 1: Sistema de Opções      ████████████████████ 100% (5/5) ✅
Fase 2: Separar Desktop        ████████████████████ 100% (4/4) ✅
Fase 3: Desktop Manager        ████████████████████ 100% (1/1) ✅
Fase 4: Hyprland Moderno       ████████████████████ 100% (3/3) ✅
Fase 5: DMS Integration        ████████░░░░░░░░░░░░  40% (2/5) 🔄
Fase 6: Features Modulares     ████████████████████ 100% (3/3) ✅
Fase 7: Profiles               ████████████████████ 100% (3/3) ✅

TOTAL:                         ██████████████████░░  86% (18/21)
```

---

## 📋 Fase 1 — Sistema de Opções

### Objetivo
Criar infraestrutura de opções `rag.*` sem quebrar configuração existente.

### Etapas

- [x] **1.1** Criar `lib/default.nix` (helpers)
- [x] **1.2** Criar `lib/options.nix` (definir opções rag.*)
- [x] **1.3** Modificar `flake.nix` (importar lib/options.nix)
- [x] **1.4** Testar `nix flake check`
- [x] **1.5** Commit "feat: add rag.* options infrastructure"

**Status**: ✅ CONCLUÍDA (2026-02-18)

---

## 📋 Fase 2 — Separar Desktop

### Objetivo
Separar desktop em system.nix (NixOS) e user.nix (Home Manager).

### Etapas

- [x] **2.1** Mover `modules/nixos/desktop/kde/default.nix` → `desktop/kde/system.nix`
- [x] **2.2** Mover `modules/nixos/desktop/hyprland/default.nix` → `desktop/hyprland/system.nix`
- [x] **2.3** Criar `desktop/kde/user.nix` (mover configs do home-manager)
- [x] **2.4** Criar `desktop/hyprland/user.nix` (mover configs do home-manager)

**Status**: ✅ CONCLUÍDA (2026-02-18)

---

## 📋 Fase 3 — Desktop Manager (Auto-import)

### Objetivo
Criar desktop/manager.nix que auto-importa desktop baseado em opção.

### Etapas

- [x] **3.1** Criar `desktop/manager.nix`

**Status**: 🔄 EM ANDAMENTO (1/1 completo, aguardando validação de build)

---

## 📋 Fase 4 — Hyprland Moderno

### Objetivo
Atualizar Hyprland para padrões modernos (portal correto).

### Etapas

- [x] **4.1** Atualizar portal: `xdg-desktop-portal-wlr` → `xdg-desktop-portal-hyprland`
- [x] **4.2** Verificar dbus/session ok
- [x] **4.3** Testar GDM session

**Status**: ✅ CONCLUÍDA (já implementada durante Fase 2.2)

---

## 📋 Fase 5 — DMS (DankMaterialShell)

### Objetivo
Integrar DankMaterialShell como rice do Hyprland.

### Etapas

- [x] **5.1** Adicionar `inputs.dms` no flake.nix
- [x] **5.2** Criar `desktop/hyprland/rice/dms.nix` (módulo base)
- [x] **5.3** Inspecionar repo DMS e ajustar paths
- [ ] **5.4** Link Waybar configs
- [ ] **5.5** Testar em host

**Status**: 🔄 EM PROGRESSO (3/5 completo)

---

## 📋 Fase 6 — Features Modulares

### Objetivo
Mover features para módulos opcionais ativados por opções.

### Etapas

- [x] **6.1** Criar `features/gaming.nix`
- [x] **6.2** Criar `features/virtualization.nix`
- [x] **6.3** Criar `features/development.nix`

**Status**: ✅ CONCLUÍDA (2026-02-19)

---

## 📋 Fase 7 — Profiles

### Objetivo
Criar profiles composáveis (desktop, laptop, vm).

### Etapas

- [x] **7.1** Criar `profiles/desktop.nix`
- [x] **7.2** Criar `profiles/laptop.nix`
- [x] **7.3** Criar `profiles/vm.nix`

**Status**: ✅ CONCLUÍDA (3/3 completo)

---

## 🔥 Etapa Atual

✅ Fase 7 concluída. Próximo foco recomendado: Fase 5 (DMS) Step 5.3.

**Próximos comandos**:
```bash
# Check geral
nix flake check

# Dry build do host principal
nixos-rebuild dry-build --flake .#inspiron
```

---

## 📝 Notas de Migração

### Atualizações recentes
- ✅ inspiron: migrou para `rag.profiles.laptop.enable = true` (host mais fino)
- ✅ inspiron: desabilitado OpenRGB via `rag.hardware.openrgb.enable = false`

### Fase 1 (Concluída - 2026-02-18) ✅
- ✅ Criado sistema de opções `rag.*`
- ✅ Namespace completo para desktop, features, branding
- ✅ Tag: v2-phase1-options

### Fase 2 (Concluída - 2026-02-18) ✅
- ✅ Movido KDE: system.nix + user.nix
- ✅ Movido Hyprland: system.nix + user.nix
- ✅ BONUS: Portal Hyprland atualizado (wlr → hyprland)
- ✅ Removido `modules/nixos/desktop/` (vazio)
- ✅ Removido `modules/home-manager/desktop/` (vazio)
- ✅ Estrutura `desktop/*/system.nix` + `desktop/*/user.nix` criada

### Próxima Etapa (3.1)
- Criar `desktop/manager.nix` para auto-import baseado em `rag.desktop.environment`
- Preparar para hosts usarem opções em vez de imports diretos

---

## 🎯 Critérios de Sucesso (Fase 1 completa)

- [ ] `nix flake check` passa sem erros
- [ ] `nixos-rebuild dry-build --flake .#Glacier` funciona
- [ ] `nixos-rebuild dry-build --flake .#inspiron` funciona
- [ ] Sistema atual continua bootando normalmente
- [ ] Opções `rag.*` estão disponíveis (via `nix eval`)

---

## 🔄 Rollback

Se algo der errado:
```bash
# Git
git reset --hard HEAD~1

# NixOS
sudo nixos-rebuild switch --rollback

# Home Manager
home-manager switch --rollback
```

---

**Última atualização**: 2026-02-18 (Fase 1 concluída ✅)  
**Próximo passo**: Fase 2, Etapa 2.1 (mover KDE)
