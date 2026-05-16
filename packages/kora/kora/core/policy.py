"""
Kora — Command Policy Engine (Secured)

Define risk levels and classification for system commands.
Ensures safety by detecting shell operators, sudo bypasses, and secret leaks.
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
    UNKNOWN = "unknown"

# Shell operators that increase risk to BLOCKED or HIGH
SHELL_OPERATORS = [";", "&&", "||", "|", ">", ">>", "$(", "`"]

# Secret files that should never be read by Kora
SECRET_FILES = [
    "kora.env", "n8n.env", "brain.env", "neo4j.env", ".env",
    "id_ed25519", "id_rsa", "private.key", "shadow", "passwd"
]

# Whitelist for READ_ONLY commands
READ_ONLY_WHITELIST = [
    r"^kora health$",
    r"^kora latency$",
    r"^kryonix doctor$",
    r"^kryonix status$",
    r"^kryonix git-status$",
    r"^systemctl status [a-zA-Z0-9\._-]+$",
    r"^journalctl -n [0-9]+$",
    r"^journalctl -u [a-zA-Z0-9\._-]+ -n [0-9]+$",
    r"^nvidia-smi$",
    r"^ollama ps$",
    r"^free -h$",
    r"^df -h$",
    r"^ip a$",
    r"^ss -ltnp$",
    r"^curl -fsS http://127.0.0.1:[0-9]+/health$",
]

# Patterns for MEDIUM risk (require simple confirmation)
MEDIUM_RISK_PATTERNS = [
    r"^systemctl (start|stop|restart|reload) [a-zA-Z0-9\._-]+$",
    r"^kryonix switch",
    r"^kryonix boot",
    r"^git (pull|push|fetch|status|diff)",
    r"^nix (build|shell|develop|flake update)",
]

# Patterns for HIGH risk (require strong confirmation)
HIGH_RISK_PATTERNS = [
    r"^iptables",
    r"^nftables",
    r"^tailscale",
    r"^ssh-",
    r"^nixos-rebuild", # switch/boot are in medium, but raw rebuild is high
]

# Explicitly BLOCKED patterns
BLOCKED_PATTERNS = [
    r"rm\s+-rf",
    r"mkfs",
    r"dd\s+",
    r"parted",
    r"fdisk",
    r"sfdisk",
    r"sgdisk",
    r"wipefs",
    r"nixos-install",
    r"disko",
    r"cryptsetup",
    r"btrfs\s+subvolume\s+delete",
    r"zpool\s+destroy",
    r"cat\s+.*\.env",
    r"grep\s+.*_KEY",
]

def classify_command(command: str) -> RiskLevel:
    """
    Classify a shell command into a risk level with security in mind.
    """
    # 1. Normalize and strip prefixes
    cmd = command.strip().lower()
    
    # Remove sudo/doas/env/python prefixes
    # This is a basic normalization to find the "real" command
    clean_cmd = re.sub(r"^(sudo|doas|env|python[0-9]?|bash|sh|run)\s+", "", cmd)

    # 2. Check for shell operators (Insecure chaining)
    for op in SHELL_OPERATORS:
        if op in cmd:
            return RiskLevel.BLOCKED

    # 3. Check for secret leakage
    for secret in SECRET_FILES:
        if secret in cmd:
            return RiskLevel.BLOCKED

    # 4. Check BLOCKED patterns
    for p in BLOCKED_PATTERNS:
        if re.search(p, clean_cmd):
            return RiskLevel.BLOCKED

    # 5. Check READ_ONLY whitelist (must be exact matches or safe patterns)
    for p in READ_ONLY_WHITELIST:
        if re.match(p, clean_cmd):
            return RiskLevel.READ_ONLY

    # 6. Check HIGH risk
    for p in HIGH_RISK_PATTERNS:
        if re.search(p, clean_cmd):
            return RiskLevel.HIGH

    # 7. Check MEDIUM risk
    for p in MEDIUM_RISK_PATTERNS:
        if re.search(p, clean_cmd):
            return RiskLevel.MEDIUM

    # 8. Default for everything else
    return RiskLevel.UNKNOWN
