# 🔍 AUDITORIA: Criação de Sessão logind (Problema: "manager" sem seat)

**Data**: 2026-02-21  
**Escopo**: Investigar por que logind cria uma sessão `class="manager"` sem seat attached, impedindo que Hyprland/DMS iniciem.

---

## 📋 SUMÁRIO DO PROBLEMA

**Comportamento observado**:

1. Sistema inicializa com sucesso
2. Usuário faz login via greetd + tuigreet
3. logind cria sessão com **classe "manager"** e **nenhum seat associado**
4. Hyprland NÃO inicia (compositor requer sessão "graphical")
5. DMS nunca é exibido

**Resultado**: Shell TTY, sem ambiente gráfico

---

## 🔎 INVESTIGAÇÃO

### 1. **Ponto de Entrada: greetd-dms**

**Arquivo**: `modules/nixos/services/greetd-dms/default.nix`

```nix
config = lib.mkIf cfg.enable {
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = greeterUser;  # default: "greeter" (usuário de sistema)
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${lib.escapeShellArg cfg.command}";
    };
  };
}
```

**O que fazemos:**

- Habilita `services.greetd` (login manager Wayland-friendly)
- Configura `tuigreet` como greeter (interface de login textual)
- Comando padrão: `uwsm start hyprland-uwsm.desktop`
  - `uwsm` = Universal Wayland Session Manager
  - `hyprland-uwsm.desktop` = arquivo de sessão para Hyprland via UWSM

---

### 2. **PAM Service Utilizado**

greetd usa o serviço PAM padrão: **nenhuma configuração customizada no projeto**

```nix
# Em modules/nixos/services/greetd-dms/default.nix
# ❌ NÃO HÁ:
# security.pam.services.greetd = { ... };
```

**Implicação**: greetd usa a configuração PAM padrão do NixOS, que **não especifica a classe de sessão logind**.

---

### 3. **Hyprland + UWSM**

**Arquivo**: `desktop/hyprland/system.nix`

```nix
programs.hyprland = {
  enable = true;
  portalPackage = pkgs.xdg-desktop-portal-hyprland;
  withUWSM = true;  # ⚠️ ATIVADO
};
```

**O que significa `withUWSM = true`**:

- O módulo NixOS `programs.hyprland` requer que a sessão seja iniciada via UWSM
- UWSM deve criar uma sessão Wayland com atributos corretos

**Problema**: O arquivo `.desktop` da sessão (`hyprland-uwsm.desktop`) **não é configurado neste projeto** — é fornecido pelo pacote `uwsm` ou `hyprland`.

---

### 4. **Sessão PAM e Seat Attachment**

Para que **logind crie uma sessão `class="graphical"` com seat**, é necessário:

1. **PAM service com tipo de sessão correto**

   ```
   session optional pam_systemd.so class=user type=wayland
   ```

2. **Variáveis de ambiente**

   ```
   XDG_SESSION_TYPE=wayland
   XDG_SESSION_CLASS=user  # ou "greeter" para login
   ```

3. **Comando de compositor que abre um novo seat** ou reutiliza a sessão corretamente

---

## 🚨 ROOT CAUSE ANALYSIS

### O Problema Real

**greetd-dms não configura PAM adequadamente para criar sessão graphical com seat:**

1. **PAM Service Padrão**: greetd usa a configuração padrão do NixOS
   - Sem especificação de `class=user` ou `type=wayland`
   - Sem `pam_systemd.so` customizado

2. **tuigreet Executa Diretamente**:

   ```bash
   tuigreet --time --cmd "uwsm start hyprland-uwsm.desktop"
   ```

   - `tuigreet` é um greeter textual (não compositor)
   - O comando (`uwsm start ...`) é executado **DENTRO da sessão do greeter**
   - Essa sessão é criada por logind como **"manager"** (classe padrão para login managers)

3. **UWSM Não Cria Nova Sessão**:
   - UWSM espera **estar já dentro de uma sessão Wayland válida**
   - Se herdado de uma sessão "manager" sem seat, UWSM não consegue criar o ambiente gráfico correto

---

## 📌 QUAL MÓDULO CAUSA O PROBLEMA

### **Culpado #1: `modules/nixos/services/greetd-dms/default.nix`**

**Linhas problemáticas**:

```nix
services.greetd = {
  enable = true;
  settings.default_session = {
    user = greeterUser;
    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${lib.escapeShellArg cfg.command}";
  };
};
```

**Por quê**:

