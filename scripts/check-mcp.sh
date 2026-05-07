#!/usr/bin/env bash
# Validate Kryonix MCP configuration on NixOS/Linux.

set -euo pipefail

VERBOSE=0
if [[ "${1:-}" == "--verbose" || "${1:-}" == "-v" ]]; then
  VERBOSE=1
fi

EXIT_CODE=0
KRYONIX_MCP_SKIP_CLI="${KRYONIX_MCP_SKIP_CLI:-0}"

if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  NC=""
else
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  NC=$'\033[0m'
fi

print_header() {
  printf '%s%s%s\n' "$BLUE" "-> $1" "$NC"
}

print_ok() {
  printf '%s%s%s\n' "$GREEN" "OK: $1" "$NC"
}

print_warn() {
  printf '%s%s%s\n' "$YELLOW" "WARN: $1" "$NC"
}

print_error() {
  printf '%s%s%s\n' "$RED" "FAIL: $1" "$NC"
  EXIT_CODE=1
}

verbose() {
  if (( VERBOSE )); then
    printf '  %s\n' "$1"
  fi
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

ROOT="$(repo_root)"
cd "$ROOT"

python_json() {
  local file="$1"
  local mode="$2"
  python3 - "$file" "$mode" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
mode = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))

if mode == "servers":
    print("\n".join(data.get("mcpServers", {}).keys()))
elif mode == "dump":
    print(json.dumps(data, indent=2, sort_keys=True))
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
}

python_toml() {
  local file="$1"
  local mode="$2"
  python3 - "$file" "$mode" <<'PY'
import json
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError as exc:
    raise SystemExit(f"tomllib unavailable: {exc}") from exc

path = Path(sys.argv[1])
mode = sys.argv[2]
data = tomllib.loads(path.read_text(encoding="utf-8"))

if mode == "servers":
    print("\n".join(data.get("mcp_servers", {}).keys()))
elif mode == "dump":
    print(json.dumps(data, indent=2, sort_keys=True))
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
}

json_valid() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq empty "$file" >/dev/null
  else
    python_json "$file" dump >/dev/null
  fi
}

toml_valid() {
  local file="$1"
  python_toml "$file" dump >/dev/null
}

list_json_servers() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.mcpServers | keys[]' "$file"
  else
    python_json "$file" servers
  fi
}

list_toml_servers() {
  local file="$1"
  python_toml "$file" servers
}

json_server_field() {
  local file="$1"
  local server="$2"
  local field="$3"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg server "$server" --arg field "$field" '.mcpServers[$server][$field] // empty' "$file"
  else
    python3 - "$file" "$server" "$field" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("mcpServers", {}).get(sys.argv[2], {}).get(sys.argv[3], ""))
PY
  fi
}

toml_server_field() {
  local file="$1"
  local server="$2"
  local field="$3"
  python3 - "$file" "$server" "$field" <<'PY'
try:
    import tomllib
except ModuleNotFoundError as exc:
    raise SystemExit(f"tomllib unavailable: {exc}") from exc

import sys

data = tomllib.loads(open(sys.argv[1], encoding="utf-8").read())
print(data.get("mcp_servers", {}).get(sys.argv[2], {}).get(sys.argv[3], ""))
PY
}

validate_security() {
  local file="$1"
  local format="$2"
  python3 - "$file" "$format" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
format_name = sys.argv[2]
text = path.read_text(encoding="utf-8")

if format_name == "json":
    data = json.loads(text)
    servers = data.get("mcpServers")
elif format_name == "toml":
    try:
        import tomllib
    except ModuleNotFoundError as exc:
        raise SystemExit(f"tomllib unavailable: {exc}") from exc
    data = tomllib.loads(text)
    servers = data.get("mcp_servers")
else:
    raise SystemExit(f"unknown format: {format_name}")

errors = []

secret_patterns = {
    r"ghp_[A-Za-z0-9_]{36,}": "GitHub token",
    r"github_pat_[A-Za-z0-9_]{22,}": "GitHub fine-grained token",
    r"sk-[A-Za-z0-9_]{20,}": "API key",
    r"(?i)(api_key|token|password|private_key)\"?\s*[:=]\s*\"(?!your_|your-|example|.*DO_NOT_COMMIT)[^\"]{6,}\"": "secret-like value",
}
for pattern, label in secret_patterns.items():
    for match in re.finditer(pattern, text):
        sample = match.group(0)
        low = sample.lower()
        if any(marker in low for marker in ("your_", "your-", "example", "do_not_commit")):
            continue
        errors.append(f"{label} appears in {path.name}: value redacted")

if not isinstance(servers, dict) or not servers:
    key_name = "mcpServers" if format_name == "json" else "mcp_servers"
    errors.append(f"{path.name}: {key_name} must be a non-empty object")
else:
    for name, cfg in servers.items():
        if not isinstance(cfg, dict):
            errors.append(f"{name}: server config must be an object")
            continue
        command = cfg.get("command")
        url = cfg.get("url")
        if not command and not url:
            errors.append(f"{name}: missing command/url")
        args = cfg.get("args")
        if args is not None and not isinstance(args, list):
            errors.append(f"{name}: args must be a list")
        cwd = cfg.get("cwd")
        if cwd:
            cwd_s = str(cwd)
            if "\\" in cwd_s or re.match(r"^[A-Za-z]:", cwd_s):
                errors.append(f"{name}: Windows path is not allowed: {cwd_s}")
            elif not (cwd_s.startswith("/") or "ABSOLUTE/PATH" in cwd_s or cwd_s.startswith("$")):
                errors.append(f"{name}: cwd must be absolute: {cwd_s}")
        for arg in args or []:
            if not isinstance(arg, str):
                errors.append(f"{name}: args must contain only strings")
                continue
            if "\\" in arg or re.match(r"^[A-Za-z]:", arg):
                errors.append(f"{name}: Windows path is not allowed in args: {arg}")
            if arg == "/" or arg.startswith(("/root", "/boot", "/sys", "/proc", "/dev")):
                errors.append(f"{name}: dangerous path in args: {arg}")

if errors:
    for error in errors:
        print(error)
    raise SystemExit(1)
PY
}

