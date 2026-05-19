"""
lock.py — Hardware lock context manager for Kora.
Ensures exclusive access to sound devices by coordinating CLI and Daemon.
"""
import os
import logging
from pathlib import Path
from types import TracebackType
from typing import Optional, Type

logger = logging.getLogger("kora.utils.lock")


class HardwareLock:
    """
    Context manager that coordinates microphone usage between the Kora CLI and Daemon.
    Uses /run/user/$(id -u)/kryonix/voice.lock to flag active CLI command runs.
    """
    def __init__(self) -> None:
        self.lock_path = Path(f"/run/user/{os.getuid()}/kryonix/voice.lock")

    def __enter__(self) -> "HardwareLock":
        try:
            self.lock_path.parent.mkdir(parents=True, exist_ok=True)
            # Write current PID into lock file for tracking
            self.lock_path.write_text(str(os.getpid()))
            logger.debug(f"HardwareLock acquired by PID {os.getpid()} at {self.lock_path}")
        except Exception as e:
            logger.error(f"Failed to acquire HardwareLock: {e}")
        return self

    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType]
    ) -> None:
        try:
            if self.lock_path.exists():
                self.lock_path.unlink()
                logger.debug(f"HardwareLock released by PID {os.getpid()}")
        except Exception as e:
            logger.error(f"Failed to release HardwareLock: {e}")
