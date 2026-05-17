# =============================================================================
# Kora Voice — STT (Speech to Text)
# =============================================================================

import os
import shutil
import subprocess
import logging
from pathlib import Path

logger = logging.getLogger("kora.voice.stt")

WHISPER_CANDIDATES = [
    os.environ.get("KORA_WHISPER_BIN"),
    "whisper-cli",
    "whisper-cpp",
    "whisper-cpp-cli",
    "whisper",
]

def find_whisper_bin() -> str:
    for candidate in WHISPER_CANDIDATES:
        if not candidate:
            continue
        path = shutil.which(candidate)
        if path:
            return path
    raise RuntimeError(
        "Whisper backend não encontrado. Instale/adicione whisper-cpp ao PATH "
        "ou defina KORA_WHISPER_BIN."
    )

def transcribe_audio(audio_path: Path) -> str:
    """Transcribe audio file using whisper-cli."""
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    # Resolve model dynamically so post-install runs pick up the model
    from .config import _resolve_whisper_model
    model_path = _resolve_whisper_model()

    if not Path(model_path).exists():
        logger.error(
            f"Modelo Whisper não encontrado: {model_path}\n"
            "  → Execute: kora voice models install whisper base"
        )
        return "[Modelo Whisper não instalado — execute: kora voice models install whisper base]"

    try:
        whisper_bin = find_whisper_bin()
        logger.debug(f"STT: usando {whisper_bin} com modelo {model_path}")
        res = subprocess.run([
            whisper_bin,
            "-m", model_path,
            "-f", str(audio_path),
            "-nt",
            "-l", "pt",
            "--print-colors", "false"
        ], capture_output=True, text=True, check=True)

        text = res.stdout.strip()
        logger.info(f"STT: {text}")
        return text
    except Exception as e:
        logger.error(f"STT failed: {e}")
        return "[Erro na transcrição]"

