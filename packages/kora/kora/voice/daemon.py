# =============================================================================
# Kora Voice — Daemon
# =============================================================================

import os
import time
import json
import asyncio
import logging
import signal
from enum import Enum
from pathlib import Path

from .wakeword import WakeWordEngine
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


def setup_voice_logging() -> None:
    """Configures daemon logging to write specifically to ~/.kryonix/logs/voice.log"""
    log_dir = Path.home() / ".kryonix" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "voice.log"

    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    
    file_handler = logging.FileHandler(log_file, encoding="utf-8")
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)
    
    # Configure the logger for 'kora' package
    root_logger = logging.getLogger("kora")
    root_logger.setLevel(logging.INFO)
    root_logger.addHandler(file_handler)
    
    # Console logging as fallback
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    console_handler.setLevel(logging.INFO)
    root_logger.addHandler(console_handler)


class KoraVoiceDaemon:
    def __init__(self) -> None:
        self.state = KoraVoiceState.IDLE
        self.muted = False
        self.running = False
        self.wakeword_engine = WakeWordEngine()
        self._loop = None
        self.state_file = Path(f"/run/user/{os.getuid()}/kryonix/voice_state.json")

    def update_state(self, state: KoraVoiceState) -> None:
        if self.state != state:
            self.state = state
            logger.info(f"State transition to: {state.value}")
            try:
                self.state_file.parent.mkdir(parents=True, exist_ok=True)
                state_data = {
                    "state": state.value,
                    "muted": self.muted,
                    "running": self.running,
                    "timestamp": time.time()
                }
                self.state_file.write_text(json.dumps(state_data))
            except Exception as e:
                logger.warning(f"Failed to write state file: {e}")

    async def handle_trigger(self) -> None:
        """Handle wake-word detection trigger."""
        self.update_state(KoraVoiceState.LISTENING)
        logger.info("Wake-word triggered! Starting interaction...")

        try:
            # Safely close the engine's stream so the recorder can open it
            self.wakeword_engine.stream.close()
            
            # We call the pipeline, ensuring it runs one interaction loop
            await listen_and_respond(push_to_talk=False, single_turn=True)
        except Exception as e:
            logger.error(f"Error in triggered interaction: {e}")
        finally:
            self.update_state(KoraVoiceState.IDLE)

    async def start(self) -> None:
        """Start the background listener daemon."""
        self.running = True
        self._loop = asyncio.get_running_loop()
        
        self.update_state(KoraVoiceState.IDLE)
        logger.info("Kora Voice Daemon: Loop started.")
        
        last_log_time = 0.0

        try:
            while self.running:
                # Check for mute status file `/var/lib/kryonix/kora/voice/muted`
                mute_file = Path("/var/lib/kryonix/kora/voice/muted")
                if mute_file.exists():
                    self.muted = True
                else:
                    self.muted = False

                if self.muted:
                    self.update_state(KoraVoiceState.MUTED)
                    self.wakeword_engine.stream.close()
                    await asyncio.sleep(0.5)
                    continue

                if self.wakeword_engine.is_locked():
                    self.update_state(KoraVoiceState.BLOCKED)
                    self.wakeword_engine.stream.close()
                    await asyncio.sleep(0.5)
                    continue

                if self.state == KoraVoiceState.IDLE:
                    self.update_state(KoraVoiceState.IDLE)
                    
                    # Log periodic status
                    now = time.monotonic()
                    if now - last_log_time > 15.0:
                        logger.info("Kora aguardando ativação...")
                        last_log_time = now

                    # Run blocking listen in executor to keep CPU usage low and avoid starvation
                    detected = await self._loop.run_in_executor(
                        None, self.wakeword_engine.listen
                    )

                    if detected:
                        asyncio.create_task(self.handle_trigger())

                # Small sleep to prevent tight-loop CPU spike
                await asyncio.sleep(0.02)
        finally:
            self.wakeword_engine.stream.close()
            logger.info("Kora Voice Daemon: Stopped.")

    def stop(self, *args) -> None:
        self.running = False

    def get_status(self) -> dict:
        return {
            "state": self.state.value,
            "muted": self.muted,
            "running": self.running
        }


async def run_daemon() -> None:
    setup_voice_logging()
    daemon = KoraVoiceDaemon()

    # Handle signals
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, daemon.stop)
        except NotImplementedError:
            # Fallback for platforms where signal handlers aren't fully supported in asyncio
            pass

    await daemon.start()
