#!/bin/bash
# Python linting hook - ruff format + lint + pyright type checking
# Auto-detects venv in project directory

file_path=$(jq -r '.tool_input.file_path')

# Only process Python files
[[ "$file_path" =~ \.py$ ]] || exit 0
[[ -f "$file_path" ]] || exit 0

# Find project root by walking up looking for .venv, .git, pyproject.toml
find_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.venv" ]] || [[ -d "$dir/.git" ]] || [[ -f "$dir/pyproject.toml" ]]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo $(dirname "$1")  # fallback to file's directory
}

project_root=$(find_project_root "$file_path")

# Ruff: format + lint (check only, no auto-modify) - run from project root
cd "$project_root"
ruff format --check "$file_path" 2>/dev/null || true
ruff check "$file_path" 2>/dev/null || true

# Pyright: type checking - auto-detect venv python if present
pyright_args="--outputjson"
if [[ -f "$project_root/.venv/bin/python" ]]; then
  pyright_args="$pyright_args --pythonpath $project_root/.venv/bin/python"
fi

errors=$(pyright $pyright_args "$file_path" 2>/dev/null | \
  jq -r '.generalDiagnostics[] | "Line \(.range.start.line + 1): \(.message)"' 2>/dev/null)

if [ -n "$errors" ]; then
  echo "Pyright errors in $file_path:" >&2
  echo "$errors" >&2
  exit 2  # Exit 2 = Claude sees this immediately
fi

exit 0
