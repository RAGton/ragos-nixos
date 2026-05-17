# =============================================================================
# Kora — CLI
#
# Interface de linha de comando oficial para a assistente Kora.
# Permite acesso direto à API local ou remota.
# =============================================================================

import argparse
import json
import sys
from typing import Any

from .client import KoraClient, KoraClientError
from .voice import devices, recorder, stt, tts, pipeline, daemon, identity, wakeword
from .core import users


def print_json(data: Any) -> None:
    """Print data as formatted JSON."""
    print(json.dumps(data, indent=2, ensure_ascii=False))


def print_table(title: str, data: dict[str, Any]) -> None:
    """Print data in a simple key-value table (fallback without rich)."""
    print(f"\n=== {title} ===")
    for k, v in data.items():
        if isinstance(v, dict):
            print(f"{k}:")
            for sub_k, sub_v in v.items():
                print(f"  {sub_k}: {sub_v}")
        elif isinstance(v, list):
            print(f"{k}:")
            for item in v:
                print(f"  - {item}")
        else:
            print(f"{k}: {v}")
    print()


def get_client(args: argparse.Namespace) -> KoraClient:
    """Instantiate the client based on args."""
    return KoraClient(url=args.url, timeout=args.timeout)


def handle_health(args: argparse.Namespace) -> None:
    client = get_client(args)
    try:
        res = client.health()
        if args.json:
            print_json(res)
        else:
            print_table("Kora Health", res)
    except KoraClientError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


def handle_status(args: argparse.Namespace) -> None:
    client = get_client(args)
    try:
        res = client.status()
        if args.json:
            print_json(res)
        else:
            print_table("Kora Status", res)
    except KoraClientError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


def handle_capabilities(args: argparse.Namespace) -> None:
    client = get_client(args)
    try:
        res = client.capabilities()
        if args.json:
            print_json(res)
        else:
            print_table("Kora Capabilities", res)
    except KoraClientError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


def handle_ask(args: argparse.Namespace) -> None:
    import os
    current_user = os.environ.get("USER") or "unknown"
    client = get_client(args)
    try:
        if args.mode:
            res = client.chat(message=args.question, mode=args.mode, user=current_user)
        else:
            res = client.ask(question=args.question, user=current_user)

        if args.json:
            print_json(res)
        else:
            print(f"\n{res.get('answer', 'No answer received')}\n")
            if not args.quiet:
                grounding = res.get("grounding", {})
                level = grounding.get("level") or grounding.get("confidence", "none")
                print(f"[Mode: {res.get('mode')} | Grounding: {level} | Time: {res.get('elapsed_sec', 0):.2f}s]")
    except KoraClientError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


def handle_chat(args: argparse.Namespace) -> None:
    # Future: interactive loop. For now, works like ask if message provided.
    print("Chat mode is partial in CLI. Use 'ask' for single messages or wait for Phase 3 CLI updates.", file=sys.stderr)
    sys.exit(1)


def handle_memory_search(args: argparse.Namespace) -> None:
    client = get_client(args)
    try:
        res = client.memory_search(query=args.query, mode=args.mode)
        if args.json:
            print_json(res)
        else:
            print_table(f"Memory Search Results (mode: {args.mode})", res)
    except KoraClientError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


def handle_voice_devices(args: argparse.Namespace) -> None:
    print("\n--- Dispositivos de Entrada ---")
    for d in devices.list_input_devices():
        print(f"  {d}")
    print("\n--- Dispositivos de Saída ---")
    for d in devices.list_output_devices():
        print(f"  {d}")


