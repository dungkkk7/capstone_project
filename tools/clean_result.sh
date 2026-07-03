#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULT_DIR="$PROJECT_ROOT/result"

if [ ! -d "$RESULT_DIR" ]; then
    echo "Result directory does not exist: $RESULT_DIR"
    exit 0
fi

echo "Cleaning up $RESULT_DIR (keeping .lifting_cache)..."

# Delete everything inside result/ except .lifting_cache
find "$RESULT_DIR" -mindepth 1 -maxdepth 1 ! -name ".lifting_cache" -exec rm -rf {} +

echo "Clean up completed."
