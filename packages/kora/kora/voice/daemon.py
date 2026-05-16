# =============================================================================
# Kora Voice — Daemon
# =============================================================================

import asyncio
import logging
import signal
import pyaudio
from enum import Enum
from .recorder import KoraRecorder
from .wakeword import KoraWakeWord
from .pipeline import listen_and_respond, get_natural_greeting
from .tts import speak_text

logger = logging.getLogger("kora.voice.daemon")

class KoraVoiceState(Enum):
    IDLE = "idle"
    LISTENING = "listening"
    THINKING = "thinking"
    SPEAKING = "speaking"
    MUTED = "muted"
    BLOCKED = "blocked"
    CONFIRMING = "confirming"

class KoraVoiceDaemon:
    def __init__(self):
        self.state = KoraVoiceState.IDLE
        self.muted = False
        self.running = False
        self.wakeword = KoraWakeWord()
        self._loop = None

    async def handle_trigger(self):
        """Handle wake-word detection trigger."""
        self.state = KoraVoiceState.LISTENING
        logger.info("Wake-word triggered! Starting interaction...")

        # In a real daemon, we might want to play a small sound here
        try:
            # We call the pipeline, but we need to ensure it doesn't block the daemon forever
            # For now, it will run one interaction loop
            await listen_and_respond(push_to_talk=False)
        except Exception as e:
            logger.error(f"Error in triggered interaction: {e}")
        finally:
            self.state = KoraVoiceState.IDLE

    async def start(self):
        """Start the background listener daemon."""
        self.running = True
        self.wakeword.start()
        self._loop = asyncio.get_running_loop()

        # Audio parameters (openWakeWord likes 16kHz mono 16-bit PCM)
        FORMAT = pyaudio.paInt16
        CHANNELS = 1
        RATE = 16000
        CHUNK = 1280 # ~80ms chunks

        try:
            audio = pyaudio.PyAudio()
            stream = audio.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)
            logger.info("Kora Voice Daemon: Audio stream opened.")
        except Exception as e:
            logger.error(f"Failed to open audio stream: {e}")
            self.running = False
            return

        logger.info("Kora Voice Daemon: Loop started.")

        try:
            while self.running:
                if self.muted:
                    self.state = KoraVoiceState.MUTED
                    await asyncio.sleep(0.5)
                    continue

                if self.state == KoraVoiceState.IDLE:
                    # Read audio chunk
                    try:
                        # Use a separate thread for blocking read if necessary,
                        # but for 80ms chunks, it's usually fine in a tight loop
                        data = await self._loop.run_in_executor(None, stream.read, CHUNK, False)

                        if self.wakeword.detect(data):
                            # Trigger!
                            asyncio.create_task(self.handle_trigger())
                    except Exception as e:
                        logger.error(f"Error reading audio stream: {e}")
                        await asyncio.sleep(1)

                await asyncio.sleep(0.01) # Yield to other tasks
        finally:
            stream.stop_stream()
            stream.close()
            audio.terminate()
            logger.info("Kora Voice Daemon: Stopped.")

    def stop(self):
        self.running = False

    def mute(self):
        self.muted = True
        self.state = KoraVoiceState.MUTED
        logger.info("Microphone muted.")

    def unmute(self):
        self.muted = False
        self.state = KoraVoiceState.IDLE
        logger.info("Microphone unmuted.")

    def get_status(self):
        return {
            "state": self.state.value,
            "muted": self.muted,
            "running": self.running
        }

async def run_daemon():
    daemon = KoraVoiceDaemon()

    # Handle signals
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, daemon.stop)

    await daemon.start()
