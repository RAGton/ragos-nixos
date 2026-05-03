# MCP Security & Validation

This document describes the threat model, restrictions, and validation gates for MCP servers in Kryonix.

## Threat Model

### HIGH Priority

**Secret Exposure in `.mcp.json`**
- **Risk:** API keys, GitHub tokens, SSH keys left in `.mcp.json` → leaked if accidentally committed or exposed
- **Attack:** Attacker steals token, impersonates user on GitHub/APIs
- **Mitigation:** 
  - `.mcp.json` is in `.gitignore` — never committed
  - `kryonix mcp check` scans for exposed secrets (regex: `API_KEY`, `TOKEN`, `private_key`, etc.)
  - Use environment variables (`.env`, `brain.env`) instead
  - Validation fail exit code 1 if secrets detected

**Path Traversal (Filesystem MCP)**
- **Risk:** Agent misconfigures filesystem MCP to point to `/` or sensitive directories
- **Attack:** Attacker reads `/etc/passwd`, `/root/.ssh/`, or project secrets
- **Mitigation:**
  - `kryonix mcp check` validates all paths are absolute and not sensitive system roots
  - Filesystem MCP **must** be bound to vault directory only (e.g., `/home/user/kryonix-vault`)
  - Documentation enforces read-only binding
  - `kryonix mcp check` verifies this constraint

**STDIO Protocol Violation (stdout leaks)**
- **Risk:** MCP server emits debug logs, warnings, or stack traces to stdout → corrupts JSON-RPC protocol
- **Attack:** Agent fails to parse response, fallback to wrong behavior, or crashes
- **Mitigation:**
  - `test_mcp_stdio_clean.py` verifies server.py redirects ALL output to stderr
  - Server uses `logging` module (goes to stderr) + file, NOT `print()`
  - `kryonix mcp doctor` runs round-trip JSON-RPC test, detects stdout pollution
  - Tests fail if any stray output detected

### MEDIUM Priority

**Config Incompatibility**
- **Risk:** User copies `.mcp.json` with non-Linux paths → servers fail to start
- **Mitigation:**
  - `.mcp.example.json` uses placeholders (e.g., `/ABSOLUTE/PATH/TO/vault`)
  - Documentation emphasizes absolute paths + platform-specific formats
  - Validation warns on suspicious path patterns

**External Server Unavailability**
- **Risk:** `mcp-nixos` not installed, or GitHub server needs API token → MCP startup fails
- **Mitigation:**
  - `kryonix mcp doctor` tests each server's availability
  - Validation warns but doesn't fail (graceful fallback)
  - Documentation provides install steps for each server

**Client/server Brain runtime**
- **Risk:** A client host is treated as if it were the Brain server and fails because Ollama, GraphML or LightRAG storage are not local
- **Mitigation:**
  - `inspiron` is a client and uses Glacier through SSH MCP or `KRYONIX_BRAIN_API`
  - `kryonix test client` reports Glacier/runtime absence as `WARN`
  - `kryonix test server` is the strict runtime gate and must be run on Glacier

### LOW Priority

**Tool Misuse (dangerous operations)**
- **Risk:** Agent calls a dangerous MCP tool by mistake (e.g., `delete_file`, `reset_graph`)
- **Attack:** Attacker manipulates agent to call dangerous tool
- **Mitigation:**
  - `test_mcp_tools_safe.py` whitelists only safe tools
  - Dangerous tools (e.g., `graph_reset`, `delete_entry`) are not exposed via MCP
  - Agent CLI maintains safe-by-default tool list

---

## Validation Gates

All MCP changes must pass these gates before deployment:

### 1. Static Config Validation

**File:** `kryonix mcp check` (CLI command)

Checks:
- ✓ `.mcp.json` is valid JSON (syntactically correct)
- ✓ `.mcp.json` has required keys: `mcpServers` (dict)
- ✓ Each server entry has `command` + `args` (required)
- ✓ No exposed secrets: regex scan for `API_KEY=`, `TOKEN=`, `private_key=`, `ghp_`, `sk-`, etc.
- ✓ All filesystem paths are absolute (not relative or `~`)
- ✓ No paths pointing to filesystem root or sensitive system directories
- ✓ `/etc/kryonix` is allowed only as the managed Kryonix checkout on NixOS hosts
- ✓ `.mcp.json` is readable (not world-writable)

**Exit code:** 0 (pass) or 1 (fail with error details)

**Run:** `kryonix mcp check`

### 2. Script-Level Validation

**File:** `scripts/check-mcp.sh` (Bash)

Checks:
- ✓ All the above + JSON parsing via `jq`
- ✓ External server commands exist (e.g., `which uvx`, `which npx`)
- ✓ File existence: `cwd` directories and binary paths exist
- ✓ Summary table with server status

**Exit code:** 0 (all green) or 1 (one or more issues)

**Run:** `./scripts/check-mcp.sh`

### 3. Test Suite

**Files:** `packages/kryonix-brain-lightrag/tests/test_mcp_*.py`

