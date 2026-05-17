# =============================================================================
# Kora Voice — Pipeline
#
# Loop principal de interação por voz:
#   record → STT → Kora Orchestrator → TTS
# Inclui memória de conversa, animação de pensando e UX melhorada.
# =============================================================================

import asyncio
import logging
import os
import sys
import threading
import time
from datetime import datetime
from pathlib import Path

from .recorder import KoraRecorder
from .stt import transcribe_audio
from .tts import speak_text
from .vad import record_with_vad
from .signals import play_wake, play_thinking, play_done, play_error
from ..core.orchestrator import process_message
from ..core.conversation import append_turn, detect_followup_complaint

logger = logging.getLogger("kora.voice.pipeline")

# ── Terminal UX helpers ──────────────────────────────────────────────────────

# Box-drawing characters
_H = "─"
_TL, _TR, _BL, _BR = "╭", "╮", "╰", "╯"
_V = "│"
_WIDTH = 56

# Thinking animation frames
_THINK_FRAMES = [
    ("⠋", "⟡"), ("⠙", "✦"), ("⠹", "✧"),
    ("⠸", "⟡"), ("⠼", "✦"), ("⠴", "✧"),
    ("⠦", "⟡"), ("⠧", "✦"), ("⠇", "✧"), ("⠏", "⟡"),
]


def _box(label: str, text: str, color_code: str = "36") -> None:
    """Print text in a styled box."""
    lines = text.split("\n")
    inner_w = _WIDTH - 4  # padding inside box

    print(f"\033[{color_code}m{_TL}{_H} {label} {_H * (_WIDTH - len(label) - 4)}{_TR}\033[0m")
    for line in lines:
        # word-wrap long lines
        while len(line) > inner_w:
            print(f"\033[{color_code}m{_V}\033[0m {line[:inner_w]} \033[{color_code}m{_V}\033[0m")
            line = line[inner_w:]
        padding = " " * (inner_w - len(line))
        print(f"\033[{color_code}m{_V}\033[0m {line}{padding} \033[{color_code}m{_V}\033[0m")
    print(f"\033[{color_code}m{_BL}{_H * (_WIDTH - 2)}{_BR}\033[0m")


class _ThinkingAnimation:
    """Spinner animation that runs in a background thread."""

    def __init__(self):
        self._running = False
        self._thread = None
        self._start_time = 0.0

    def start(self):
        self._running = True
        self._start_time = time.monotonic()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=1)
        # Clear the line
        sys.stdout.write("\r" + " " * 60 + "\r")
        sys.stdout.flush()

    def _loop(self):
        idx = 0
        while self._running:
            elapsed = time.monotonic() - self._start_time
            frame_spinner, frame_star = _THINK_FRAMES[idx % len(_THINK_FRAMES)]
            sys.stdout.write(
                f"\r  \033[35mKora pensando {frame_spinner}{frame_star}\033[0m "
                f"\033[2m{elapsed:.1f}s\033[0m"
            )
            sys.stdout.flush()
            idx += 1
            time.sleep(0.12)


def get_natural_greeting(user: str = "Ragton") -> str:
    """Return a natural greeting based on the time of day."""
    hour = datetime.now().hour
    if 5 <= hour < 12:
        period = "Bom dia"
    elif 12 <= hour < 18:
        period = "Boa tarde"
    else:
        period = "Boa noite"

    if user in ("rocha", "Ragton"):
        return f"{period}, Ragton. Estou online e pronta para acompanhar você."
    else:
        return "Olá. Ainda não reconheci sua identidade, mas posso conversar de forma limitada."


async def listen_and_respond(push_to_talk: bool = True, user: str = "rocha"):
    """
    Complete voice loop: record → STT → Kora → TTS.
    Persists conversation turns for context.
    """
    from .config import KORA_VOICE_TMP_DIR, ensure_voice_dirs
    ensure_voice_dirs()

    recorder = KoraRecorder()

    print()
    print(f"\033[35m{'═' * _WIDTH}\033[0m")
    print(f"\033[35m{'':>14}KORA VOICE — MODO ESCUTA\033[0m")
    if push_to_talk:
        print(f"\033[2m{'':>16}Push-to-Talk (ENTER)\033[0m")
    else:
        print(f"\033[2m{'':>12}VAD — para após 1s silêncio\033[0m")
    print(f"\033[35m{'═' * _WIDTH}\033[0m")

    # Initial greeting
    greeting = get_natural_greeting(user)
    _box("Kora", greeting, "35")
    speak_text(greeting)

    try:
        while True:
            if push_to_talk:
                print(f"\n  \033[2m[Pressione ENTER para falar ou Ctrl+C para sair]\033[0m")
                input()
                print("  \033[33m🎙 Gravando... (ENTER para parar)\033[0m")
                audio_path = recorder.record_until_keypress("last_input.wav")
            else:
                # VAD mode — records until 1s of silence
                print(f"\n  \033[2m[Fale a qualquer momento ou Ctrl+C para sair]\033[0m")
                play_wake()
                print("  \033[33m🎙 Ouvindo...\033[0m")
                audio_path, duration = record_with_vad(
                    KORA_VOICE_TMP_DIR / "last_input.wav"
                )

            print("  \033[2m... processando áudio ...\033[0m")
            text = transcribe_audio(audio_path)

            if not text or text.strip() in ["[Erro na transcrição]", ""]:
                print("  \033[2m(nenhuma fala detectada)\033[0m")
                continue

            # Show user input
            _box("Você", text.strip(), "36")

            # Detect followup complaint
            if detect_followup_complaint(text):
                logger.info("Followup complaint detected — injecting recovery context")

            # Thinking animation + signal
            play_thinking()
            spinner = _ThinkingAnimation()
            spinner.start()

            try:
                resp = await process_message(
                    text, user=user, mode="auto", is_voice=True
                )
            finally:
                spinner.stop()

            answer = resp.get("answer", "Sem resposta.")
            elapsed = resp.get("elapsed_sec", 0)
            mode_used = resp.get("mode", "?")

            play_done()

            # Show Kora response
            _box("Kora", answer, "35")
            print(f"  \033[2m[{mode_used} | {elapsed:.1f}s]\033[0m")

            # Save conversation turn
            append_turn(
                user_text=text.strip(),
                assistant_text=answer,
                speaker=user,
                metadata={"mode": mode_used, "elapsed": elapsed},
            )

            # Speak
            speak_text(answer)

    except KeyboardInterrupt:
        print(f"\n  \033[2m[Encerrando modo voz — até mais, Ragton.]\033[0m\n")
    except asyncio.CancelledError:
        print(f"\n  \033[2m[Operação cancelada]\033[0m\n")
    except Exception as e:
        play_error()
        logger.error(f"Pipeline error: {e}")
        print(f"\n  \033[31m[Erro fatal no pipeline de voz: {e}]\033[0m\n")