def handle_voice_doctor(args: argparse.Namespace) -> None:
    import shutil
    import os, pwd, grp
    from . voice import models as voice_models
    print("\n=== KORA VOICE DOCTOR ===")

    print("\n[BIN\u00c1RIOS]")
    binaries = ["whisper-cli", "whisper-cpp", "whisper-cpp-cli", "piper-tts", "piper", "aplay", "arecord"]
    for b in binaries:
        path = shutil.which(b)
        if path:
            print(f"  {b}: FOUND ({path})")
        else:
            print(f"  {b}: MISSING")

    print("\n[MODELOS]")
    whisper = voice_models.resolve_whisper_model()
    if whisper:
        size_mb = round(whisper.stat().st_size / 1_048_576, 1)
        print(f"  Whisper: FOUND {whisper}  ({size_mb} MB)")
    else:
        print("  Whisper: MISSING  \u2192 kora voice models install whisper base")
    piper_m, piper_c = voice_models.resolve_piper_model()
    if piper_m:
        print(f"  Piper model:  FOUND {piper_m}")
    else:
        print("  Piper model:  MISSING  \u2192 kora voice models install piper faber")
    if piper_c:
        print(f"  Piper config: FOUND {piper_c}")
    else:
        print("  Piper config: MISSING")

    print("\n[DISPOSITIVOS DE \u00c1UDIO]")
    handle_voice_devices(args)

    print("\n[DIRET\u00d3RIOS E PERMISS\u00d5ES]")
    dirs = [
        "/var/lib/kryonix/kora",
        "/var/lib/kryonix/kora/voice",
        "/var/lib/kryonix/kora/voice/profiles",
        "/var/lib/kryonix/kora/voice/models/whisper",
        "/var/lib/kryonix/kora/voice/models/piper",
    ]
    for d in dirs:
        if os.path.exists(d):
            st = os.stat(d)
            user = pwd.getpwuid(st.st_uid).pw_name
            group = grp.getgrgid(st.st_gid).gr_name
            perms = oct(st.st_mode)[-3:]
            print(f"  {d}: EXISTE ({user}:{group} {perms})")
        else:
            print(f"  {d}: MISSING")


def handle_voice_models_status(args: argparse.Namespace) -> None:
    from .voice import models as voice_models
    voice_models.cmd_status()


def handle_voice_models_list(args: argparse.Namespace) -> None:
    from .voice import models as voice_models
    voice_models.cmd_list()


def handle_voice_models_install(args: argparse.Namespace) -> None:
    from .voice import models as voice_models
    kind = args.model_type.lower()
    name = args.model_name.lower()
    if kind == "whisper":
        voice_models.cmd_install_whisper(name)
    elif kind == "piper":
        voice_models.cmd_install_piper(name)
    else:
        print(f"[ERRO] Tipo desconhecido: '{kind}'. Use 'whisper' ou 'piper'.")



def handle_voice_test_mic(args: argparse.Namespace) -> None:
    rec = recorder.KoraRecorder()
    path = rec.record_to_file("test_mic.wav", seconds=args.seconds)
    print(f"Gravado em: {path}")


def handle_voice_transcribe(args: argparse.Namespace) -> None:
    rec = recorder.KoraRecorder()
    path = rec.record_to_file("temp_transcribe.wav", seconds=args.seconds)
    text = stt.transcribe_audio(path)
    print(f"Transcrição: {text}")


DEFAULT_SPEAK_TEXT = "Kora online, Ragton. Estou pronta para acompanhar você."


def handle_voice_speak(args: argparse.Namespace) -> None:
    from .voice.voices import get_active_preset
    preset = get_active_preset()
    text = getattr(args, "text", None) or DEFAULT_SPEAK_TEXT
    if getattr(args, "test", False):
        text = "Kora online, Ragton. Testando voz atual com preset ativo."
    tts.speak_text_with_preset(text, preset=preset)


# ---------------------------------------------------------------------------
# Voice Voices handlers
# ---------------------------------------------------------------------------

def handle_voice_voices(args: argparse.Namespace) -> None:
    from .voice import voices as voice_voices
    cmd = args.voice_voices_command
    if cmd == "list":
        voice_voices.cmd_list()
    elif cmd == "current":
        voice_voices.cmd_current()
    elif cmd == "set":
        voice_voices.cmd_set(args.preset_name)
    elif cmd == "test":
        voice_voices.cmd_test()


# ---------------------------------------------------------------------------
# Voice Service handlers (systemctl --user)
# ---------------------------------------------------------------------------

SERVICE_UNIT = "kora-voice-listener.service"


def _systemctl_user(*subcmds: str, capture: bool = False) -> int | str:
    import subprocess as _sp
    cmd = ["systemctl", "--user"] + list(subcmds)
    if capture:
        result = _sp.run(cmd, capture_output=True, text=True)
        return result.stdout + result.stderr
    return _sp.run(cmd).returncode


