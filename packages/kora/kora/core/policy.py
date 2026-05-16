"""
Kora — Command Policy Engine

Define risk levels and classification for system commands.
"""

from enum import Enum
import re

class RiskLevel(Enum):
    READ_ONLY = "read_only"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"
    BLOCKED = "blocked"

# Patterns for classification
READ_ONLY_PATTERNS = [
    r"^kryonix doctor",
    r"^kryonix status",
    r"^kryonix git-status",
    r"^systemctl status",
    r"^journalctl",
    r"^kora health",
    r"^kora latency",
    r"^nvidia-smi",
    r"^ollama ps",
    r"^free -h",
    r"^df -h",
    r"^ip a",
    r"^ss -",
]

MEDIUM_RISK_PATTERNS = [
    r"^systemctl (start|stop|restart)",
    r"^kryonix switch",
    r"^git (pull|push)",
    r"^nix (build|shell|develop)",
]

HIGH_RISK_PATTERNS = [
    r"^bootloader",
    r"^networkmanager",
    r"^tailscale",
    r"^iptables",
    r"^nftables",
    r"^ssh",
]

BLOCKED_PATTERNS = [
    r"^rm -rf /",
    r"^mkfs",
    r"^dd",
    r"^parted",
    r"^fdisk",
    r"^wipefs",
    r"^nixos-install",
]

def classify_command(command: str) -> RiskLevel:
    """Classify a shell command into a risk level."""
    cmd = command.strip().lower()
    
    for p in BLOCKED_PATTERNS:
        if re.search(p, cmd):
            return RiskLevel.BLOCKED
            
    for p in HIGH_RISK_PATTERNS:
        if re.search(p, cmd):
            return RiskLevel.HIGH
            
    for p in MEDIUM_RISK_PATTERNS:
        if re.search(p, cmd):
            return RiskLevel.MEDIUM
            
    for p in READ_ONLY_PATTERNS:
        if re.search(p, cmd):
            return RiskLevel.READ_ONLY
            
    return RiskLevel.LOW
