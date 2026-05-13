#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("kryonix-secret-scan.py")


def run(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--repo", str(repo), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def run_file(path: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), str(path), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def init_repo(repo: Path) -> None:
    subprocess.run(["git", "-C", str(repo), "init"], check=True, stdout=subprocess.PIPE)
    subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "user.name", "Kryonix Test"], check=True)


class SecretScanTests(unittest.TestCase):
    def test_detects_suspicious_untracked_name(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "PROMPT_API_KEY_PRODUCTION.md").write_text("template only\n", encoding="utf-8")

            proc = run(repo, "--json")
            data = json.loads(proc.stdout)

            self.assertEqual(data["status"], "blocked")
            self.assertEqual(data["suspects"][0]["rule"], "suspicious_api_key_name")

    def test_detects_content_without_printing_secret_value(self) -> None:
        sample_value = "a" * 64
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "notes.md").write_text(f"KRYONIX_BRAIN_API_KEY={sample_value}\n", encoding="utf-8")

            proc = run(repo, "--json")
            data = json.loads(proc.stdout)

            self.assertEqual(data["status"], "blocked")
            self.assertIn("possible_api_key", {s["rule"] for s in data["suspects"]})
            self.assertNotIn(sample_value, proc.stdout)
            self.assertFalse(data["printed_secret_values"])

    def test_quarantine_moves_only_untracked_suspects(self) -> None:
        sample_value = "b" * 64
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            init_repo(repo)
            (repo / "tracked.env").write_text(f"KRYONIX_BRAIN_API_KEY={sample_value}\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "tracked.env"], check=True)

            untracked = repo / "backup.bak"
            untracked.write_text(f"KRYONIX_BRAIN_API_KEY={sample_value}\n", encoding="utf-8")

            proc = run(repo, "--json", "--quarantine-untracked")
            data = json.loads(proc.stdout)

            self.assertEqual(data["status"], "blocked")
            self.assertTrue((repo / "tracked.env").exists())
            self.assertFalse(untracked.exists())
            tracked = [s for s in data["suspects"] if s["path"] == "tracked.env"]
            moved = [s for s in data["suspects"] if s["path"] == "backup.bak"]
            self.assertTrue(tracked)
            self.assertTrue(moved)
            self.assertIsNone(tracked[0]["quarantined_to"])
            self.assertIsNotNone(moved[0]["quarantined_to"])
            self.assertNotIn(sample_value, proc.stdout)

    def test_standalone_file_scan_redacts_secret_value(self) -> None:
        sample_value = "FAKE_TEST_SECRET_VALUE_1234567890_DO_NOT_USE"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "fake-secret.txt"
            path.write_text(f"KRYONIX_BRAIN_API_KEY={sample_value}\n", encoding="utf-8")

            proc = run_file(path, "--json")
            data = json.loads(proc.stdout)

            self.assertEqual(data["status"], "blocked")
            self.assertIn("possible_api_key", {s["rule"] for s in data["suspects"]})
            self.assertNotIn(sample_value, proc.stdout)
            self.assertFalse(data["printed_secret_values"])


if __name__ == "__main__":
    unittest.main()