- Não configura PAM para definir tipo/classe de sessão
- Não especifica seat attachment
- Não define `XDG_SESSION_TYPE=wayland` ou `XDG_SESSION_CLASS`

---

### **Culpado #2: `desktop/hyprland/system.nix` (Indiretamente)**

**Linhas problemáticas**:

```nix
programs.hyprland = {
  enable = true;
  withUWSM = true;  # ⚠️ Requer UWSM
};

# ❌ FALTA:
# security.pam.services."<greeter_pam_service>" = { ... };
```

**Por quê**:

- `withUWSM = true` muda a forma de inicializar Hyprland
- UWSM é um gerenciador de sessão moderno que **requer uma sessão Wayland válida**
- Mas greetd não cria uma sessão Wayland válida automaticamente

---

## 🔧 DIAGRAMA DO FLUXO ATUAL (INCORRETO)

```
[logind]
  ↓
[Criar sessão "manager" (sem seat)]
  ↓
[greetd.service é iniciado nessa sessão]
  ↓
[tuigreet é executado]
  ↓
[Usuário digita credenciais]
  ↓
[PAM autentica → sesssão PAM]
  ↓
[Executar comando: uwsm start hyprland-uwsm.desktop]
  ↓
[UWSM herda sessão "manager" ❌]
  ↓
[Hyprland não consegue criar compositor sem seat Wayland ❌]
  ↓
[Shell TTY 🔴]
```

---

## 🔧 DIAGRAMA DO FLUXO ESPERADO (CORRETO)

```
[logind]
  ↓
[Criar sessão "graphical" com seat (via PAM config)]
  ↓
[greetd.service é iniciado nessa sessão]
  ↓
[tuigreet é executado]
  ↓
[Usuário digita credenciais]
  ↓
[PAM autentica → sessão PAM com class=user type=wayland]
  ↓
[Executar comando: uwsm start hyprland-uwsm.desktop]
  ↓
[UWSM herda sessão Wayland válida ✅]
  ↓
[Hyprland inicia compositor com acesso ao seat ✅]
  ↓
[DMS shell é exibida ✅]
```

---

## 📊 ANÁLISE COMPARATIVA

### Greetd sem UWSM (Deveria Funcionar)

```nix
# NO PROJETO:
# programs.hyprland.withUWSM = true;  # ❌ ATIVA UWSM
command = "uwsm start hyprland-uwsm.desktop";  # UWSM requer sessão Wayland

# CORRETO SERIA:
# programs.hyprland.withUWSM = false;
# command = "Hyprland";  # Executa Hyprland diretamente
```

**Problema**: Projeto ativa UWSM mas não configura a sessão PAM necessária

---

### Greetd com Configuração PAM Adequada (Alternativa)

```nix
# EM desktop/hyprland/system.nix ou modules/nixos/services/greetd-dms/default.nix

security.pam.services.greetd = {
  # ✅ Especifica classe e tipo de sessão
  unixAuth = true;
  unixStandalone = false;
  
  # Configurar sessionControl e type para logind
  # (sintaxe exata depende da versão do NixOS)
};
```

**Resultado Esperado**: logind criaria sessão com `class="user"` e seat válido

---

## 🎯 CONCLUSÃO

### **Raiz do Problema**

**greetd-dms** (`modules/nixos/services/greetd-dms/default.nix`) não configura a sessão PAM para:

1. **Tipo de sessão**: `type=wayland` (não especificado → logind padrão)
2. **Classe de sessão**: `class=user` (logind cria "manager" por padrão)
3. **Seat attachment**: Nenhuma garantia de que a sessão tenha um seat associado

### **Secundariamente**

**desktop/hyprland/system.nix** ativa `withUWSM = true`, que **requer** uma sessão Wayland válida, mas greetd-dms não fornece essa.

### **Por Que Logind Cria "manager" sem seat**

1. greetd usa configuração PAM padrão do NixOS
2. PAM padrão **não especifica `class=` ou `type=`** para pam_systemd.so
3. logind, sem instruções, assume `class="manager"` (padrão para login managers)
4. Sessões "manager" **não recebem seat de VT** por design
5. Hyprland via UWSM tenta usar essa sessão "manager" e falha

### **Qual Módulo É Responsável**

- **`modules/nixos/services/greetd-dms/default.nix`**: Não configura PAM ❌
- **`desktop/hyprland/system.nix`**: Ativa UWSM sem garantir sessão Wayland ⚠️
