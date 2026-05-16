# =============================================================================
# Kora Voice — Device Management
# =============================================================================

import subprocess
import logging
from typing import List, Dict

logger = logging.getLogger("kora.voice.devices")

def list_input_devices() -> List[str]:
    """List available capture devices using arecord."""
    try:
        res = subprocess.run(["arecord", "-l"], capture_output=True, text=True, check=True)
        return res.stdout.splitlines()
    except Exception as e:
        logger.error(f"Error listing input devices: {e}")
        return ["ALSA: Default Input"]

def list_output_devices() -> List[str]:
    """List available playback devices using aplay."""
    try:
        res = subprocess.run(["aplay", "-l"], capture_output=True, text=True, check=True)
        return res.stdout.splitlines()
    except Exception as e:
        logger.error(f"Error listing output devices: {e}")
        return ["ALSA: Default Output"]

def get_default_input_device() -> str:
    return "default"

def get_default_output_device() -> str:
    return "default"
