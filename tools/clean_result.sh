#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULT_DIR="$PROJECT_ROOT/result"

if [ ! -d "$RESULT_DIR" ]; then
    echo "Result directory does not exist: $RESULT_DIR"
    exit 0
fi

# Get list of directories/files to keep by parsing the cache index JSON
KEEP_LIST=$(python3 -c '
import os, json, sys
result_dir = sys.argv[1]
cache_index = os.path.join(result_dir, ".lifting_cache", "cache_index.json")
keep = {".lifting_cache"}
if os.path.exists(cache_index):
    try:
        with open(cache_index, "r") as f:
            data = json.load(f)
            for entry in data.values():
                for key in ["bc_path", "ll_path", "cfg_path"]:
                    path = entry.get(key)
                    if path and path.startswith(result_dir):
                        rel = os.path.relpath(path, result_dir)
                        parts = rel.split(os.sep)
                        if parts and parts[0] != "..":
                            keep.add(parts[0])
    except Exception as e:
        sys.stderr.write(f"Warning: Failed to parse cache index: {e}\n")
for item in sorted(keep):
    print(item)
' "$RESULT_DIR")

echo "Keeping the following cached/protected directories:"
echo "$KEEP_LIST"
echo "Cleaning up other directories/files in $RESULT_DIR..."

# Convert KEEP_LIST to an associative array for fast lookup
declare -A KEEP_MAP
while IFS= read -r line; do
    if [ -n "$line" ]; then
        KEEP_MAP["$line"]=1
    fi
done <<< "$KEEP_LIST"

# Clean non-hidden files and directories
for file in "$RESULT_DIR"/*; do
    if [ -e "$file" ] || [ -L "$file" ]; then
        base="$(basename "$file")"
        if [ -z "${KEEP_MAP["$base"]:-}" ]; then
            rm -rf "$file"
        fi
    fi
done

# Clean hidden files and directories (excluding ., .., and cached folders)
for file in "$RESULT_DIR"/.*; do
    if [ -e "$file" ] || [ -L "$file" ]; then
        base="$(basename "$file")"
        if [ "$base" != "." ] && [ "$base" != ".." ]; then
            if [ -z "${KEEP_MAP["$base"]:-}" ]; then
                rm -rf "$file"
            fi
        fi
    fi
done

echo "Clean up completed."
