#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BASE="$(cd "$ROOT/../.." && pwd)"
SRC="$BASE/Notes/User-centred_Design_in_Digital_Media/User-centred_Design_in_Digital_Media"
OUT="$ROOT/slides"
MARP="$ROOT/node_modules/.bin/marp"
EMBED="$ROOT/embed-slide-assets.py"

# Prefer nvm Node if present
if ! command -v node >/dev/null 2>&1; then
  if [[ -d "$HOME/.nvm/versions/node" ]]; then
    LATEST_NODE="$(ls "$HOME/.nvm/versions/node" | sort -V | tail -1)"
    export PATH="$HOME/.nvm/versions/node/$LATEST_NODE/bin:$PATH"
  fi
fi

if [[ ! -x "$MARP" ]]; then
  (cd "$ROOT" && npm install @marp-team/marp-cli --save-dev)
fi

mkdir -p "$OUT"
# Staging copies for Marp relative paths + embed resolver
if [[ -d "$SRC/images" ]]; then
  rsync -a --delete "$SRC/images/" "$OUT/images/"
fi

HTML_FILES=()

for md in "$SRC"/SHDS5014_User-centred_Design_in_Digital_Media_week_*.md; do
  [[ -f "$md" ]] || continue
  base="$(basename "$md")"
  num="$(echo "$base" | sed -E 's/.*week_([0-9]+).*/\1/')"
  # Skip final presentation week (13+)
  if (( 10#$num >= 13 )); then
    echo "[skip] week $num (no published deck)"
    continue
  fi
  num="$(printf '%02d' "$((10#$num))")"
  out_html="$OUT/week-${num}.html"
  "$MARP" "$md" -o "$out_html" --html --allow-local-files
  HTML_FILES+=("$out_html")
done

if [[ ${#HTML_FILES[@]} -eq 0 ]]; then
  echo "Error: no lecture markdown files found under $SRC"
  exit 1
fi

# Inline local images as base64, then drop external asset folders
python3 "$EMBED" --asset-root "$OUT" "${HTML_FILES[@]}"

# Protect slide pages with the shared password gate
for html in "${HTML_FILES[@]}"; do
  if ! grep -q 'src="../auth.js"' "$html"; then
    python3 - "$html" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8", errors="ignore")
if "</body>" in text and "../auth.js" not in text:
    p.write_text(text.replace("</body>", '<script src="../auth.js"></script></body>', 1), encoding="utf-8")
    print(f"[auth] injected {p.name}")
PY
  fi
done

rm -rf "$OUT/images" "$OUT/diagrams"
rm -f "$OUT/week-13.html"

echo "Exported self-contained lecture HTML (weeks 1–12) to $OUT"
