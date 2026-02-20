#!/bin/bash
# LESSOPEN preprocessor: syntax-highlight with bat, skip for large files
# If this produces no output, less falls back to reading the file directly.

MAX_SIZE=$((20 * 1024 * 1024))  # 20 MB

file="$1"
size=$(stat --printf='%s' "$file" 2>/dev/null) || exit 1

if [ "$size" -gt "$MAX_SIZE" ]; then
    exit 1
fi

exec bat --color=always --style=plain --paging=never "$file"