def handle_voice_service(args: argparse.Namespace) -> None:
    import subprocess as _sp
    cmd = args.voice_service_command
    if cmd == "enable":
        rc = _systemctl_user("enable", "--now", SERVICE_UNIT)
        if rc == 0:
            print(f"  ✓ {SERVICE_UNIT} habilitado e iniciado.")
            print("  ⚠ Wake-word real 'Kora' ainda pendente de modelo custom.")
        else:
            print(f"  ✗ Falha ao habilitar. Crie o unit primeiro via 'kryonix switch all'.")
    elif cmd == "disable":
        _systemctl_user("disable", "--now", SERVICE_UNIT)
        print(f"  ✓ {SERVICE_UNIT} desabilitado.")
    elif cmd == "start":
        _systemctl_user("start", SERVICE_UNIT)
        print(f"  ✓ {SERVICE_UNIT} iniciado.")
    elif cmd == "stop":
        _systemctl_user("stop", SERVICE_UNIT)
        print(f"  ✓ {SERVICE_UNIT} parado.")
    elif cmd == "restart":
        _systemctl_user("restart", SERVICE_UNIT)
        print(f"  ✓ {SERVICE_UNIT} reiniciado.")
    elif cmd == "status":
        out = _systemctl_user("status", "--no-pager", "-l", SERVICE_UNIT, capture=True)
        print(out or f"  {SERVICE_UNIT}: não encontrado ou não iniciado.")
    elif cmd == "logs":
        _sp.run([
            "journalctl", "--user", "-u", SERVICE_UNIT,
            "--no-pager", "-n", "50"
        ])



def handle_listen(args: argparse.Namespace) -> None:
    # Run the async pipeline
    import asyncio
    try:
        asyncio.run(pipeline.listen_and_respond(push_to_talk=args.push_to_talk))
    except KeyboardInterrupt:
        print("\n[Encerrando modo voz]")
        return


def handle_voice_daemon(args: argparse.Namespace) -> None:
    if args.voice_daemon_command == "status":
        # Note: In a real implementation, this would query a running service
        # or check a PID/socket. For now, we show foundation status.
        print_json({
            "status": "foundation",
            "ready": False,
            "note": "Daemon is currently in foundation mode. Use 'kora listen' for PTT."
        })
    elif args.voice_daemon_command == "start":
        print("Starting Kora Voice Daemon (Foundation)...")
        import asyncio
        asyncio.run(daemon.run_daemon())
    elif args.voice_daemon_command == "stop":
        print("Stopping Kora Voice Daemon... (Not yet implemented via CLI control)")


def handle_user(args: argparse.Namespace) -> None:
    registry = users.UserRegistry()

    if args.user_command == "init":
        # Create initial users
        ragton = users.KoraUser(
            id="ragton",
            display_name="Ragton",
            full_name="Gabriel Aguiar Rocha",
            linux_user="rocha",
            github_user="RAGton",
            role="owner",
            permission_level="admin_owner",
            can_access_private_memory=True,
            can_request_commands=True,
            can_request_admin_actions=True,
            preferences=["Linux", "NixOS", "IA", "Development"]
        )
        nicoly = users.KoraUser(
            id="nicoly",
            display_name="Nicoly",
            linux_user="nina",
            role="trusted_partner",
            permission_level="trusted_user",
            preferences=["Culinária", "Design", "Filmes"]
        )
        registry.save_user(ragton)
        registry.save_user(nicoly)
        print("Initial users created: ragton, nicoly")

    elif args.user_command == "add":
        user = users.KoraUser(
            id=args.id,
            display_name=args.display_name,
            full_name=args.full_name,
            linux_user=args.linux_user,
            github_user=args.github,
            role=args.role,
            permission_level="admin_owner" if args.role == "owner" else "trusted_user"
        )
        registry.save_user(user)
        print(f"User {args.id} added.")

    elif args.user_command == "list":
        usrs = registry.list_users()
        data = {u.id: {"display": u.display_name, "role": u.role, "level": u.permission_level} for u in usrs}
        print_json(data)

    elif args.user_command == "show":
        user = registry.get_user(args.id)
        if user:
            print_json(user.to_dict())
        else:
            print(f"User {args.id} not found.")

    elif args.user_command == "remove":
        registry.delete_user(args.id)
        print(f"User {args.id} removed.")


