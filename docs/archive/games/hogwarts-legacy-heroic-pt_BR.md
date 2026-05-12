# Hogwarts Legacy (Heroic) — preset 1080p/75Hz (RTX 4060 8GB)

Objetivo: **qualidade visual alta** com **frametime estável** em 1080p/75Hz.

## 1) Melhor runner (Wine/Proton)

No Heroic, para jogos da Epic, o mais comum/estável é usar **Wine-GE** (GloriousEggroll).

- Recomendação: use a **versão mais nova do Wine-GE** disponível no Heroic/ProtonUp-Qt.
- Se uma versão nova quebrar (acontece), volte 1 versão.

### Como instalar/atualizar

- Abra `protonup-qt` e instale:
  - o **Wine-GE** mais recente (para Heroic)
  - (opcional) **GE-Proton** mais recente (se você preferir Proton dentro do Heroic)

## 2) Como iniciar (com performance + overlay + “Proton seguro”)

Use o wrapper que já está no seu repo:

- Abrir Heroic (com envs “seguras”):
  - `heroic-safe`

O que isso faz:

- força envs que evitam regressões comuns do Proton (`HDR/Wayland off`), útil quando o Heroic usa Proton/UMU.

### Overlay + GameMode (no jogo, não no Heroic)

Recomendação: não injete MangoHud no processo do Heroic (Electron), pois pode quebrar a GPU process.

No **Hogwarts Legacy** (Configurações do jogo no Heroic):

- **Wrapper**: `mangohud --dlsym gamemoderun`
- **Env**: `MANGOHUD_CONFIG=fps_limit=75`

> Importante: não inclua `umu-run` no campo Wrapper. O Heroic/Legendary já executa o runner; o wrapper é apenas o “prefixo”.

### Se aparecer "Driver/library version mismatch" (NVML)

Isso indica driver NVIDIA atualizado, mas o **kernel module ainda é antigo**.

- Solução: faça **reboot** do sistema e tente novamente.

## 3) Config do jogo (qualidade — RTX 4060 8GB)

### Dentro do jogo

- **Upscaling**: DLSS **Quality**
- **Cap de FPS**: 75 (se oscilar, 72)
- **Texturas**: **High** (Ultra em 8GB pode causar stutter por VRAM)
- **Ray Tracing**:
  - recomendação base (mais estável): **OFF**
  - se você quiser RT mesmo assim: ligue **somente RT Reflections** e mantenha Shadows/AO OFF/Low
- Pós-processo:
  - Motion Blur: OFF
  - Film Grain: OFF
  - Chromatic Aberration: OFF

### Se crashar/stutter pesado no DX12

- Coloque argumento `-dx11` no Heroic (por jogo) para testar estabilidade.
  - Observação: você perde RT e parte do visual do DX12, mas costuma estabilizar.

## 4) Validar gargalo (pra ajustar fino)

- `nvtop` (GPU/VRAM/clocks)
- MangoHud (FPS/frametime)

Se o **frametime virar “serra”** ou a **VRAM encostar no limite**:

1) baixar Texturas
2) desligar RT
3) trocar DLSS Quality → Balanced
