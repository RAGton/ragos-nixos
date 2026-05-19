# =============================================================================
# Kora Voice — STT (Speech to Text)
# =============================================================================

import os
import logging
from pathlib import Path
import numpy as np

logger = logging.getLogger("kora.voice.stt")

# Singleton instance for the Whisper model
_whisper_model_instance = None

def get_whisper_model():
    """
    Singleton loader for faster-whisper WhisperModel.
    Initializes model on CUDA with float16 to keep VRAM < 2GB (approx 400MB),
    falling back to CPU int8 if CUDA is unavailable.
    """
    global _whisper_model_instance
    if _whisper_model_instance is None:
        try:
            from faster_whisper import WhisperModel
            # Attempt CUDA float16 first (fastest, lowest GPU memory footprint)
            logger.info("Inicializando faster-whisper em CUDA (float16)...")
            _whisper_model_instance = WhisperModel(
                "base",
                device="cuda",
                compute_type="float16"
            )
            logger.info("faster-whisper carregado com sucesso em GPU CUDA.")
        except Exception as e:
            logger.warning(
                f"Falha ao carregar faster-whisper com aceleração CUDA: {e}. "
                "Tentando carregar em CPU (int8)..."
            )
            try:
                from faster_whisper import WhisperModel
                _whisper_model_instance = WhisperModel(
                    "base",
                    device="cpu",
                    compute_type="int8"
                )
                logger.info("faster-whisper carregado com sucesso em CPU.")
            except Exception as cpu_err:
                logger.error(f"Erro fatal: não foi possível carregar o WhisperModel: {cpu_err}")
                _whisper_model_instance = None
    return _whisper_model_instance


def transcribe_audio(audio_buffer, user: str = "rocha") -> str:
    """
    Transcribe audio from a buffer (bytes, numpy array, or file path/str) using faster-whisper.
    """
    model = get_whisper_model()
    if model is None:
        logger.error("WhisperModel não está disponível. Transcrição cancelada.")
        return "[Erro: WhisperModel não carregado]"

    # Resolve input audio
    if isinstance(audio_buffer, (str, Path)):
        audio_path = Path(audio_buffer)
        if not audio_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        audio_input = str(audio_path)
    elif isinstance(audio_buffer, bytes):
        # Convert raw 16-bit PCM bytes to normalized float32 numpy array
        audio_input = np.frombuffer(audio_buffer, dtype=np.int16).astype(np.float32) / 32768.0
    elif isinstance(audio_buffer, np.ndarray):
        if audio_buffer.dtype == np.int16:
            audio_input = audio_buffer.astype(np.float32) / 32768.0
        else:
            audio_input = audio_buffer
    else:
        raise TypeError("Tipo de buffer de áudio não suportado")

    try:
        # Prime Whisper's vocabulary dynamically using user's active learning profile
        prompt_words = [
            "Kora", "Kryonix", "Hyprland", "NixOS", "Inspiron", "Glacier", "Ragton",
            "terminal", "CLI", "systemd", "Caelestia"
        ]
        if user:
            try:
                from kora.core.learning import LearningEngine
                engine = LearningEngine()
                profile = engine.get_profile(user)
                if profile.get("technical_vocabulary"):
                    prompt_words.extend(profile["technical_vocabulary"])
                if profile.get("active_projects"):
                    prompt_words.extend(profile["active_projects"])
                if profile.get("spelling_mappings"):
                    prompt_words.extend(profile["spelling_mappings"].values())
            except Exception as pe:
                logger.warning(f"Erro ao ler perfil para Whisper prompt: {pe}")

        # Deduplicate and format prompt
        unique_words = []
        for w in prompt_words:
            if w and w not in unique_words:
                unique_words.append(w)
        prompt_str = ", ".join(unique_words) + "."

        # Transcribe with faster-whisper
        # Using beam_size=5 for accuracy, language='pt' for Portuguese
        segments, info = model.transcribe(
            audio_input,
            language="pt",
            beam_size=5,
            initial_prompt=prompt_str
        )

        text = " ".join([segment.text for segment in segments]).strip()

        # Apply normalizer
        try:
            from kora.core.normalizer import normalize_text
            text = normalize_text(text, user).normalized
        except Exception as norm_err:
            logger.warning(f"Erro ao normalizar transcricao: {norm_err}")

        logger.info(f"STT: {text}")
        return text

    except Exception as e:
        logger.error(f"STT failed: {e}")
        return "[Erro na transcrição]"
