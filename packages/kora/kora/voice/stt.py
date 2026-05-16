# =============================================================================
# Kora Voice — STT (Speech to Text)
# =============================================================================

import subprocess
import logging
from pathlib import Path
from .config import WHISPER_MODEL_PATH

logger = logging.getLogger("kora.voice.stt")

def transcribe_audio(audio_path: Path) -> str:
    """Transcribe audio file using whisper-cpp."""
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    # whisper-cpp -m <model> -f <file> -nt
    # -nt = no timestamps
    # -l pt = language portuguese (optional but good)
    try:
        res = subprocess.run([
            "whisper-cpp",
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
