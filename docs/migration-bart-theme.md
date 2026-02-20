# Migração: Tema Bart → KDE-Specific

**Data**: 2026-02-18  
**Tipo**: Reorganização estrutural  
**Risco**: Baixo (apenas movimentação de arquivo)

---

## 🎯 Objetivo

Mover o tema Bart para a estrutura correta, refletindo que ele é **exclusivo do KDE Plasma** e não pode ser usado em outros desktops (Hyprland, GNOME, etc).

---

## 📋 Mudanças Aplicadas

### 1. Estrutura de Diretórios

**ANTES:**
```
modules/home-manager/desktop/themes/bart/default.nix
```

**DEPOIS:**
```
desktop/kde/themes/bart/default.nix
```

### 2. Imports Atualizados

**Arquivo**: `home/rag/inspiron/default.nix`

**ANTES:**
```nix
imports = [
  ../../../modules/home-manager/common
  ../../../desktop/kde/user.nix
  ../../../modules/home-manager/desktop/themes/bart  # ❌ caminho errado
];
```

**DEPOIS:**
```nix
imports = [
  ../../../modules/home-manager/common
  ../../../desktop/kde/user.nix
  ../../../desktop/kde/themes/bart  # ✅ caminho correto
];
```

### 3. Documentação Adicionada

#### Criado: `desktop/kde/themes/README.md`
- Explica que temas aqui são KDE-only
- Lista componentes usados (Plasma, Kvantum, Aurorae)
- Documenta o tema Bart
- Indica onde ficam temas para outros desktops

#### Atualizado: `INSTRUCT.md`
- Nova seção 3.5: "Adicionar Tema Desktop-Specific"
- Aviso sobre temas serem específicos de cada DE
- Exemplo de como criar tema KDE
- Lista de componentes exclusivos do KDE

#### Atualizado: `desktop/kde/themes/bart/default.nix`
- Cabeçalho expandido com aviso ⚠️ KDE ONLY
- Lista de dependências exclusivas do KDE
- Documentação melhorada

---

## 🔍 Por Que Isso Foi Feito?

### Problema Identificado

O tema Bart estava em `modules/home-manager/desktop/themes/`, sugerindo que poderia ser usado em qualquer desktop. Porém, ele usa:

- **plasma-manager** - gerenciamento declarativo do KDE Plasma
- **Kvantum** - engine de temas Qt/KDE
- **Aurorae** - decorador de janelas exclusivo do KDE
- **Look-and-Feel** do Plasma

Nenhum desses componentes funciona fora do KDE Plasma.

### Solução

Mover para `desktop/kde/themes/` deixa **explícito** que:
1. É um tema **exclusivo do KDE**
2. Não funciona em Hyprland/DMS
3. Está organizado junto com a configuração do KDE

---

## ✅ Verificação

### Comandos Executados

```bash
# Mover diretório
mv modules/home-manager/desktop/themes/bart desktop/kde/themes/bart

# Verificar erros
nix flake check
```

### Arquivos Validados

- ✅ `home/rag/inspiron/default.nix` - import atualizado
- ✅ `desktop/kde/themes/bart/default.nix` - documentação melhorada
- ✅ Sem erros de sintaxe Nix

---

## 🎯 Próximos Passos

### Para Hyprland/DMS

Quando implementar temas para Hyprland, criar em:
```
desktop/hyprland/themes/
```

Esses temas usarão:
- Waybar theming
- Rofi/Wofi styling
- Hyprland window decorations
- GTK themes (sem componentes Qt/Plasma)

### Padrão Estabelecido

Todos os temas futuros devem seguir:

```
desktop/
├── kde/
│   └── themes/
│       └── <tema-kde>/
├── hyprland/
│   └── themes/
│       └── <tema-hyprland>/
└── gnome/
    └── themes/
        └── <tema-gnome>/
```

**Regra**: Temas ficam dentro do desktop para o qual foram feitos.

---

## 📊 Impacto

- **Hosts afetados**: `inspiron` (usa tema Bart)
- **Hosts não afetados**: `Glacier` (não usa tema Bart)
- **Breaking changes**: Nenhum (apenas reorganização interna)
- **Ações do usuário**: Nenhuma (mudança transparente)

---

## 🏗️ Alinhamento com Arquitetura v2

Esta mudança está **100% alinhada** com a arquitetura alvo do RagOS v2:

```
desktop/               # Desktop environments
├── kde/
│   ├── system.nix    # NixOS config
│   ├── user.nix      # Home Manager config
│   └── themes/       # ✅ Temas KDE-specific
│       └── bart/
└── hyprland/
    ├── system.nix
    ├── user.nix
    └── themes/       # ✅ Temas Hyprland-specific (futuro)
```

---

## 📝 Resumo

✅ Tema Bart movido para `desktop/kde/themes/`  
✅ Imports atualizados  
✅ Documentação criada  
✅ INSTRUCT.md atualizado  
✅ Sem erros de avaliação  
✅ Preparado para DMS/Hyprland no futuro

