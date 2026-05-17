# =============================================================================
# Kora Voice — STT (Speech to Text)
# =============================================================================

import os
import shutil
import subprocess
import logging
from pathlib import Path
from .config import WHISPER_MODEL_PATH

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
    """Transcribe audio file using whisper-cpp."""
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    # whisper-cpp -m <model> -f <file> -nt
    # -nt = no timestamps
    # -l pt = language portuguese (optional but good)
    try:
        whisper_bin = find_whisper_bin()
        res = subprocess.run([
            whisper_bin,
            "-m", WHISPER_MODEL_PATH,
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
