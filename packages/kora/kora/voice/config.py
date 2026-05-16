# =============================================================================
# Kora Voice — Configuration
# =============================================================================

import os
from pathlib import Path

# Backends
KORA_VOICE_STT_BACKEND = os.environ.get("KORA_VOICE_STT_BACKEND", "whisper_cpp")
KORA_VOICE_TTS_BACKEND = os.environ.get("KORA_VOICE_TTS_BACKEND", "piper")

# Directories
KORA_VOICE_TMP_DIR = Path("/tmp/kora-voice")
KORA_VOICE_DATA_DIR = Path("/var/lib/kryonix/kora/voice")

# Models (default paths for NixOS packages)
WHISPER_MODEL_PATH = os.environ.get("WHISPER_MODEL_PATH", "/var/lib/kryonix/kora/models/whisper-base.bin")
PIPER_MODEL_PATH = os.environ.get("PIPER_MODEL_PATH", "/var/lib/kryonix/kora/models/piper-pt_BR.onnx")
PIPER_CONFIG_PATH = os.environ.get("PIPER_CONFIG_PATH", "/var/lib/kryonix/kora/models/piper-pt_BR.onnx.json")

# Safety & Privacy
KORA_VOICE_SAVE_AUDIO = os.environ.get("KORA_VOICE_SAVE_AUDIO", "0") == "1"
KORA_VOICE_REQUIRE_CONSENT_FOR_VOICEPRINT = True

def ensure_voice_dirs():
    """Ensure runtime and data directories exist."""
    KORA_VOICE_TMP_DIR.mkdir(parents=True, exist_ok=True)
    KORA_VOICE_DATA_DIR.mkdir(parents=True, exist_ok=True)
    (KORA_VOICE_DATA_DIR / "profiles").mkdir(parents=True, exist_ok=True)
    (KORA_VOICE_DATA_DIR / "archive").mkdir(parents=True, exist_ok=True)
