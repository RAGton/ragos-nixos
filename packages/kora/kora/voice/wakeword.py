# =============================================================================
# Kora Voice — Wake-word Detection
# =============================================================================

import logging
import numpy as np

try:
    from openwakeword.model import Model
    OPENWAKEWORD_AVAILABLE = True
except ImportError:
    OPENWAKEWORD_AVAILABLE = False

logger = logging.getLogger("kora.voice.wakeword")

class KoraWakeWord:
    def __init__(self, model="alexa"):
        self.model_name = model
        self.active = False
        self.oww_model = None
        self.ready = False
        
        if OPENWAKEWORD_AVAILABLE:
            try:
                # Defaulting to 'alexa' for now as it's a common default model in openWakeWord
                # In the future, we will use a custom 'kora' model.
                self.oww_model = Model(wakeword_models=[self.model_name])
                logger.info(f"Wake-word engine initialized (models: {self.oww_model.wakeword_models})")
                self.ready = True
            except Exception as e:
                logger.error(f"Failed to initialize openWakeWord Model: {e}")
        else:
            logger.warning("openWakeWord library not available. Using foundation stub.")

    def start(self):
        self.active = True
        logger.info("Wake-word detection enabled.")

    def stop(self):
        self.active = False
        logger.info("Wake-word detection disabled.")

    def detect(self, audio_data: bytes) -> bool:
        """
        Detect wake-word in audio data (expecting 16kHz mono 16-bit PCM).
        Returns True if detected.
        """
        if not self.ready or not self.active or not self.oww_model:
            return False
            
        try:
            # Convert bytes to numpy array
            audio_np = np.frombuffer(audio_data, dtype=np.int16)
            
            # Prediction returns a dict of scores
            prediction = self.oww_model.predict(audio_np)
            
            for mdl, score in prediction.items():
                if score > 0.5:
                    logger.info(f"Wake-word detected: {mdl} (score: {score:.2f})")
                    return True
        except Exception as e:
            logger.error(f"Error during wake-word detection: {e}")
            
        return False

def get_wakeword_status():
    return {
        "engine": "openWakeWord" if OPENWAKEWORD_AVAILABLE else "foundation (missing lib)",
        "ready": OPENWAKEWORD_AVAILABLE,
        "active_models": ["alexa"] # Default for now
    }
