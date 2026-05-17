# =============================================================================
# Kora Voice — STT (Speech to Text)
# =============================================================================

import os
import shutil
import subprocess
import logging
from pathlib import Path

logger = logging.getLogger("kora.voice.stt")

WHISPER_CANDIDATES = [
    os.environ.get("KORA_WHISPER_BIN"),
    "whisper-cli",
    "whisper-cpp",
    "whisper-cpp-cli",
    "whisper",
]

def find_whisper_bin() -> str:
    for candidate in WHISPER_CANDIDATES:
        if not candidate:
            continue
        path = shutil.which(candidate)
        if path:
            return path
    raise RuntimeError(
        "Whisper backend não encontrado. Instale/adicione whisper-cpp ao PATH "
        "ou defina KORA_WHISPER_BIN."
    )

import re

CLEAN_ANSI_RE = re.compile(
    r"(?:\x1b|\\x1b|\\033|\\u001b)\[[0-9;?]*[A-Za-z]" # Standard ANSI codes
    r"|\[[0-9]+(?:;[0-9]+)*m"                        # bracket + color codes (e.g. [0m, [38;5;114m)
    r"|(?:\b|;)[0-9]+;[0-9]+(?:;[0-9]+)*m"            # color codes with semicolons (e.g. 38;5;114m, ;166m)
)
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
WHISPER_TS_RE = re.compile(r"\[[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\s*-->\s*[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\]")

def clean_transcript(text: str) -> str:
    text = CLEAN_ANSI_RE.sub("", text)
    text = CONTROL_RE.sub("", text)
    text = WHISPER_TS_RE.sub("", text)
    lines = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("whisper_") or line.startswith("system_info"):
            continue
        if "processing" in line.lower():
            continue
        lines.append(line)
    return " ".join(lines).strip()

def transcribe_audio(audio_path: Path, user: str = "rocha") -> str:
    """Transcribe audio file using whisper-cli."""
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    # Resolve model dynamically so post-install runs pick up the model
    from .config import _resolve_whisper_model
    model_path = _resolve_whisper_model()

    if not Path(model_path).exists():
        logger.error(
            f"Modelo Whisper não encontrado: {model_path}\n"
            "  → Execute: kora voice models install whisper base"
        )
        return "[Modelo Whisper não instalado — execute: kora voice models install whisper base]"

    try:
        whisper_bin = find_whisper_bin()
        logger.debug(f"STT: usando {whisper_bin} com modelo {model_path}")

        output_base = "/tmp/kora-whisper-output"
        output_txt = output_base + ".txt"

        # Ensure previous file is removed
        if os.path.exists(output_txt):
            os.remove(output_txt)

        # Prime Whisper's vocabulary dynamically using user's active learning profile
        prompt_words = [
            "Kora", "Kryonix", "Hyprland", "NixOS", "Inspiron", "Glacier", "Ragton",
            "terminal", "CLI", "systemd", "Caelestia"
        ]
        if user:
            try:
                from kora.core.learning import LearningEngine
                engine = LearningEngine()
                profile = engine.get_profile(user)
                if profile.get("technical_vocabulary"):
                    prompt_words.extend(profile["technical_vocabulary"])
                if profile.get("active_projects"):
                    prompt_words.extend(profile["active_projects"])
                if profile.get("spelling_mappings"):
                    # Add corrected/target terms to prime Whisper
                    prompt_words.extend(profile["spelling_mappings"].values())
            except Exception as pe:
                logger.warning(f"Erro ao ler perfil para Whisper prompt: {pe}")

        # Deduplicate and format prompt
        unique_words = []
        for w in prompt_words:
            if w and w not in unique_words:
                unique_words.append(w)
        prompt_str = ", ".join(unique_words) + "."

        subprocess.run([
            whisper_bin,
            "-m", model_path,
            "-f", str(audio_path),
            "-nt",
            "-l", "pt",
            "-t", "6",
            "-sns",
            "--prompt", prompt_str,
            "-otxt",
            "-of", output_base
        ], capture_output=True, text=True, check=True)

        if os.path.exists(output_txt):
            with open(output_txt, "r", encoding="utf-8") as f:
                raw_text = f.read()
            text = clean_transcript(raw_text)
        else:
            logger.warning("STT output file not created. Falling back to empty.")
            text = ""

        try:
            from kora.core.normalizer import normalize_text
            text = normalize_text(text, user).normalized
        except Exception as norm_err:
            logger.warning("Erro ao normalizar transcricao: %s", norm_err)

        logger.info(f"STT: {text}")
        return text
    except Exception as e:
        logger.error(f"STT failed: {e}")
        return "[Erro na transcrição]"
