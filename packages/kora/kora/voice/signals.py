# =============================================================================
# Kora Voice — Signal Sounds
# =============================================================================
# Generates and plays short signal tones for wake, thinking, error events.
# Uses pure Python PCM generation + aplay. No external assets required.
# =============================================================================

import logging
import math
import struct
import shutil
import subprocess
import tempfile
from pathlib import Path

logger = logging.getLogger("kora.voice.signals")


def _generate_tone(
    freq: float = 880.0,
    duration: float = 0.15,
    volume: float = 0.3,
    sample_rate: int = 22050,
    fade_ms: float = 10.0,
) -> bytes:
    """Generate a pure sine wave tone as raw 16-bit PCM."""
    n_samples = int(sample_rate * duration)
    fade_samples = int(sample_rate * fade_ms / 1000)
    samples = []
    for i in range(n_samples):
        t = i / sample_rate
        val = volume * math.sin(2 * math.pi * freq * t)
        # Apply fade-in/out to avoid clicks
        if i < fade_samples:
            val *= i / fade_samples
        elif i > n_samples - fade_samples:
            val *= (n_samples - i) / fade_samples
        samples.append(int(val * 32767))
    return struct.pack(f"<{len(samples)}h", *samples)


# ── Signal definitions ───────────────────────────────────────────────────────

def _play_raw(data: bytes, sample_rate: int = 22050) -> None:
    """Play raw PCM data via aplay."""
    aplay = shutil.which("aplay")
    if not aplay:
        logger.warning("aplay não encontrado — sinal não reproduzido.")
        return
    try:
        proc = subprocess.Popen(
            [aplay, "-r", str(sample_rate), "-f", "S16_LE", "-t", "raw", "-q", "-"],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        proc.stdin.write(data)
        proc.stdin.close()
        proc.wait(timeout=3)
    except Exception as e:
        logger.error(f"Erro ao reproduzir sinal: {e}")


def play_wake() -> None:
    """Short ascending double-beep — wake-word detected."""
    tone1 = _generate_tone(freq=660, duration=0.08, volume=0.25)
    tone2 = _generate_tone(freq=880, duration=0.12, volume=0.3)
    silence = b"\x00\x00" * 1100  # ~50ms silence
    _play_raw(tone1 + silence + tone2)


def play_thinking() -> None:
    """Single soft tone — processing started."""
    tone = _generate_tone(freq=440, duration=0.1, volume=0.15)
    _play_raw(tone)


def play_error() -> None:
    """Low descending tone — error occurred."""
    tone1 = _generate_tone(freq=440, duration=0.1, volume=0.25)
    tone2 = _generate_tone(freq=330, duration=0.15, volume=0.2)
    silence = b"\x00\x00" * 1100
    _play_raw(tone1 + silence + tone2)


def play_done() -> None:
    """Quick high blip — response ready."""
    tone = _generate_tone(freq=1046, duration=0.06, volume=0.2)
    _play_raw(tone)


# ── CLI ──────────────────────────────────────────────────────────────────────

def cmd_signal(name: str) -> None:
    """Play a named signal."""
    signals = {
        "wake": play_wake,
        "thinking": play_thinking,
        "error": play_error,
        "done": play_done,
    }
    fn = signals.get(name)
    if fn:
        print(f"  ♪ Reproduzindo sinal: {name}")
        fn()
    else:
        print(f"  ✗ Sinal desconhecido: '{name}'. Disponíveis: {list(signals.keys())}")
