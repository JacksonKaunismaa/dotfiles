#!/bin/bash
# LESSOPEN preprocessor: syntax-highlight with bat, skip for large files
# If this produces no output, less falls back to reading the file directly.

# batcat on debian/ubuntu, bat on arch/mac
if command -v bat >/dev/null 2>&1; then
    BAT=bat
elif command -v batcat >/dev/null 2>&1; then
    BAT=batcat
else
    exit 1
fi

MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB

file="$1"
# stat --printf is GNU, stat -f%z is BSD/macOS
size=$(stat --printf='%s' "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null) || exit 1

if [ "$size" -gt "$MAX_SIZE" ]; then
    exit 1
fi

case "$file" in
    *.json|*.jsonl)
        jq . "$file" 2>/dev/null | "$BAT" --color=always --style=plain --paging=never -l json
        ;;
    *)
        "$BAT" --color=always --style=plain --paging=never "$file"
        ;;
esac
