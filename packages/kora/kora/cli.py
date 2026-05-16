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


if __name__ == "__main__":
    main()
