"""
Kora — Entry point for manual execution and debugging.

Usage:
    python -m kora.main
    uv run python -m kora.main
"""

from kora.api.server import main

if __name__ == "__main__":
    main()
