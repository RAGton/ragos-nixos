# Manual (PT-BR): `programs.plasma.panels` no plasma-manager (Plasma 6)

Este manual explica como declarar painéis do KDE Plasma via **plasma-manager** usando Home Manager.

> Contexto do seu repo: a configuração principal do Plasma fica em `modules/home-manager/desktop/kde/default.nix` e usa `programs.plasma.overrideConfig = true;`.

---

## 1) Conceitos importantes

- **Painel**: uma “barra” do Plasma (top/bottom/left/right).
- **Widget / Plasmoid / Applet**: itens dentro do painel (menu, relógio, system tray, monitores etc.).
- **`overrideConfig = true`**: o plasma-manager reescreve os arquivos de configuração do Plasma durante a ativação.
  - Resultado prático: o painel *sempre volta* exatamente para o que está no Nix.
  - Se você alterar via GUI, a mudança some no próximo `home-manager switch`.

---

## 2) Estrutura básica do `programs.plasma.panels`

A opção recebe uma lista de painéis:

```nix
programs.plasma = {
  enable = true;
  overrideConfig = true;

  panels = [
    {
      location = "top";
      height = 36;
      floating = true;
      opacity = "translucent";
      alignment = "center";
      lengthMode = "fit";

      widgets = [
        { name = "org.kde.plasma.digitalclock"; }
      ];
    }
  ];
};
```

No seu repo, os painéis seguem esse mesmo padrão: cada item do array é um painel; cada painel tem um array `widgets`.

---

## 3) Campos mais usados (no seu padrão)

### `location`

Onde o painel fica.

Valores comuns:

- `"top"`
- `"bottom"`
- `"left"`
- `"right"`

### `height`

Altura do painel em pixels (ex.: `36`).

### `floating`

Se `true`, painel fica “flutuante” (com bordas arredondadas dependendo do tema/estilo).

### `opacity`

Opacidade/estilo do painel.

Você está usando `"translucent"` no layout atual.

### `alignment`

Alinhamento horizontal do painel (quando `lengthMode = "fit"`).

Você usa:

- `"left"`
- `"center"`
- `"right"`

### `lengthMode`

Como o painel ocupa a largura.

Você usa `"fit"` (tamanho “encaixa no conteúdo”).

---

## 4) Declarando widgets

Cada widget é um attrset com:

- `name`: **ID do plasmoid/applet**.
- `config`: configurações específicas do widget.

Exemplo (o mesmo formato que você usa no painel de CPU):

```nix
{
  name = "org.kde.plasma.systemmonitor.cpucore";
  config = {
    CurrentPreset = "org.kde.plasma.systemmonitor";
    Appearance = {
      chartFace = "org.kde.ksysguard.barchart";
      title = "Uso individual do núcleo";
    };
  };
}
```

### Observação sobre `config`

O `config` costuma mapear seções/keys de configurações do Plasma (bem parecido com INI).

Dicas práticas:

- Se algo não aplicar, compare com o que ficou gravado em `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
- Alguns widgets usam nomes de seção como `General`, `Appearance`, `SensorColors` etc.

---

## 5) Como descobrir o `name` (ID) de um widget

### Opção A: `kpackagetool6`

Liste applets instalados:

```bash
kpackagetool6 --type Plasma/Applet --list
```

Você pode filtrar:

```bash
kpackagetool6 --type Plasma/Applet --list | grep -i tray
```

### Opção B: olhar os diretórios de plasmoids

Widgets do usuário costumam ficar em:

- `~/.local/share/plasma/plasmoids/<ID_DO_WIDGET>`

O nome da pasta normalmente é exatamente o ID que você deve colocar em `name`.

### Opção C: ler o `appletsrc`

Quando você mexe via GUI, o Plasma escreve em:

- `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

Ali você consegue:

- ver quais applets estão em cada painel
- copiar IDs
- copiar blocos de config como referência

---

## 6) Por que “o painel volta” depois do rebuild

Isso acontece quando:

- `programs.plasma.overrideConfig = true;`
- você declara `programs.plasma.panels = [ ... ];`

Nessa combinação, o plasma-manager entende que o **estado de verdade** é o Nix, e re-aplica o layout em toda ativação.

### Como evitar reset (se você quiser customizar via GUI)

Escolha um caminho:

1) **Totalmente declarativo (recomendado para reprodutibilidade)**

- mantenha `overrideConfig = true`
- qualquer ajuste de painel deve ser feito editando o Nix

1) **GUI manda (menos reprodutível)**

- coloque `overrideConfig = false` (ou remova)
- e/ou pare de declarar `panels`

> No seu caso, como o objetivo é “painel sempre igual após rebuild”, faz sentido manter declarativo.

---

## 7) Workflow recomendado para ajustar um painel sem dor

1) Ajuste o painel na GUI (uma vez), só para “descobrir” opções
2) Leia `~/.config/plasma-org.kde.plasma.desktop-appletsrc` e copie:
   - IDs dos applets
   - blocos de config relevantes
3) Traduza para `programs.plasma.panels` (igual ao padrão já usado no repo)
4) Rode `home-manager switch --flake .#rocha@inspiron`
5) Confirme que, após logout/login, continua igual

---

## 8) Troubleshooting rápido

- **Widget não abre configuração / Plasma instável**: geralmente é plasmoid quebrado em `~/.local/share/plasma/plasmoids`. Remover/mover o diretório do plasmoid costuma resolver.
- **System tray “perde” itens**: o tray tem configuração própria e pode exigir definir entradas explicitamente.
- **Mudanças não aparecem**: valide se a home config aplicada é a correta (`home-manager switch --flake .#rocha@inspiron`) e se o `overrideConfig` está `true`.
