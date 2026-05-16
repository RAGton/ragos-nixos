# =============================================================================
# Kora Voice — Wake-word Detection
# =============================================================================

import logging

logger = logging.getLogger("kora.voice.wakeword")

class KoraWakeWord:
    def __init__(self, model="kora"):
        self.model = model
        self.active = False
        # foundation: stub for openwakeword integration
        logger.info(f"Wake-word engine initialized (model: {model}) [FOUNDATION]")

    def start(self):
        self.active = True
        logger.info("Wake-word detection started.")

    def stop(self):
        self.active = False
        logger.info("Wake-word detection stopped.")

    def detect(self, audio_buffer) -> bool:
        """
        Detect wake-word in audio buffer.
        Returns True if detected.
        """
        # Placeholder for real inference
        return False

def get_wakeword_status():
    return {
        "engine": "openWakeWord (planned)",
        "model": "kora",
        "status": "foundation",
        "ready": False
    }