validate_server_commands() {
  local file="$1"
  local format="$2"
  local server command cwd
  local servers=()

  if [[ "$format" == "json" ]]; then
    mapfile -t servers < <(list_json_servers "$file")
  else
    mapfile -t servers < <(list_toml_servers "$file")
  fi

  for server in "${servers[@]}"; do
    if [[ "$format" == "json" ]]; then
      command="$(json_server_field "$file" "$server" command)"
      cwd="$(json_server_field "$file" "$server" cwd)"
    else
      command="$(toml_server_field "$file" "$server" command)"
      cwd="$(toml_server_field "$file" "$server" cwd)"
    fi

    if [[ -n "$command" ]]; then
      if [[ "$command" == *"/"* ]]; then
        if [[ -x "$command" ]]; then
          verbose "$server command available: $command"
        else
          print_error "$server absolute command not found/executable: $command"
        fi
      elif command -v "$command" >/dev/null 2>&1; then
        verbose "$server command available: $command"
      else
        print_warn "$server command not found in PATH: $command"
      fi
    fi

    if [[ -n "$cwd" && "$cwd" != *"ABSOLUTE/PATH"* && "$cwd" != '$'* ]]; then
      if [[ -d "$cwd" ]]; then
        verbose "$server cwd exists: $cwd"
      else
        print_error "$server cwd does not exist: $cwd"
      fi
    fi
  done
}

validate_json_config_file() {
  local file="$1"
  local label="$2"

  print_header "$label"
  if [[ ! -f "$file" ]]; then
    print_error "$file not found"
    return
  fi

  if json_valid "$file"; then
    print_ok "$file JSON syntax valid"
  else
    print_error "$file has invalid JSON"
    return
  fi

  if validate_security "$file" json; then
    print_ok "$file security checks passed"
  else
    print_error "$file security checks failed"
  fi

  validate_server_commands "$file" json
}

validate_toml_config_file() {
  local file="$1"
  local label="$2"

  print_header "$label"
  if [[ ! -f "$file" ]]; then
    print_error "$file not found"
    return
  fi

  if toml_valid "$file"; then
    print_ok "$file TOML syntax valid"
  else
    print_error "$file has invalid TOML"
    return
  fi

  if validate_security "$file" toml; then
    print_ok "$file security checks passed"
  else
    print_error "$file security checks failed"
  fi

  validate_server_commands "$file" toml
}

if ! command -v python3 >/dev/null 2>&1; then
  print_error "python3 is required for MCP security validation"
  exit 1
fi

print_header "Kryonix MCP validation"
printf 'repo: %s\n\n' "$ROOT"

validate_json_config_file ".mcp.example.json" "Template config"
printf '\n'

if [[ -f ".mcp.json" ]]; then
  validate_json_config_file ".mcp.json" "Local config"
else
  print_warn ".mcp.json not found; only template was validated"
fi

printf '\n'
validate_toml_config_file ".codex/config.toml" "Codex project config"

printf '\n'
print_header "Kryonix CLI validation"
if [[ "$KRYONIX_MCP_SKIP_CLI" == "1" ]]; then
  print_warn "Skipping kryonix mcp check because KRYONIX_MCP_SKIP_CLI=1"
else
  KRYONIX_BIN="${KRYONIX_BIN:-}"
  if [[ -n "$KRYONIX_BIN" ]]; then
    if KRYONIX_MCP_SKIP_CLI=1 "$KRYONIX_BIN" mcp check; then
      print_ok "kryonix mcp check passed"
    else
      print_error "kryonix mcp check failed"
    fi
  elif command -v nix >/dev/null 2>&1; then
    if KRYONIX_MCP_SKIP_CLI=1 nix run "path:$ROOT#kryonix" -- mcp check; then
      print_ok "kryonix mcp check passed"
    else
      print_error "kryonix mcp check failed"
    fi
  elif [[ -x "$ROOT/result/bin/kryonix" ]]; then
    if KRYONIX_MCP_SKIP_CLI=1 "$ROOT/result/bin/kryonix" mcp check; then
      print_ok "kryonix mcp check passed"
    else
      print_error "kryonix mcp check failed"
    fi
  elif command -v kryonix >/dev/null 2>&1; then
    if KRYONIX_MCP_SKIP_CLI=1 kryonix mcp check; then
      print_ok "kryonix mcp check passed"
    else
      print_error "kryonix mcp check failed"
    fi
  else
    print_warn "kryonix command not found; install or build .#kryonix to run system-level validation"
  fi
fi

printf '\n'
print_header "Summary"
if [[ "$EXIT_CODE" -eq 0 ]]; then
  print_ok "MCP validation passed"
else
  print_error "MCP validation failed"
fi

exit "$EXIT_CODE"
