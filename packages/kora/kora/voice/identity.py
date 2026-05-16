# =============================================================================
# Kora Voice — Identity Foundation
# =============================================================================

from dataclasses import dataclass
from typing import Optional

@dataclass
class SpeakerProfile:
    speaker_id: str
    display_name: str
    permission_level: str
    voiceprint_path: Optional[str] = None
    consent: bool = False
    created_at: str = ""

def get_voice_identity_status():
    """Return status of voice identity system."""
    return {
        "active": False,
        "mode": "foundation",
        "supported": ["enrollment", "identification (planned)"],
        "note": "Voice identity enrollment ainda está em modo foundation. Nenhum comando crítico será autorizado por voz."
    }

def enroll_speaker(speaker_id: str):
    """Placeholder for enrolling a new speaker."""
    return f"Iniciando enrollment para {speaker_id}. (Stub)"
