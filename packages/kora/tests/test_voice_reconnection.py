"""
Tests for VoiceDaemon reconnection resilience.

Verifies that the daemon:
- Enters RECONNECTING when the orchestrator is unreachable.
- Returns to IDLE when the orchestrator becomes reachable again.
- Skips audio processing while in RECONNECTING.
- Cleans up properly on stop().
"""
import asyncio
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

# Patch hardware layer before importing the daemon module.
_ENGINE_PATH = "kora.voice.daemon.WakeWordEngine"


def _make_daemon():
    """Return a KoraVoiceDaemon with hardware dependencies mocked."""
    with patch(_ENGINE_PATH) as mock_cls:
        mock_engine = MagicMock()
        mock_engine.is_locked.return_value = False
        mock_engine.stream = MagicMock()
        mock_cls.return_value = mock_engine
        from kora.voice.daemon import KoraVoiceDaemon
        daemon = KoraVoiceDaemon()
    return daemon


class TestHeartbeatCycle(unittest.TestCase):
    """Unit tests for _heartbeat_cycle (single-shot probe, no retry)."""

    def test_enters_reconnecting_when_ping_fails(self):
        """Daemon must switch to RECONNECTING when orchestrator ping returns False."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon._reconnect_ok.set()  # Start as healthy

        async def run():
            with patch("kora.voice.daemon.ping_orchestrator", AsyncMock(return_value=False)):
                await daemon._heartbeat_cycle()

        asyncio.run(run())

        self.assertEqual(daemon.state, KoraVoiceState.RECONNECTING)
        self.assertFalse(daemon._reconnect_ok.is_set())

    def test_exits_reconnecting_when_ping_succeeds(self):
        """Daemon must return to IDLE from RECONNECTING once orchestrator responds."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon.state = KoraVoiceState.RECONNECTING
        daemon._reconnect_ok.clear()

        async def run():
            with patch("kora.voice.daemon.ping_orchestrator", AsyncMock(return_value=True)):
                await daemon._heartbeat_cycle()

        asyncio.run(run())

        self.assertEqual(daemon.state, KoraVoiceState.IDLE)
        self.assertTrue(daemon._reconnect_ok.is_set())

    def test_stays_reconnecting_on_consecutive_failures(self):
        """State must remain RECONNECTING across multiple failed probes."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon.state = KoraVoiceState.RECONNECTING
        daemon._reconnect_ok.clear()

        async def run():
            with patch("kora.voice.daemon.ping_orchestrator", AsyncMock(return_value=False)):
                await daemon._heartbeat_cycle()
                await daemon._heartbeat_cycle()

        asyncio.run(run())

        self.assertEqual(daemon.state, KoraVoiceState.RECONNECTING)


class TestHandleTrigger(unittest.TestCase):
    """Unit tests for handle_trigger gate during RECONNECTING state."""

    def test_skips_interaction_when_reconnecting(self):
        """handle_trigger must not invoke listen_and_respond in RECONNECTING state."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon.state = KoraVoiceState.RECONNECTING

        with patch("kora.voice.daemon.listen_and_respond", AsyncMock()) as mock_listen:
            asyncio.run(daemon.handle_trigger())
            mock_listen.assert_not_called()

        self.assertEqual(daemon.state, KoraVoiceState.RECONNECTING)

    def test_proceeds_when_idle(self):
        """handle_trigger must invoke listen_and_respond when in IDLE state."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon.state = KoraVoiceState.IDLE

        with patch("kora.voice.daemon.listen_and_respond", AsyncMock()) as mock_listen:
            asyncio.run(daemon.handle_trigger())
            mock_listen.assert_called_once()


class TestStop(unittest.TestCase):
    """Unit tests for graceful stop and signal handling."""

    def test_stop_sets_running_false(self):
        daemon = _make_daemon()
        daemon.running = True
        daemon.stop()
        self.assertFalse(daemon.running)

    def test_stop_cancels_heartbeat_task(self):
        daemon = _make_daemon()
        daemon.running = True

        mock_task = MagicMock(spec=asyncio.Task)
        mock_task.done.return_value = False
        daemon._heartbeat_task = mock_task

        daemon.stop()

        mock_task.cancel.assert_called_once()

    def test_stop_closes_audio_stream(self):
        daemon = _make_daemon()
        daemon.running = True
        daemon.stop()
        daemon.wakeword_engine.stream.close.assert_called()


class TestReconnectProbe(unittest.TestCase):
    """Integration-style test for _reconnect_probe with retry logic."""

    def test_probe_succeeds_and_restores_idle(self):
        """_reconnect_probe must set IDLE state when ping eventually returns True."""
        from kora.voice.daemon import KoraVoiceState

        daemon = _make_daemon()
        daemon.state = KoraVoiceState.RECONNECTING
        daemon._reconnect_ok.clear()

        async def run():
            # Ping fails twice, then succeeds — exercising the backoff path.
            call_count = 0

            async def flaky_ping(*_args, **_kwargs):
                nonlocal call_count
                call_count += 1
                return call_count >= 3

            # Override asyncio.sleep to avoid real delays during retries.
            with patch("kora.voice.daemon.ping_orchestrator", flaky_ping):
                with patch("asyncio.sleep", AsyncMock()):
                    await daemon._reconnect_probe()

            return call_count

        calls = asyncio.run(run())

        self.assertEqual(daemon.state, KoraVoiceState.IDLE)
        self.assertTrue(daemon._reconnect_ok.is_set())
        self.assertEqual(calls, 3)


if __name__ == "__main__":
    unittest.main()
