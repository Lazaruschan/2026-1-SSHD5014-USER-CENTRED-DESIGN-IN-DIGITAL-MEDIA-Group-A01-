#!/usr/bin/env bash
# Copy tutorial worksheet PDFs from Notes into the site folder.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BASE="$(cd "$ROOT/../.." && pwd)"
SRC="$BASE/Notes/User-centred_Design_in_Digital_Media/User-centred_Design_in_Digital_Media/Tutorial/pdf"
OUT="$ROOT/tutorial-notes"

if [[ ! -d "$SRC" ]]; then
  echo "Error: tutorial PDF source not found: $SRC"
  exit 1
fi

mkdir -p "$OUT"
# Prefer rsync when available; fall back to cp
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --include='*/' --include='*.pdf' --exclude='*' "$SRC/" "$OUT/"
else
  rm -f "$OUT"/*.pdf 2>/dev/null || true
  cp -f "$SRC"/*.pdf "$OUT/"
fi

shopt -s nullglob
pdfs=("$OUT"/*.pdf)
echo "Synced ${#pdfs[@]} tutorial PDF(s) → $OUT"
