#!/usr/bin/env python3
"""Safe secret preflight for Kryonix deploys.

The scanner reports paths and rule ids only. It never emits matched values or
source lines, because this command is meant to run during incident handling.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path


MAX_SCAN_BYTES = 1024 * 1024

NAME_RULES: list[tuple[str, re.Pattern[str], str]] = [
    ("suspicious_api_key_name", re.compile(r"api[_-]?key", re.I), "medium"),
    ("suspicious_secret_name", re.compile(r"secret", re.I), "medium"),
    ("suspicious_token_name", re.compile(r"token", re.I), "medium"),
    ("backup_file", re.compile(r"\.bak(?:$|\.)", re.I), "medium"),
    ("env_file", re.compile(r"(^|/)(?:\.env|brain\.env|neo4j\.env)$", re.I), "high"),
    ("private_ssh_key_name", re.compile(r"(^|/)id_ed25519", re.I), "high"),
    ("pem_key_file", re.compile(r"\.(?:pem|key)$", re.I), "high"),
]

CONTENT_RULES: list[tuple[str, re.Pattern[str], str]] = [
    (
        "possible_api_key",
        re.compile(
            r"(?i)\b(?:KRYONIX_BRAIN_API_KEY|api[_-]?key|token|secret|password|passwd)\b"
            r"\s*[:=]\s*['\"]?([A-Za-z0-9_./+=:@-]{20,})"
        ),
        "high",
    ),
    (
        "possible_authorization_header",
        re.compile(r"(?i)\b(?:bearer|authorization)\b\s*[:= ]\s*['\"]?([A-Za-z0-9_./+=:@-]{20,})"),
        "high",
    ),
    ("private_key_block", re.compile(r"-{5}BEGIN [A-Z0-9 ]*PRIVATE KEY-{5}", re.I), "critical"),
]

PLACEHOLDER_VALUES = {
    "valor",
    "example",
    "exemplo",
    "changeme",
    "placeholder",
    "sua_chave_de_64_caracteres_hex",
    "sua_chave_de_api_aqui",
}

TOOLING_NAME_ALLOWLIST = {
    "scripts/kryonix-secret-scan.py",
    "scripts/test-kryonix-secret-scan.py",
}

SEVERITY_ORDER = {"low": 0, "medium": 1, "high": 2, "critical": 3}


@dataclass
class Suspect:
    path: str
    tracked: bool
    rule: str
    severity: str
    recommended_action: str
    quarantined_to: str | None = None


def run_git(repo: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def git_paths(repo: Path, args: list[str]) -> set[str]:
    proc = run_git(repo, [*args, "-z"])
    if proc.returncode != 0:
        return set()
    return {p for p in proc.stdout.split("\0") if p}


def is_git_repo(repo: Path) -> bool:
    return run_git(repo, ["rev-parse", "--is-inside-work-tree"]).returncode == 0


def is_placeholder(value: str) -> bool:
    clean = value.strip().strip("'\"").strip()
    lower = clean.lower()
    if not clean or clean.startswith("<") or clean.startswith("$") or "${" in clean:
        return True
    return lower in PLACEHOLDER_VALUES


def safe_read_text(path: Path) -> str:
    try:
        data = path.read_bytes()[:MAX_SCAN_BYTES]
    except OSError:
        return ""
    if b"\x00" in data[:4096]:
        return ""
    return data.decode("utf-8", errors="ignore")


def recommended_action(rule: str, severity: str, tracked: bool) -> str:
    if tracked and SEVERITY_ORDER[severity] >= SEVERITY_ORDER["high"]:
        return "remove_secret_from_git_history_or_rotate"
    if tracked:
        return "review_tracked_file"
    if SEVERITY_ORDER[severity] >= SEVERITY_ORDER["high"]:
        return "quarantine_or_rotate"
    return "quarantine_or_review"


def add_suspect(suspects: dict[tuple[str, str], Suspect], path: str, tracked: bool, rule: str, severity: str) -> None:
    key = (path, rule)
    current = suspects.get(key)
    if current and SEVERITY_ORDER[current.severity] >= SEVERITY_ORDER[severity]:
        return
    suspects[key] = Suspect(
        path=path,
        tracked=tracked,
        rule=rule,
        severity=severity,
        recommended_action=recommended_action(rule, severity, tracked),
    )


def scan_repo(repo: Path) -> list[Suspect]:
    tracked_paths = git_paths(repo, ["ls-files"])
    untracked_paths = git_paths(repo, ["ls-files", "--others", "--exclude-standard"])
    paths = sorted(tracked_paths | untracked_paths)
    suspects: dict[tuple[str, str], Suspect] = {}

    for rel in paths:
        tracked = rel in tracked_paths
        if rel not in TOOLING_NAME_ALLOWLIST:
            for rule, pattern, severity in NAME_RULES:
                if pattern.search(rel):
                    effective_severity = severity
                    if not tracked and severity == "medium":
                        effective_severity = "high"
                    add_suspect(suspects, rel, tracked, rule, effective_severity)

        full_path = repo / rel
        if not full_path.is_file():
            continue

        text = safe_read_text(full_path)
        if not text:
            continue

        for rule, pattern, severity in CONTENT_RULES:
            for match in pattern.finditer(text):
                value = match.group(1) if match.groups() else ""
                if value and is_placeholder(value):
                    continue
                add_suspect(suspects, rel, tracked, rule, severity)
                break

    return sorted(suspects.values(), key=lambda s: (s.path, s.rule))


def scan_file(path: Path) -> list[Suspect]:
    suspects: dict[tuple[str, str], Suspect] = {}
    label = str(path)

    if not path.exists() or not path.is_file():
        add_suspect(suspects, label, False, "missing_or_not_file", "high")
        return list(suspects.values())

    for rule, pattern, severity in NAME_RULES:
        if pattern.search(path.name):
            add_suspect(suspects, label, False, rule, "high" if severity == "medium" else severity)

    text = safe_read_text(path)
    if text:
        for rule, pattern, severity in CONTENT_RULES:
            for match in pattern.finditer(text):
                value = match.group(1) if match.groups() else ""
                if value and is_placeholder(value):
                    continue
                add_suspect(suspects, label, False, rule, severity)
                break

    return sorted(suspects.values(), key=lambda s: (s.path, s.rule))


def quarantine_untracked(repo: Path, suspects: list[Suspect]) -> tuple[list[Suspect], str | None]:
    to_move = [s for s in suspects if not s.tracked]
    if not to_move:
        return suspects, None

    hostname = socket.gethostname().split(".")[0] or "host"
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dest_root = Path.home() / ".local/share/kryonix/private-prompts" / f"{hostname}-{stamp}"
    dest_root.mkdir(parents=True, exist_ok=True)

    for suspect in to_move:
        source = repo / suspect.path
        if not source.exists() or not source.is_file():
            continue
        destination = dest_root / suspect.path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        suspect.quarantined_to = str(destination)
        suspect.recommended_action = "quarantined"

    for root, dirs, files in os.walk(dest_root):
        os.chmod(root, 0o700)
        for dirname in dirs:
            os.chmod(Path(root) / dirname, 0o700)
        for filename in files:
            os.chmod(Path(root) / filename, 0o600)

    return suspects, str(dest_root)


def result_status(suspects: list[Suspect], quarantine_dir: str | None) -> str:
    active = [s for s in suspects if s.quarantined_to is None]
    if any(SEVERITY_ORDER[s.severity] >= SEVERITY_ORDER["high"] for s in active):
        return "blocked"
    if quarantine_dir:
        return "quarantined"
    if active:
        return "warn"
    return "pass"


def render_human(result: dict) -> None:
    print("Kryonix Secret Preflight")
    print()
    print(f"Status: {result['status'].upper()}")
    if result.get("quarantine_dir"):
        print(f"Quarantine: {result['quarantine_dir']}")
    print()
    if result["suspects"]:
        print("Suspects:")
        for suspect in result["suspects"]:
            print(f"- {suspect['path']}")
            print(f"  tracked: {str(suspect['tracked']).lower()}")
            print(f"  rule: {suspect['rule']}")
            print(f"  severity: {suspect['severity']}")
            print(f"  action: {suspect['recommended_action']}")
            if suspect.get("quarantined_to"):
                print(f"  quarantined_to: {suspect['quarantined_to']}")
    else:
        print("Suspects: none")
    print()
    print("No secret values were printed.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Safe secret scanner for Kryonix deploy preflight.")
    parser.add_argument("targets", nargs="*", help="Optional standalone files to scan without reading a git repo.")
    parser.add_argument("--repo", default=".", help="Git repo root to scan.")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    parser.add_argument("--quarantine-untracked", action="store_true", help="Move only untracked suspects to private quarantine.")
    args = parser.parse_args()

    if args.targets:
        suspects: list[Suspect] = []
        for target in args.targets:
            suspects.extend(scan_file(Path(target).resolve()))
        result = {
            "status": result_status(suspects, None),
            "repo": None,
            "targets": [str(Path(t).resolve()) for t in args.targets],
            "suspects": [asdict(s) for s in suspects],
            "quarantine_dir": None,
            "printed_secret_values": False,
        }
        if args.json:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            render_human(result)
        return 1 if result["status"] == "blocked" else 0

    repo = Path(args.repo).resolve()
    if not is_git_repo(repo):
        result = {
            "status": "blocked",
            "repo": str(repo),
            "suspects": [],
            "error": "not_a_git_repo",
            "printed_secret_values": False,
        }
        if args.json:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            render_human(result)
        return 1

    suspects = scan_repo(repo)
    quarantine_dir = None
    if args.quarantine_untracked:
        suspects, quarantine_dir = quarantine_untracked(repo, suspects)

    result = {
        "status": result_status(suspects, quarantine_dir),
        "repo": str(repo),
        "suspects": [asdict(s) for s in suspects],
        "quarantine_dir": quarantine_dir,
        "printed_secret_values": False,
    }

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        render_human(result)

    return 1 if result["status"] == "blocked" else 0


if __name__ == "__main__":
    sys.exit(main())
