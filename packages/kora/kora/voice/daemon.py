import asyncio
import contextlib
import json
import logging
import os
import signal
import time
from enum import Enum
from pathlib import Path

from .exceptions import HardwareAccessError, ServiceUnreachable
from .monitor import ping_orchestrator, retry_connection
from .pipeline import listen_and_respond
from .wakeword import WakeWordEngine

logger = logging.getLogger("kora.voice.daemon")


class KoraVoiceState(Enum):
    IDLE = "idle"
    LISTENING = "listening"
    THINKING = "thinking"
    SPEAKING = "speaking"
    MUTED = "muted"
    BLOCKED = "blocked"
    CONFIRMING = "confirming"
    RECONNECTING = "reconnecting"


def setup_voice_logging() -> None:
    log_dir = Path.home() / ".kryonix" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    fh = logging.FileHandler(log_dir / "voice.log", encoding="utf-8")
    fh.setFormatter(fmt)
    fh.setLevel(logging.INFO)

    ch = logging.StreamHandler()
    ch.setFormatter(fmt)
    ch.setLevel(logging.INFO)

    root = logging.getLogger("kora")
    root.setLevel(logging.INFO)
    root.addHandler(fh)
    root.addHandler(ch)


class KoraVoiceDaemon:
    _HEARTBEAT_INTERVAL = 30.0

    def __init__(self) -> None:
        self.state = KoraVoiceState.IDLE
        self.muted = False
        self.running = False
        self.wakeword_engine = WakeWordEngine()
        self._loop: asyncio.AbstractEventLoop | None = None
        self.state_file = Path(f"/run/user/{os.getuid()}/kryonix/voice_state.json")
        self._reconnect_ok: asyncio.Event = asyncio.Event()
        self._heartbeat_task: asyncio.Task | None = None

    # ── State management ────────────────────────────────────────────────────

    def update_state(self, state: KoraVoiceState) -> None:
        if self.state == state:
            return
        self.state = state
        logger.info("State → %s", state.value)
        try:
            self.state_file.parent.mkdir(parents=True, exist_ok=True)
            self.state_file.write_text(json.dumps({
                "state": state.value,
                "muted": self.muted,
                "running": self.running,
                "timestamp": time.time(),
            }))
        except Exception as e:
            logger.warning("Failed to write state file: %s", e)

    # ── Heartbeat ────────────────────────────────────────────────────────────

    async def _heartbeat_cycle(self) -> None:
        """Single health probe. Extracted for testability."""
        healthy = await ping_orchestrator()
        if healthy:
            if self.state == KoraVoiceState.RECONNECTING:
                logger.info("Orchestrator reachable again — resuming normal operation.")
                self._reconnect_ok.set()
                self.update_state(KoraVoiceState.IDLE)
        else:
            if self.state != KoraVoiceState.RECONNECTING:
                logger.warning(
                    "Orchestrator unreachable — entering RECONNECTING state."
                )
            self._reconnect_ok.clear()
            self.update_state(KoraVoiceState.RECONNECTING)

    @retry_connection
    async def _reconnect_probe(self) -> None:
        """Called during RECONNECTING. Retries with exponential backoff until healthy."""
        healthy = await ping_orchestrator()
        if not healthy:
            raise ServiceUnreachable("Orchestrator still unreachable")
        logger.info("Reconnected to orchestrator after outage.")
        self._reconnect_ok.set()
        self.update_state(KoraVoiceState.IDLE)

    async def _heartbeat_loop(self) -> None:
        """Background task: probes every HEARTBEAT_INTERVAL; uses backoff in RECONNECTING."""
        while self.running:
            try:
                if self.state == KoraVoiceState.RECONNECTING:
                    await self._reconnect_probe()
                else:
                    await asyncio.sleep(self._HEARTBEAT_INTERVAL)
                    await self._heartbeat_cycle()
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.error("Heartbeat loop error: %s", e)
                await asyncio.sleep(5.0)

    # ── Interaction trigger ──────────────────────────────────────────────────

    async def handle_trigger(self) -> None:
        if self.state == KoraVoiceState.RECONNECTING:
            logger.warning("Wake-word trigger skipped — daemon in RECONNECTING state.")
            return

        self.update_state(KoraVoiceState.LISTENING)
        logger.info("Wake-word triggered — starting interaction.")
        try:
            self.wakeword_engine.stream.close()
            await listen_and_respond(push_to_talk=False, single_turn=True)
        except (OSError, IOError) as e:
            logger.error("Audio hardware error: %s", e)
            raise HardwareAccessError(str(e)) from e
        except Exception as e:
            logger.error("Interaction error: %s", e)
        finally:
            if self.state != KoraVoiceState.RECONNECTING:
                self.update_state(KoraVoiceState.IDLE)

    # ── Main loop ────────────────────────────────────────────────────────────

    async def start(self) -> None:
        self.running = True
        self._loop = asyncio.get_running_loop()
        self._reconnect_ok.set()  # Assume healthy at startup

        self._heartbeat_task = asyncio.create_task(
            self._heartbeat_loop(), name="kora-voice-heartbeat"
        )
        self.update_state(KoraVoiceState.IDLE)
        logger.info("Kora Voice Daemon: loop started.")

        last_log_time = 0.0
        try:
            while self.running:
                mute_file = Path("/var/lib/kryonix/kora/voice/muted")
                self.muted = mute_file.exists()

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

                if self.state == KoraVoiceState.RECONNECTING:
                    # Audio processing paused — heartbeat task handles reconnection.
                    self.wakeword_engine.stream.close()
                    await asyncio.sleep(1.0)
                    continue

                if self.state == KoraVoiceState.IDLE:
                    now = time.monotonic()
                    if now - last_log_time > 15.0:
                        logger.info("Kora aguardando ativação...")
                        last_log_time = now

                    detected = await self._loop.run_in_executor(
                        None, self.wakeword_engine.listen
                    )
                    if detected:
                        asyncio.create_task(self.handle_trigger())

                await asyncio.sleep(0.02)

        except asyncio.CancelledError:
            logger.info("Daemon main loop cancelled.")
        finally:
            await self._shutdown()

    async def _shutdown(self) -> None:
        """Cancel background tasks and release audio hardware."""
        if self._heartbeat_task and not self._heartbeat_task.done():
            self._heartbeat_task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await self._heartbeat_task
        self.wakeword_engine.stream.close()
        logger.info("Kora Voice Daemon: stopped.")

    def stop(self, *args) -> None:
        """Signal-safe stop: schedules cleanup without blocking the loop."""
        logger.info("Stop requested (signal received).")
        self.running = False
        if self._heartbeat_task and not self._heartbeat_task.done():
            self._heartbeat_task.cancel()
        self.wakeword_engine.stream.close()

    def get_status(self) -> dict:
        return {
            "state": self.state.value,
            "muted": self.muted,
            "running": self.running,
        }


async def run_daemon() -> None:
    setup_voice_logging()
    daemon = KoraVoiceDaemon()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, daemon.stop)
        except NotImplementedError:
            pass

    await daemon.start()
