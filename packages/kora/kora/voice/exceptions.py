class VoiceDaemonError(Exception):
    """Base exception for VoiceDaemon failures."""


class ServiceUnreachable(VoiceDaemonError):
    """Orchestrator or LLM backend is unreachable."""


class HardwareAccessError(VoiceDaemonError):
    """Audio hardware cannot be opened or accessed."""
