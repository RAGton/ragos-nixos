# =============================================================================
# Kora Voice — Wake-word Detection
# =============================================================================

import logging
import numpy as np

try:
    from openwakeword.model import Model
    OPENWAKEWORD_AVAILABLE = True
except ImportError:
    try:
        from pyopen_wakeword import Model
        OPENWAKEWORD_AVAILABLE = True
    except ImportError:
        OPENWAKEWORD_AVAILABLE = False

logger = logging.getLogger("kora.voice.wakeword")

class KoraWakeWord:
    def __init__(self, model="kora"):
        self.model_name = model
        self.active = False
        self.oww_model = None
        self.ready = False

        if OPENWAKEWORD_AVAILABLE:
            try:
                # Try to use 'kora' model first.
                self.oww_model = Model(wakeword_models=[self.model_name])
                logger.info(f"Wake-word engine initialized (models: {self.oww_model.wakeword_models})")
                self.ready = True
            except Exception as e:
                logger.warning(f"Failed to initialize openWakeWord Model '{self.model_name}': {e}. Falling back to 'hey_mycroft'.")
                try:
                    self.model_name = "hey_mycroft"
                    self.oww_model = Model(wakeword_models=["hey_mycroft"])
                    logger.info(f"Wake-word engine initialized with fallback (models: {self.oww_model.wakeword_models})")
                    self.ready = True
                except Exception as ex:
                    logger.error(f"Fallback also failed: {ex}")
                    logger.info("Wake-word engine falling back to foundation mode (no model found).")
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
    custom_model_present = False
    active_model = "kora"
    if OPENWAKEWORD_AVAILABLE:
        try:
            temp_model = Model(wakeword_models=["kora"])
            custom_model_present = "kora" in temp_model.wakeword_models
        except:
            try:
                temp_model = Model(wakeword_models=["hey_mycroft"])
                custom_model_present = True
                active_model = "hey_mycroft"
            except:
                custom_model_present = False

    return {
        "target_wake_word": active_model,
        "backend": "openWakeWord" if OPENWAKEWORD_AVAILABLE else "foundation (missing lib)",
        "custom_kora_model": "present" if (custom_model_present and active_model == "kora") else ("fallback" if custom_model_present else "missing"),
        "status": "validated" if custom_model_present else "foundation",
        "ready": OPENWAKEWORD_AVAILABLE and custom_model_present,
        "note": "Wake-word configurado como alvo. Usando fallback se kora não for encontrado."
    }


import os
import pyaudio
from pathlib import Path

class PyAudioStreamWrapper:
    """Wrapper that exposes start() and close() methods to match constraints."""
    def __init__(self, engine: "WakeWordEngine") -> None:
        self.engine = engine

    def start(self) -> bool:
        return self.engine.start_stream()

    def close(self) -> None:
        self.engine.close_stream()


class WakeWordEngine:
    """
    Wake-word engine that reads from PyAudio and handles hardware lock checks.
    """
    def __init__(self, model: str = "kora") -> None:
        self.detector = KoraWakeWord(model)
        self.detector.start()
        self.lock_path = Path(f"/run/user/{os.getuid()}/kryonix/voice.lock")
        self.pyaudio = None
        self.active_stream = None
        self.stream = PyAudioStreamWrapper(self)
        
        # Audio configuration
        self.chunk_size = 1280  # ~80ms at 16kHz
        self.rate = 16000
        self.channels = 1
        self.format = pyaudio.paInt16

    def is_locked(self) -> bool:
        return self.lock_path.exists()

    def start_stream(self) -> bool:
        if self.active_stream is not None:
            return True
        if self.pyaudio is None:
            self.pyaudio = pyaudio.PyAudio()
        try:
            self.active_stream = self.pyaudio.open(
                format=self.format,
                channels=self.channels,
                rate=self.rate,
                input=True,
                frames_per_buffer=self.chunk_size
            )
            logger.info("WakeWordEngine: PyAudio stream opened and active.")
            return True
        except Exception as e:
            logger.warning(f"WakeWordEngine: Device busy or failed to open stream: {e}")
            self.active_stream = None
            return False

    def close_stream(self) -> None:
        if self.active_stream is not None:
            try:
                self.active_stream.stop_stream()
                self.active_stream.close()
            except Exception as e:
                logger.warning(f"WakeWordEngine: Error closing stream: {e}")
            finally:
                self.active_stream = None
                logger.info("WakeWordEngine: PyAudio stream closed.")

    def listen(self) -> bool:
        """
        Periodically check lock file.
        If file exists, call stream.close() if stream is open.
        If it does not exist, call stream.start().
        Processes PyAudio chunks and returns True if 'Kora' is detected.
        """
        if self.is_locked():
            if self.active_stream is not None:
                self.stream.close()
            return False

        if self.active_stream is None:
            success = self.stream.start()
            if not success:
                return False

        try:
            data = self.active_stream.read(self.chunk_size, exception_on_overflow=False)
            if self.detector.detect(data):
                return True
        except Exception as e:
            logger.error(f"WakeWordEngine: Error reading chunk: {e}")
            self.stream.close()

        return False

