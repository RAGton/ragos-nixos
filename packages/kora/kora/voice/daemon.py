# =============================================================================
# Kora Voice — Daemon
# =============================================================================

import asyncio
import logging
import signal
from enum import Enum
from .recorder import KoraRecorder
from .wakeword import KoraWakeWord
from .pipeline import listen_and_respond

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

    async def start(self):
        """Start the background listener daemon."""
        self.running = True
        logger.info("Kora Voice Daemon started.")
        
        while self.running:
            if self.muted:
                self.state = KoraVoiceState.MUTED
                await asyncio.sleep(1)
                continue

            self.state = KoraVoiceState.IDLE
            # In V2 foundation, we loop listening tasks
            # real wake-word detection would go here
            try:
                # Placeholder: for now we don't start the loop automatically
                # to avoid unexpected microphone usage.
                await asyncio.sleep(5) 
            except asyncio.CancelledError:
                break
        
        logger.info("Kora Voice Daemon stopped.")

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
