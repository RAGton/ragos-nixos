# =============================================================================
# Kora Voice — Identity & Enrollment
# =============================================================================

import os
import json
import logging
from typing import Optional

logger = logging.getLogger("kora.voice.identity")

VOICE_PROFILES_DIR = "/var/lib/kryonix/kora/voice/profiles"

class VoiceIdentityManager:
    def __init__(self, profiles_dir: str = VOICE_PROFILES_DIR):
        self.profiles_dir = profiles_dir
        if not os.path.exists(self.profiles_dir):
            try:
                os.makedirs(self.profiles_dir, mode=0o700, exist_ok=True)
            except PermissionError:
                logger.warning(f"No permission to create {self.profiles_dir}. Using /tmp.")
                self.profiles_dir = "/tmp/kora/voice/profiles"
                os.makedirs(self.profiles_dir, mode=0o700, exist_ok=True)

    def enroll(self, user_id: str):
        """
        Enroll a user's voice.
        In foundation mode, this just creates a metadata file.
        """
        print(f"\n=== Voice Enrollment: {user_id} ===")
        print("POLÍTICA DE PRIVACIDADE E SEGURANÇA:")
        print("- Áudio bruto NÃO é salvo por padrão.")
        print("- Voiceprint (embedding) exige seu consentimento.")
        print("- Voz NÃO é autorização forte para comandos críticos.\n")

        confirm = input("Digite 'CONFIRMO' para iniciar o cadastro de voz: ")
        if confirm.upper() != "CONFIRMO":
            print("Cancelado.")
            return

        print("\nPor favor, diga as seguintes frases claramente:")
        phrases = [
            "Kora, bom dia.",
            "Kora, sou eu, Ragton.",
            "Kora, qual o estado do sistema?",
            "Kora, pode me ouvir?",
            "Kora, iniciar modo assistente."
        ]

        for i, phrase in enumerate(phrases):
            input(f"[{i+1}/{len(phrases)}] Pressione ENTER e diga: '{phrase}'")
            # In foundation mode, we don't actually record/process
            print("... capturado ...")

        # Save foundation profile
        profile_path = os.path.join(self.profiles_dir, f"{user_id}.json")
        profile_data = {
            "user_id": user_id,
            "status": "foundation",
            "samples_collected": len(phrases),
            "embedding_ready": False,
            "created_at": "2026-05-16T00:00:00Z"
        }

        with open(profile_path, "w") as f:
            json.dump(profile_data, f, indent=2)

        print(f"\nCadastro de fundação para '{user_id}' concluído com sucesso!")

    def identify(self, audio_data=None) -> dict:
        """
        Identify speaker from audio data.
        Returns speaker info.
        """
        # Placeholder for real biometric identification
        return {
            "speaker_id": "unknown",
            "display_name": "Visitante",
            "confidence": 0.0,
            "permission_level": "guest"
        }

def get_voice_identity_status():
    return {
        "engine": "foundation",
        "speaker_embeddings": "not_implemented",
        "authorization": "disabled for critical actions",
        "ready": False,
        "note": "Voice Identity está em modo foundation. Identificação biométrica real pendente."
    }
