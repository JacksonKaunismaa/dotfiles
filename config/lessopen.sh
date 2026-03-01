#!/bin/bash
# LESSOPEN preprocessor: syntax-highlight with bat, skip for large files
# If this produces no output, less falls back to reading the file directly.

MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB

file="$1"
size=$(stat --printf='%s' "$file" 2>/dev/null) || exit 1

if [ "$size" -gt "$MAX_SIZE" ]; then
    exit 1
fi

case "$file" in
    *.json)
        jq . "$file" 2>/dev/null | bat --color=always --style=plain --paging=never -l json
        ;;
    *.jsonl)
        jq . "$file" 2>/dev/null | bat --color=always --style=plain --paging=never -l json
        ;;
    *)
        bat --color=always --style=plain --paging=never "$file"
        ;;
esac
