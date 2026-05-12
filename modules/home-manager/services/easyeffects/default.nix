# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o `EasyEffects` e publicar presets.
# - Define um preset padrão para microfone (ex.: rnnoise/compressor/limiter).
#
# Por quê:
# - Mantém a cadeia de áudio do microfone consistente entre máquinas.
# - Evita reconfigurar filtros manualmente após reinstalar/rebuild.
#
# Como:
# - Em Linux, habilita `services.easyeffects` e seleciona `preset = "mic"`.
# - Escreve `~/.config/easyeffects/input/mic.json` via `xdg.configFile`.
#
# Riscos:
# - Presets podem ser específicos do hardware (microfone/ganho) e precisar ajuste por host.
# - Mudanças no formato de preset entre versões podem exigir atualização do JSON.
# =============================================================================
{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Instala o EasyEffects via módulo do Home Manager.
    services.easyeffects = {
      enable = true;
      preset = "mic";

      # Preset padrão para a SAÍDA (melhora percepção de volume e clareza)
      # Obs.: o nome precisa existir em `~/.config/easyeffects/output/<nome>.json`.
      outputPreset = "speakers";
    };

    # Importa o preset do EasyEffects a partir do store do Home Manager.
    xdg.configFile = {
      "easyeffects/input/mic.json".text = ''
        {
          "input": {
            "blocklist": [],
            "compressor#0": {
              "attack": 2.0,
              "boost-amount": 6.0,
              "boost-threshold": -72.0,
              "bypass": false,
              "dry": -100.0,
              "hpf-frequency": 10.0,
              "hpf-mode": "off",
              "input-gain": 9.0,
              "knee": -6.0,
              "lpf-frequency": 20000.0,
              "lpf-mode": "off",
              "makeup": 0.0,
              "mode": "Downward",
              "output-gain": 0.0,
              "ratio": 4.0,
              "release": 200.0,
              "release-threshold": -40.0,
              "sidechain": {
                "lookahead": 0.0,
                "mode": "RMS",
                "preamp": 0.0,
                "reactivity": 10.0,
                "source": "Middle",
                "stereo-split-source": "Left/Right",
                "type": "Feed-forward"
              },
              "stereo-split": false,
              "threshold": -16.0,
              "wet": 0.0
            },
            "limiter#0": {
              "alr": false,
              "alr-attack": 5.0,
              "alr-knee": 0.0,
              "alr-release": 50.0,
              "attack": 1.0,
              "bypass": false,
              "dithering": "16bit",
              "external-sidechain": false,
              "gain-boost": false,
              "input-gain": 0.0,
              "lookahead": 5.0,
              "mode": "Herm Wide",
              "output-gain": 0.0,
              "oversampling": "Half x2(2L)",
              "release": 20.0,
              "sidechain-preamp": 0.0,
              "stereo-link": 100.0,
              "threshold": -3.0
            },
            "plugins_order": [
              "rnnoise#0",
              "compressor#0",
              "limiter#0"
            ],
            "rnnoise#0": {
              "bypass": false,
              "enable-vad": true,
              "input-gain": 0.0,
              "model-path": "",
              "output-gain": 0.0,
              "release": 20.0,
              "vad-thres": 50.0,
              "wet": 0.0
            }
          }
        }
      '';

      # Preset de saída: ganho automático + compressor + limiter + EQ leve
      # Objetivo: deixar o som mais alto/cheio sem distorcer.
      "easyeffects/output/speakers.json".text = ''
        {
          "output": {
            "blocklist": [],
            "plugins_order": [
              "equalizer#0",
              "autogain#0",
              "compressor#0",
              "limiter#0"
            ],
            "equalizer#0": {
              "bypass": false,
              "input-gain": 0.0,
              "output-gain": 0.0,
              "mode": "IIR",
              "split-channels": false,
              "bands": [
                { "type": "lowshelf", "frequency": 140.0, "quality": 0.7, "gain": 3.0 },
                { "type": "peaking",  "frequency": 900.0, "quality": 1.0, "gain": -1.5 },
                { "type": "highshelf","frequency": 6500.0, "quality": 0.7, "gain": 2.5 }
              ]
            },
            "autogain#0": {
              "bypass": false,
              "target": -16.0,
              "max-gain": 12.0,
              "min-gain": -12.0,
              "reset": false
            },
            "compressor#0": {
              "bypass": false,
              "mode": "Downward",
              "threshold": -18.0,
              "ratio": 3.0,
              "attack": 10.0,
              "release": 120.0,
              "knee": -6.0,
              "makeup": 3.0,
              "dry": -100.0,
              "wet": 0.0
            },
            "limiter#0": {
              "bypass": false,
              "threshold": -1.0,
              "lookahead": 5.0,
              "release": 50.0
            }
          }
        }
      '';
    };
  };
}
