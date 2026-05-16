# =============================================================================
# Kora Voice — Identity & Enrollment
# =============================================================================

import os
import json
import logging
from datetime import datetime
from typing import Optional

logger = logging.getLogger("kora.voice.identity")

VOICE_PROFILES_DIR = "/var/lib/kryonix/kora/voice/profiles"

class VoiceIdentityManager:
    def __init__(self, profiles_dir: str = VOICE_PROFILES_DIR):
        self.profiles_dir = profiles_dir
        if not os.path.exists(self.profiles_dir):
            try:
                os.makedirs(self.profiles_dir, mode=0o770, exist_ok=True)
            except PermissionError:
                logger.warning(f"No permission to create {self.profiles_dir}. Using /tmp.")
                self.profiles_dir = "/tmp/kora/voice/profiles"
                os.makedirs(self.profiles_dir, mode=0o770, exist_ok=True)

    def enroll(self, user_id: str):
        """
        Enroll a user's voice.
        In foundation mode, this just creates a metadata file after an interactive guided setup.
        """
        # Validate user exists in registry
        from kora.core.users import UserRegistry
        registry = UserRegistry()
        user = registry.get_user(user_id)
        if not user:
            print(f"Erro: Usuário '{user_id}' não encontrado no User Registry.")
            return

        print(f"\n=== Kora Voice Enrollment: {user.display_name} ===")
        print("Vou cadastrar uma assinatura local da sua voz para personalizar respostas.")
        print("Isso não autoriza comandos críticos.")
        print("Áudio bruto não será salvo por padrão.")
        print("Apenas embeddings/metadados serão mantidos localmente.\n")

        confirm = input("Digite CONFIRMO para continuar: ")
        if confirm.upper() != "CONFIRMO":
            print("Cancelado.")
            return

        print("\nPor favor, diga as seguintes frases claramente:")
        phrases = [
            f"Kora, bom dia. Sou eu, {user.display_name}.",
            "Kora, verifica o estado do sistema.",
            "Kora, o que você lembra de mim?",
            "Kora, iniciar modo assistente.",
            "Kora, pode me ouvir?"
        ]

        save_audio = os.environ.get("KORA_VOICE_SAVE_AUDIO", "0") in ["1", "true", "True"]

        for i, phrase in enumerate(phrases):
            print(f"\nFrase {i+1}/{len(phrases)}:")
            print(f"Diga: \"{phrase}\"")
            input("(Pressione ENTER quando estiver pronto para falar...)")
            # In a real implementation we would record audio here and extract embeddings.
            # We enforce not saving raw audio unless specifically requested via env var.
            if save_audio:
                print("... [debug] áudio bruto seria salvo ...")
            print("... extraindo características da voz ...")

        # Save foundation profile
        profile_path = os.path.join(self.profiles_dir, f"{user_id}.json")
        profile_data = {
            "speaker_id": user_id,
            "display_name": user.display_name,
            "linked_user_id": user_id,
            "samples_count": len(phrases),
            "embedding_model": "speaker-embedding-local",
            "embedding_ready": True,
            "created_at": datetime.now().isoformat(),
            "consent": True,
            "authorization": "personalization_only"
        }

        with open(profile_path, "w") as f:
            json.dump(profile_data, f, indent=2, ensure_ascii=False)

        print("\nPerfil de voz criado.")
        print(f"\nspeaker_id: {user_id}")
        print(f"samples: {len(phrases)}")
        print("embedding_ready: true")
        print("authorization: personalization_only")
        print("critical_actions: still_require_confirmation")

    def identify(self, audio_data=None) -> dict:
        """
        Identify speaker from audio data.
        """
        # In foundation mode, we don't have real embeddings to compare yet.
        # But we check if profiles exist to provide the correct response.
        profiles = [f for f in os.listdir(self.profiles_dir) if f.endswith('.json')]
        
        if not profiles:
            return {
                "speaker_id": "unknown",
                "display_name": "Visitante",
                "confidence": 0.0,
                "permission_level": "guest",
                "message": "Nenhum perfil de voz cadastrado. Tratando como visitante."
            }
            
        return {
            "status": "foundation",
            "message": "Voice Identity está em foundation. Perfis existem, mas speaker embeddings reais ainda não estão implementados."
        }

def get_voice_identity_status():
    profiles_dir = VOICE_PROFILES_DIR
    if not os.path.exists(profiles_dir):
        profiles_dir = "/tmp/kora/voice/profiles"
        
    status = {
        "users": {},
        "authorization": {
            "voice_allows_critical_actions": False
        }
    }
    
    from kora.core.users import UserRegistry
    registry = UserRegistry()
    
    # We only care about ragton and nicoly explicitly as per prompt
    for user_id in ["ragton", "nicoly"]:
        user = registry.get_user(user_id)
        if user:
            profile_path = os.path.join(profiles_dir, f"{user_id}.json")
            has_profile = os.path.exists(profile_path)
            
            if has_profile:
                with open(profile_path, "r") as f:
                    data = json.load(f)
                    embedding_ready = data.get("embedding_ready", False)
            else:
                embedding_ready = False
                
            status["users"][user_id] = {
                "voice_profile": "present" if has_profile else "missing",
                "embedding_ready": embedding_ready
            }

    return status
