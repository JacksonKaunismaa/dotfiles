#!/bin/bash
# PreToolUse hook for Bash: BLOCK unquarantined package install commands
# Exit 2 = block the command (message on stderr). Exit 0 = allow.
set -euo pipefail

COMMAND=$(cat | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d.get('input',{})).get('command',''))" 2>/dev/null || echo "")

# Strip comments to prevent bypass via "pip install evil  # uv pip install"
STRIPPED=$(echo "$COMMAND" | sed "s/#[^'\"]*$//")

MSG="Use 'uv pip install' or 'uv add' instead, as a defence against supply chain attacks that steal credentials. Do not attempt to bypass this. If you need a package: (1) look for an existing venv or pyproject.toml in the project, (2) activate it or create one with 'uv venv', (3) use 'uv pip install' to install, (4) if uv is not available, stop and tell the user."

# === BLOCK: --break-system-packages ===
if echo "$STRIPPED" | grep -qF -- '--break-system-packages'; then
    echo "BLOCKED: --break-system-packages is not allowed. $MSG" >&2
    exit 2
fi

# === BLOCK: Any raw pip install (not through uv) ===
if echo "$STRIPPED" | grep -qiE 'pip3?\s+install'; then
    if echo "$STRIPPED" | grep -qE '\buv\s+pip\s+install'; then
        REMAINING=$(echo "$STRIPPED" | sed 's/uv pip install//g; s/uv pip3 install//g')
        if echo "$REMAINING" | grep -qiE 'pip3?\s+install'; then
            echo "BLOCKED: Raw pip install is not allowed. $MSG" >&2
            exit 2
        fi
        exit 0
    fi
    echo "BLOCKED: Raw pip install is not allowed. $MSG" >&2
    exit 2
fi

# === BLOCK: python -m pip install ===
if echo "$STRIPPED" | grep -qiE 'python3?\s+-m\s+pip\s+install'; then
    echo "BLOCKED: python -m pip install is not allowed. $MSG" >&2
    exit 2
fi

# === BLOCK: pip.main() / pip._internal ===
if echo "$STRIPPED" | grep -qE "pip\.main|pip._internal"; then
    echo "BLOCKED: Direct pip API call is not allowed. $MSG" >&2
    exit 2
fi

# === BLOCK: pip download --no-binary / pip wheel (run setup.py) ===
if echo "$STRIPPED" | grep -qE 'pip3?\s+(download.*--no-binary|wheel\b)'; then
    echo "BLOCKED: This command executes arbitrary setup.py code. $MSG" >&2
    exit 2
fi

# === BLOCK: setup.py install / easy_install ===
if echo "$STRIPPED" | grep -qE 'setup\.py\s+install|easy_install\s'; then
    echo "BLOCKED: setup.py install is not allowed. Use 'uv pip install .' or 'uv pip install -e .' instead." >&2
    exit 2
fi

# === WARN: cargo update / cargo add (pulls new unquarantined versions) ===
if echo "$STRIPPED" | grep -qE '\bcargo\s+(update|add)\b'; then
    echo "WARN: This pulls new dependency versions. Run 'cargo cooldown build' afterward to reject any recently-published crates, as a defence against supply chain attacks." >&2
    exit 0
fi

# === WARN: go get -u ===
if echo "$STRIPPED" | grep -qE '\bgo\s+get\s+(-u|\.\.\.)\b'; then
    echo "WARN: No supply chain quarantine exists for Go. Review what changed in go.sum after this — compromised packages may be pulled." >&2
    exit 0
fi

exit 0
