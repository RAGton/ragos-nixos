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
from .voice import devices, recorder, stt, tts, pipeline, daemon


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
    client = get_client(args)
    try:
        if args.mode:
            res = client.chat(message=args.question, mode=args.mode)
        else:
            res = client.ask(question=args.question)

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


def handle_voice_test_mic(args: argparse.Namespace) -> None:
    rec = recorder.KoraRecorder()
    path = rec.record_to_file("test_mic.wav", seconds=args.seconds)
    print(f"Gravado em: {path}")


def handle_voice_transcribe(args: argparse.Namespace) -> None:
    rec = recorder.KoraRecorder()
    path = rec.record_to_file("temp_transcribe.wav", seconds=args.seconds)
    text = stt.transcribe_audio(path)
    print(f"Transcrição: {text}")


def handle_voice_speak(args: argparse.Namespace) -> None:
    tts.speak_text(args.text)


def handle_listen(args: argparse.Namespace) -> None:
    # Run the async pipeline
    import asyncio
    asyncio.run(pipeline.listen_and_respond(push_to_talk=args.push_to_talk))


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
    
    mic_parser = voice_subparsers.add_parser("test-mic", help="Test microphone recording")
    mic_parser.add_argument("--seconds", type=int, default=5)
    
    stt_parser = voice_subparsers.add_parser("transcribe", help="Transcribe audio to text")
    stt_parser.add_argument("--seconds", type=int, default=5)
    
    speak_parser = voice_subparsers.add_parser("speak", help="Speak text using TTS")
    speak_parser.add_argument("text", help="Text to speak")

    # voice daemon
    daemon_parser = voice_subparsers.add_parser("daemon", help="Manage voice listener daemon")
    daemon_subparsers = daemon_parser.add_subparsers(dest="voice_daemon_command", required=True)
    daemon_subparsers.add_parser("start", help="Start the daemon")
    daemon_subparsers.add_parser("stop", help="Stop the daemon")
    daemon_subparsers.add_parser("status", help="Get daemon status")

    # listen
    listen_parser = subparsers.add_parser("listen", help="Listen and respond (Voice Mode)")
    listen_parser.add_argument("--push-to-talk", action="store_true", default=True, help="Use push-to-talk mode")

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
        elif args.voice_command == "test-mic":
            handle_voice_test_mic(args)
        elif args.voice_command == "transcribe":
            handle_voice_transcribe(args)
        elif args.voice_command == "speak":
            handle_voice_speak(args)
        elif args.voice_command == "daemon":
            handle_voice_daemon(args)
    elif args.command == "listen":
        handle_listen(args)


if __name__ == "__main__":
    main()
