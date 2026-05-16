# =============================================================================
# Kora Voice — TTS (Text to Speech)
# =============================================================================

import subprocess
import logging
from .config import PIPER_MODEL_PATH, PIPER_CONFIG_PATH

logger = logging.getLogger("kora.voice.tts")

def speak_text(text: str):
    """Speak text using piper-tts and aplay."""
    if not text:
        return

    # echo "text" | piper --model <model> --config <config> --output_raw | aplay -r 22050 -f S16_LE -t raw -
    try:
        # We'll use a pipe to send text to piper and then to aplay
        piper_proc = subprocess.Popen([
            "piper",
            "--model", PIPER_MODEL_PATH,
            "--output_raw"
        ], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        
        aplay_proc = subprocess.Popen([
            "aplay",
            "-r", "22050", # Piper default
            "-f", "S16_LE",
            "-t", "raw",
            "-"
        ], stdin=piper_proc.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        piper_proc.stdin.write(text.encode("utf-8"))
        piper_proc.stdin.close()
        
        aplay_proc.wait()
    except Exception as e:
        logger.error(f"TTS failed: {e}")
        # Fallback to spd-say if available
        try:
            subprocess.run(["spd-say", text], check=True)
        except:
            pass