def handle_voice_identity(args: argparse.Namespace) -> None:
    manager = identity.VoiceIdentityManager()

    if args.voice_identity_command == "status":
        print_json(identity.get_voice_identity_status())
    elif args.voice_identity_command == "enroll":
        manager.enroll(args.user_id)
    elif args.voice_identity_command == "identify":
        print_json(manager.identify())


def handle_voice_wakeword_status(args: argparse.Namespace) -> None:
    print_json(wakeword.get_wakeword_status())


def main() -> None:
    parser = argparse.ArgumentParser(description="Kora Personal Assistant CLI")
    parser.add_argument("--url", help="Override KORA_API_URL")
    parser.add_argument("--timeout", type=int, default=120, help="Request timeout (seconds)")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
    parser.add_argument("--quiet", "-q", action="store_true", help="Suppress metadata/diagnostics")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # health
    subparsers.add_parser("health", help="Check API and dependencies health")

    # status
    subparsers.add_parser("status", help="Get service metadata and uptime")

    # capabilities
    subparsers.add_parser("capabilities", help="List active and planned capabilities")

    # ask
    ask_parser = subparsers.add_parser("ask", help="Ask a quick question")
    ask_parser.add_argument("question", help="The question to ask")
    ask_parser.add_argument("--mode", choices=["direct", "rag", "auto"], help="Override processing mode")

    # chat
    subparsers.add_parser("chat", help="Start interactive chat (Phase 3)")

    # memory
    memory_parser = subparsers.add_parser("memory", help="Memory and graph operations")
    memory_subparsers = memory_parser.add_subparsers(dest="memory_command", required=True)

    search_parser = memory_subparsers.add_parser("search", help="Search the knowledge base")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument("--mode", choices=["hybrid", "naive", "local", "global"], default="hybrid", help="Search mode")

    # voice
    voice_parser = subparsers.add_parser("voice", help="Voice and audio operations")
    voice_subparsers = voice_parser.add_subparsers(dest="voice_command", required=True)

    voice_subparsers.add_parser("devices", help="List audio devices")
    voice_subparsers.add_parser("doctor", help="Run diagnostics for voice pipeline")

    mic_parser = voice_subparsers.add_parser("test-mic", help="Test microphone recording")
    mic_parser.add_argument("--seconds", type=int, default=5)

    stt_parser = voice_subparsers.add_parser("transcribe", help="Transcribe audio to text")
    stt_parser.add_argument("--seconds", type=int, default=5)

    speak_parser = voice_subparsers.add_parser("speak", help="Speak text using TTS")
    speak_parser.add_argument("text", nargs="?", default=None, help="Texto a falar (usa padrão se omitido)")
    speak_parser.add_argument("--test", action="store_true", help="Fala frase de teste")
    speak_parser.add_argument("--voice", default=None, help="Preset de voz (faber, cadu...)")

    # voice voices
    voices_parser = voice_subparsers.add_parser("voices", help="Manage voice presets")
    voices_subparsers = voices_parser.add_subparsers(dest="voice_voices_command", required=True)
    voices_subparsers.add_parser("list",    help="List voice presets")
    voices_subparsers.add_parser("current", help="Show active preset")
    voices_subparsers.add_parser("test",    help="Test active preset")
    voices_set_parser = voices_subparsers.add_parser("set", help="Set active preset")
    voices_set_parser.add_argument("preset_name", help="Preset name (default, soft, fast, expressive)")

    # voice service
    service_parser = voice_subparsers.add_parser("service", help="Manage Kora background voice service")
    service_subparsers = service_parser.add_subparsers(dest="voice_service_command", required=True)
    for svc_cmd, svc_help in [
        ("enable",  "Enable and start background listener"),
        ("disable", "Disable background listener"),
        ("start",   "Start background listener"),
        ("stop",    "Stop background listener"),
        ("restart", "Restart background listener"),
        ("status",  "Show service status"),
        ("logs",    "Show recent service logs"),
    ]:
        service_subparsers.add_parser(svc_cmd, help=svc_help)

    # voice daemon
    daemon_parser = voice_subparsers.add_parser("daemon", help="Manage voice listener daemon")
    daemon_subparsers = daemon_parser.add_subparsers(dest="voice_daemon_command", required=True)
    daemon_subparsers.add_parser("start", help="Start the daemon")
    daemon_subparsers.add_parser("stop", help="Stop the daemon")
    daemon_subparsers.add_parser("status", help="Get daemon status")

    # voice identity
    identity_parser = voice_subparsers.add_parser("identity", help="Manage voice identity")
    identity_subparsers = identity_parser.add_subparsers(dest="voice_identity_command", required=True)
    identity_subparsers.add_parser("status", help="Get identity engine status")
    enroll_parser = identity_subparsers.add_parser("enroll", help="Enroll a user's voice")
    enroll_parser.add_argument("user_id", help="User ID to enroll")
    identity_subparsers.add_parser("identify", help="Identify the current speaker")

    # voice wake-word
    ww_parser = voice_subparsers.add_parser("wake-word", help="Manage wake-word engine")
    ww_subparsers = ww_parser.add_subparsers(dest="voice_ww_command", required=True)
    ww_subparsers.add_parser("status", help="Get wake-word engine status")

    # voice models
    models_parser = voice_subparsers.add_parser("models", help="Manage local voice models")
    models_subparsers = models_parser.add_subparsers(dest="voice_models_command", required=True)
    models_subparsers.add_parser("status", help="Show active model status")
    models_subparsers.add_parser("list",   help="List available models for installation")
    install_parser = models_subparsers.add_parser("install", help="Install a model (e.g. install whisper base)")
    install_parser.add_argument("model_type", choices=["whisper", "piper"], help="Type of model")
    install_parser.add_argument("model_name", help="Model name (e.g. base, small, faber, cadu)")

    # listen
    listen_parser = subparsers.add_parser("listen", help="Listen and respond (Voice Mode)")
    listen_parser.add_argument("--push-to-talk", action="store_true", default=True, help="Use push-to-talk mode")

    # user
    user_parser = subparsers.add_parser("user", help="Manage Kora users")
    user_subparsers = user_parser.add_subparsers(dest="user_command", required=True)
    user_subparsers.add_parser("init", help="Initialize default users")
    user_add_parser = user_subparsers.add_parser("add", help="Add a new user")
    user_add_parser.add_argument("--id", required=True)
    user_add_parser.add_argument("--display-name", required=True)
    user_add_parser.add_argument("--full-name")
    user_add_parser.add_argument("--linux-user")
    user_add_parser.add_argument("--github")
    user_add_parser.add_argument("--role", default="trusted_partner")

    user_subparsers.add_parser("list", help="List all users")

    user_show_parser = user_subparsers.add_parser("show", help="Show user details")
    user_show_parser.add_argument("id")

    user_remove_parser = user_subparsers.add_parser("remove", help="Remove a user")
    user_remove_parser.add_argument("id")

    args = parser.parse_args()

    if args.command == "health":
        handle_health(args)
    elif args.command == "status":
        handle_status(args)
    elif args.command == "capabilities":
        handle_capabilities(args)
    elif args.command == "ask":
        handle_ask(args)
    elif args.command == "chat":
        handle_chat(args)
    elif args.command == "memory":
        if args.memory_command == "search":
            handle_memory_search(args)
    elif args.command == "voice":
        if args.voice_command == "devices":
            handle_voice_devices(args)
        elif args.voice_command == "doctor":
            handle_voice_doctor(args)
        elif args.voice_command == "test-mic":
            handle_voice_test_mic(args)
        elif args.voice_command == "transcribe":
            handle_voice_transcribe(args)
        elif args.voice_command == "speak":
            handle_voice_speak(args)
        elif args.voice_command == "voices":
            handle_voice_voices(args)
        elif args.voice_command == "service":
            handle_voice_service(args)
        elif args.voice_command == "daemon":
            handle_voice_daemon(args)
        elif args.voice_command == "identity":
            handle_voice_identity(args)
        elif args.voice_command == "models":
            if args.voice_models_command == "status":
                handle_voice_models_status(args)
            elif args.voice_models_command == "list":
                handle_voice_models_list(args)
            elif args.voice_models_command == "install":
                handle_voice_models_install(args)
        elif args.voice_command == "wake-word":
            if args.voice_ww_command == "status":
                handle_voice_wakeword_status(args)
    elif args.command == "listen":
        handle_listen(args)
    elif args.command == "user":
        handle_user(args)


if __name__ == "__main__":
    main()
