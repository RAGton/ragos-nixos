# =============================================================================
# Kora Voice — Pipeline
# =============================================================================

import asyncio
import logging
from datetime import datetime
from .recorder import KoraRecorder
from .stt import transcribe_audio
from .tts import speak_text
from ..core.orchestrator import process_message

logger = logging.getLogger("kora.voice.pipeline")

def get_natural_greeting(user: str = "Ragton") -> str:
    """Return a natural greeting based on the time of day."""
    hour = datetime.now().hour
    if 5 <= hour < 12:
        period = "Bom dia"
    elif 12 <= hour < 18:
        period = "Boa tarde"
    else:
        period = "Boa noite"

    if user == "rocha" or user == "Ragton":
        return f"{period}, Ragton. Estou online e pronta para acompanhar você."
    else:
        return f"Olá. Ainda não reconheci sua identidade, mas posso conversar de forma limitada."

async def listen_and_respond(push_to_talk: bool = True, user: str = "rocha"):
    """
    Complete voice loop: record -> STT -> Kora -> TTS.
    """
    recorder = KoraRecorder()

    print("\n" + "=" * 50)
    print(" KORA VOICE — MODO ESCUTA ")
    print("=" * 50)

    # Initial greeting
    greeting = get_natural_greeting(user)
    print(f"Kora: {greeting}")
    speak_text(greeting)

    try:
        while True:
            if push_to_talk:
                input("\n[Pressione ENTER para falar ou Ctrl+C para sair]")
                audio_path = recorder.record_until_keypress("last_input.wav")
            else:
                # Fixed 5s for now if not PTT
                audio_path = recorder.record_to_file("last_input.wav", seconds=5)

            print("... processando áudio ...")
            text = transcribe_audio(audio_path)

            if not text or text.strip() in ["[Erro na transcrição]", ""]:
                continue

            print(f"Você: {text}")

            # Send to Kora
            print("... Kora pensando ...")
            resp = await process_message(text, user=user, mode="auto")
            answer = resp.get("answer", "Sem resposta.")

            print(f"Kora: {answer}")

            # Speak
            speak_text(answer)

    except KeyboardInterrupt:
        print("\n[Encerrando modo voz]")
    except Exception as e:
        logger.error(f"Pipeline error: {e}")
        print(f"\n[Erro fatal no pipeline de voz: {e}]")
