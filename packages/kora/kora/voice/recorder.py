# =============================================================================
# Kora Voice — Recorder
# =============================================================================

import subprocess
import time
import logging
from pathlib import Path
from .config import KORA_VOICE_TMP_DIR, ensure_voice_dirs

logger = logging.getLogger("kora.voice.recorder")

class KoraRecorder:
    def __init__(self):
        ensure_voice_dirs()

    def record_to_file(self, filename: str, seconds: int = 5) -> Path:
        """Record audio for a fixed duration."""
        output_path = KORA_VOICE_TMP_DIR / filename
        logger.info(f"Recording {seconds} seconds to {output_path}...")

        # arecord -d <seconds> -f S16_LE -r 16000 -c 1 <file>
        try:
            subprocess.run([
                "arecord",
                "-d", str(seconds),
                "-f", "S16_LE",
                "-r", "16000",
                "-c", "1",
                str(output_path)
            ], check=True)
            return output_path
        except Exception as e:
            logger.error(f"Recording failed: {e}")
            raise

    def record_until_keypress(self, filename: str) -> Path:
        """Record until user presses Enter (Push-to-Talk)."""
        output_path = KORA_VOICE_TMP_DIR / filename
        print("\n[REC] Gravando... (Pressione Ctrl+C para parar se travar)")

        # arecord -f S16_LE -r 16000 -c 1 <file>
        # We start the process and kill it when needed
        process = subprocess.Popen([
            "arecord",
            "-f", "S16_LE",
            "-r", "16000",
            "-c", "1",
            str(output_path)
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        try:
            input("Pressione [Enter] para parar de falar...")
        finally:
            process.terminate()
            process.wait()

        return output_path
