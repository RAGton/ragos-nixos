# =============================================================================
# Kora Voice — Voice Presets (voices.py)
# =============================================================================
# Define presets de parâmetros Piper para diferentes estilos de voz.
# O preset ativo é salvo em /var/lib/kryonix/kora/voice/config.json.
# =============================================================================

import json
import logging
import shutil
from pathlib import Path

logger = logging.getLogger("kora.voice.voices")

# ---------------------------------------------------------------------------
# Diretório de config de voz
# ---------------------------------------------------------------------------
VOICE_CONFIG_PATH = Path("/var/lib/kryonix/kora/voice/config.json")

# ---------------------------------------------------------------------------
# Catálogo de presets
# ---------------------------------------------------------------------------
VOICE_PRESETS: dict = {
    "kora_ptbr_female": {
        "model":        "kora_ptbr_female",
        "length_scale": 1.18,
        "noise_scale":  0.48,
        "noise_w":      0.78,
        "description":  "voz principal da Kora — feminina PT-BR (requer modelo custom importado)",
        "gender_note":  "feminina — requer modelo importado via 'kora voice models import piper kora_ptbr_female'",
        "custom":       True,
    },
    "default": {
        "model":        "faber",
        "length_scale": 1.18,
        "noise_scale":  0.55,
        "noise_w":      0.65,
        "description":  "voz PT-BR local padrão (faber)",
        "gender_note":  "masculina/neutra — voz feminina PT-BR local ainda não disponível",
    },
    "soft": {
        "model":        "faber",
        "length_scale": 1.28,
        "noise_scale":  0.45,
        "noise_w":      0.80,
        "description":  "mais lenta e suave",
        "gender_note":  "masculina/neutra — voz feminina PT-BR local ainda não disponível",
    },
    "fast": {
        "model":        "faber",
        "length_scale": 1.00,
        "noise_scale":  0.60,
        "noise_w":      0.70,
        "description":  "mais rápida e direta",
        "gender_note":  "masculina/neutra — voz feminina PT-BR local ainda não disponível",
    },
    "expressive": {
        "model":        "faber",
        "length_scale": 1.22,
        "noise_scale":  0.70,
        "noise_w":      0.55,
        "description":  "mais expressiva e variada",
        "gender_note":  "masculina/neutra — voz feminina PT-BR local ainda não disponível",
    },
}

DEFAULT_PRESET = "default"

# ---------------------------------------------------------------------------
# Persistência
# ---------------------------------------------------------------------------

def _load_config() -> dict:
    if VOICE_CONFIG_PATH.exists():
        try:
            return json.loads(VOICE_CONFIG_PATH.read_text())
        except Exception:
            pass
    return {"active_preset": DEFAULT_PRESET}


def _save_config(cfg: dict) -> None:
    VOICE_CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    VOICE_CONFIG_PATH.write_text(json.dumps(cfg, indent=2, ensure_ascii=False))


def get_active_preset_name() -> str:
    return _load_config().get("active_preset", DEFAULT_PRESET)


def get_active_preset() -> dict:
    name = get_active_preset_name()
    return VOICE_PRESETS.get(name, VOICE_PRESETS[DEFAULT_PRESET])


def set_active_preset(name: str) -> None:
    if name not in VOICE_PRESETS:
        raise ValueError(f"Preset desconhecido: '{name}'. Disponíveis: {list(VOICE_PRESETS)}")
    cfg = _load_config()
    cfg["active_preset"] = name
    _save_config(cfg)

# ---------------------------------------------------------------------------
# CLI actions
# ---------------------------------------------------------------------------

def cmd_list() -> None:
    """Lista presets disponíveis."""
    from .models import PIPER_VOICES, PIPER_DIR

    active = get_active_preset_name()
    print("\n[PRESETS DE VOZ DISPONÍVEIS]")
    for name, preset in VOICE_PRESETS.items():
        flag = "→" if name == active else " "
        model_name = preset["model"]
        installed = (PIPER_DIR / f"pt_BR-{model_name}-medium.onnx").exists()
        status = "✓" if installed else "✗ não instalado"
        print(f"  {flag} {name:<12} [{model_name} {status}]  {preset['description']}")

    print("\n[STATUS VOZ FEMININA PT-BR]")
    female_found = False
    for name, info in PIPER_VOICES.items():
        model_file = PIPER_DIR / info["local_model"]
        # Heurística: nenhum dos modelos rhasspy PT-BR disponíveis é feminino ainda
        if model_file.exists():
            print(f"  {name}: instalado — {info['local_model']}")
    if not female_found:
        print("  female_ptbr: MISSING")
        print("  ⚠ Voz feminina PT-BR local ainda não disponível via rhasspy/piper-voices.")
        print("    → Usando preset 'soft' no modelo atual para melhor naturalidade.")
    print()


def cmd_current() -> None:
    """Mostra preset ativo."""
    import json as _json
    name = get_active_preset_name()
    preset = get_active_preset()
    print(_json.dumps({"active_preset": name, **preset}, indent=2, ensure_ascii=False))


def cmd_set(name: str) -> None:
    """Ativa preset por nome."""
    set_active_preset(name)
    preset = VOICE_PRESETS[name]
    print(f"  ✓ Preset ativo: {name}  ({preset['description']})")
    print(f"  ℹ {preset.get('gender_note', '')}")


def cmd_test() -> None:
    """Fala frase de teste com o preset ativo."""
    from .tts import speak_text_with_preset
    preset = get_active_preset()
    name = get_active_preset_name()
    print(f"  → Testando preset '{name}' ({preset['description']})...")
    speak_text_with_preset(
        "Boa noite, Ragton. Estou online e pronta para acompanhar você.",
        preset=preset
    )
