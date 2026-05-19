import os
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from kora.utils.lock import HardwareLock
from kora.voice.wakeword import WakeWordEngine


def test_hardware_lock_lifecycle():
    # Force HardwareLock to use a temporary path for testing
    with patch("kora.utils.lock.os.getuid", return_value=9999):
        # The path should resolve to /run/user/9999/kryonix/voice.lock
        # But /run/user/9999 might not exist or be writable in test environment.
        # So we patch the lock_path directly to point to a temp file.
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_lock = Path(tmpdir) / "voice.lock"
            
            with patch.object(HardwareLock, "__init__", lambda self: setattr(self, "lock_path", temp_lock)):
                assert not temp_lock.exists()
                
                with HardwareLock() as lock:
                    assert temp_lock.exists()
                    # Content should be current PID
                    pid_content = temp_lock.read_text()
                    assert pid_content == str(os.getpid())
                
                assert not temp_lock.exists()


def test_wakeword_engine_locking_closes_stream():
    with tempfile.TemporaryDirectory() as tmpdir:
        temp_lock = Path(tmpdir) / "voice.lock"
        
        # Patch dependencies so we don't open real pyaudio streams or load heavy openwakeword models
        with patch("kora.voice.wakeword.pyaudio.PyAudio") as mock_pyaudio_class, \
             patch("kora.voice.wakeword.KoraWakeWord") as mock_wakeword_class, \
             patch("kora.voice.wakeword.os.getuid", return_value=9999):
            
            engine = WakeWordEngine()
            engine.lock_path = temp_lock
            
            # Setup mock stream
            mock_stream = MagicMock()
            engine.active_stream = mock_stream
            
            # 1. Test is_locked when lock file doesn't exist
            assert not engine.is_locked()
            
            # 2. Test is_locked and stream closure when lock file exists
            temp_lock.touch()
            assert engine.is_locked()
            
            # Call listen() while locked
            result = engine.listen()
            assert result is False
            # The active stream should have been closed/released
            assert engine.active_stream is None
            mock_stream.stop_stream.assert_called_once()
            mock_stream.close.assert_called_once()


def test_wakeword_engine_opens_stream_when_not_locked():
    with patch("kora.voice.wakeword.pyaudio.PyAudio") as mock_pyaudio_class, \
         patch("kora.voice.wakeword.KoraWakeWord") as mock_wakeword_class, \
         patch("kora.voice.wakeword.os.getuid", return_value=9999):
        
        mock_pyaudio_instance = mock_pyaudio_class.return_value
        mock_pyaudio_instance.open.return_value = MagicMock()
        
        engine = WakeWordEngine()
        # Mock lock path to non-existent file
        engine.lock_path = Path("/nonexistent/path/for/test/voice.lock")
        
        # No stream currently open
        assert engine.active_stream is None
        
        # Call listen(). It should try to start the stream.
        # Since KoraWakeWord is mocked, let's mock detect to return True
        engine.detector.detect.return_value = True
        
        # Mock active stream read to return dummy bytes
        mock_active_stream = MagicMock()
        mock_active_stream.read.return_value = b"\x00" * 2560
        mock_pyaudio_instance.open.return_value = mock_active_stream
        
        result = engine.listen()
        assert result is True
        assert engine.active_stream is not None
        mock_pyaudio_instance.open.assert_called_once()
