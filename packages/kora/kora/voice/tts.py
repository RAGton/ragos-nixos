# =============================================================================
# Kora Voice — TTS (Text to Speech)
# =============================================================================
# Usa piper-tts (do Nix PATH) com modelo .onnx PT-BR.
# O modelo é resolvido dinamicamente via config.py (current.onnx ou fallback).
# =============================================================================

import shutil
import subprocess
import logging
from pathlib import Path

logger = logging.getLogger("kora.voice.tts")

# Binários Piper suportados (injetados via wrapProgram no Nix)
_PIPER_CANDIDATES = [
    "piper-tts",   # nome real do pacote nixpkgs
    "piper",       # alias em alguns empacotamentos
]

def _find_piper_bin() -> str | None:
    for c in _PIPER_CANDIDATES:
        p = shutil.which(c)
        if p:
            return p
    return None


def speak_text(text: str) -> None:
    """Sintetiza texto com Piper usando o preset ativo."""
    speak_text_with_preset(text, preset=None)  # None → carrega preset ativo automaticamente



def _fallback_spd_say(text: str) -> None:
    """Fallback via spd-say se disponível."""
    spd = shutil.which("spd-say")
    if spd:
        try:
            subprocess.run([spd, text], check=True, timeout=10)
        except Exception:
            pass


def speak_text_with_preset(text: str, preset: dict | None = None) -> None:
    """Sintetiza texto usando parâmetros de um preset de voz."""
    if not text:
        return

    # Import tardio para evitar ciclo
    from .config import PIPER_MODEL_PATH, PIPER_CONFIG_PATH

    if preset is None:
        try:
            from .voices import get_active_preset
            preset = get_active_preset()
        except Exception:
            preset = {}

    piper_bin = _find_piper_bin()
    aplay_bin = shutil.which("aplay")

    if not piper_bin:
        logger.warning("piper-tts não encontrado no PATH — TTS desabilitado.")
        _fallback_spd_say(text)
        return

    model_path = Path(PIPER_MODEL_PATH)
    if not model_path.exists():
        logger.warning(
            f"Modelo Piper não encontrado: {model_path}\n"
            "  → Execute: kora voice models install piper faber"
        )
        _fallback_spd_say(text)
        return

    piper_cmd = [piper_bin, "--model", str(model_path), "--output_raw"]

    # Config opcional
    config_path = Path(PIPER_CONFIG_PATH)
    if config_path.exists():
        piper_cmd += ["--config", str(config_path)]

    # Parâmetros de qualidade/naturalidade
    if preset.get("length_scale"):
        piper_cmd += ["--length_scale", str(preset["length_scale"])]
    if preset.get("noise_scale"):
        piper_cmd += ["--noise_scale", str(preset["noise_scale"])]
    if preset.get("noise_w"):
        piper_cmd += ["--noise_w", str(preset["noise_w"])]

    try:
        piper_proc = subprocess.Popen(
            piper_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )

        if aplay_bin:
            aplay_proc = subprocess.Popen(
                [aplay_bin, "-r", "22050", "-f", "S16_LE", "-t", "raw", "-"],
                stdin=piper_proc.stdout,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            piper_proc.stdin.write(text.encode("utf-8"))
            piper_proc.stdin.close()
            aplay_proc.wait()
        else:
            piper_proc.stdin.write(text.encode("utf-8"))
            piper_proc.stdin.close()
            piper_proc.wait()
            logger.warning("aplay não encontrado — áudio não reproduzido.")
    except Exception as e:
        logger.error(f"TTS falhou: {e}")
        _fallback_spd_say(text)


