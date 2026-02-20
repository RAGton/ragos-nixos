# KDE Plasma Themes

Este diretório contém temas **exclusivos do KDE Plasma**.

## ⚠️ Importante

Os temas aqui **NÃO funcionam** em outros desktops como:
- Hyprland / DMS (DankMaterialShell)
- GNOME
- Xfce
- i3/Sway

## Temas Disponíveis

### Bart

**Localização:** `bart/default.nix`

**Descrição:** Tema completo do KDE Plasma incluindo:
- Look-and-Feel global do Plasma
- Decoração de janelas (Aurorae)
- Tema Qt via Kvantum
- Tema GTK (para compatibilidade com apps GTK no KDE)
- Ícones

**Fonte:** [KDE Store](https://store.kde.org)

**Componentes usados:**
- `plasma-manager` - gerenciamento declarativo do Plasma
- `Kvantum` - engine de temas para aplicações Qt
- `Aurorae` - decorador de janelas do KDE

**Como usar:**

```nix
{
  imports = [
    ../../../desktop/kde/themes/bart
  ];

  rag.theme.bart = {
    enable = true;
    name = "Bart";
    gtkName = "Bart";
    iconName = "Bart";
    kvantumTheme = "Bart";
    auroraeTheme = "__aurorae__svg__Bart";
    plasmaLookAndFeel = "Bart";
  };
}
```

## Arquitetura

```
desktop/kde/themes/
├── README.md          # Este arquivo
└── bart/
    └── default.nix    # Módulo do tema Bart
```

## Para Hyprland/DMS

Se você está usando Hyprland ou DMS (DankMaterialShell), os temas ficam em:
```
desktop/hyprland/themes/  # (quando implementado)
```

Hyprland usa temas baseados em:
- Waybar
- Rofi/Wofi
- Hyprland window decorations
- GTK themes (sem Plasma/Qt components)