Tests:
- `test_mcp_config_validation.py` — JSON structure, secret detection, path validation
- `test_mcp_stdio_clean.py` — STDIO has no pollution, JSON-RPC responses are pure JSON
- `test_mcp_tools_safe.py` — Tool contract valid, no dangerous tools exposed

**Exit code:** 0 (all pass) or 1 (test failure)

**Run:** `pytest -q packages/kryonix-brain-lightrag/tests/test_mcp_*.py`

### 4. System-Level Check

**Command:** `kryonix mcp check`

Combines all above + detailed diagnostics:
- Calls `kryonix mcp check` (Brain validation)
- Checks all 4 servers are configured or documented as "not yet"
- Summarizes status per server

**Exit code:** 0 (all pass) or 1 (issues found)

**Run:** `kryonix mcp check`

### 5. Doctor (Detailed Diagnostics)

**Command:** `kryonix mcp doctor`

Deep inspection:
- Dumps `.mcp.json` (with secrets masked as `****`)
- Lists available tools per server
- Attempts STDIO round-trip (sends test JSON-RPC, verifies response)
- Shows stderr logs (last 10 lines from each server)
- Reports health per server (✓ / ⚠ / ✗)

**Exit code:** 0 (informational) or 1 (critical issues)

**Run:** `kryonix mcp doctor`

---

## Safety Rules (Mandatory)

### Secrets
- **NEVER** put API keys, tokens, SSH keys in `.mcp.json`
- Use environment variables: `export GITHUB_TOKEN=ghp_...` or add to `.env`
- `.mcp.json` is in `.gitignore` — even so, don't tempt it

### Paths
- **NEVER** use relative paths (e.g., `../vault`, `~/vault`)
- All paths must be **absolute** (e.g., `/home/user/kryonix-vault`)
- Filesystem MCP must be **read-only** and bound to vault (or documents root) only
- No access to `/`, `/etc/`, `/root/`, or system directories

### STDIO
- Server must **redirect all output to stderr** — use `logging` module
- No `print()` statements in production code
- `print()` is only for debug (and redirected to stderr)
- Responses must be **pure JSON-RPC 2.0** (no extra text)

### Files
- `.mcp.json` in `.gitignore` (never committed)
- `.mcp.example.json` is version controlled (template for users)
- Update `.mcp.example.json` when adding new servers

### Tests
- All MCP tests must pass before merge
- New servers require new tests (at minimum: config validation + STDIO)
- Tests verify: JSON contract, secret detection, path validation

---

## Pre-Deployment Checklist

Before declaring MCP work "ready":

- [ ] `kryonix mcp check` passes (no secrets, paths valid)
- [ ] `./scripts/check-mcp.sh` passes (all servers found)
- [ ] `pytest -q packages/kryonix-brain-lightrag/tests/test_mcp_*.py` passes (all green)
- [ ] `kryonix mcp check` passes (system validation)
- [ ] `kryonix mcp doctor` shows all servers ✓ or ⚠ (not ✗)
- [ ] `kryonix test client` passes on `inspiron`; Glacier offline is WARN, not FAIL
- [ ] `kryonix test server` passes on `glacier` before declaring runtime/infra ready
- [ ] `.mcp.json` is in `.gitignore`
- [ ] `.mcp.example.json` is updated and version controlled
- [ ] No secrets in git history: `git log -p --all -S 'API_KEY\|ghp_\|sk-' | head -5` (should be empty)
- [ ] Documentation updated (`docs/mcp/client-configs.md` for new servers)

---

## Incident Response

### If secrets are exposed

1. **Revoke immediately:** Rotate API key, GitHub token, SSH key
2. **Scan history:** `git log -p --all | grep -i 'API_KEY\|TOKEN'`
3. **Remove from git:** `git filter-branch` or `bfg` to purge (coordinate with team)
4. **Audit:** Check server logs for unauthorized access
5. **Document:** Add note to context/SECURITY.md with timeline

### If path traversal attempted

1. **Check config:** Run `kryonix mcp check` to identify bad paths
2. **Fix:** Update `.mcp.json` to bind filesystem MCP to vault only
3. **Verify:** Run `kryonix mcp check` to confirm
4. **Audit:** Review agent logs for suspicious file access

### If STDIO pollution detected

1. **Identify source:** Run `kryonix mcp doctor` to see stderr logs
2. **Fix:** Add `logging.basicConfig(stream=sys.stderr)` to server code
3. **Remove print statements:** Replace `print()` with `logging.debug()`
4. **Verify:** Re-run `pytest test_mcp_stdio_clean.py` — should pass
5. **Test round-trip:** `kryonix mcp doctor` should show clean JSON-RPC

---

## References

- **MCP Protocol:** https://modelcontextprotocol.io/
- **Config Examples:** `.mcp.example.json` in project root
- **Setup Guides:** `docs/mcp/client-configs.md`
- **Architecture:** `docs/mcp/README.md`
