#!/usr/bin/env bash
# Скриншот через headless Chrome: bash tools/shot.sh URL label [width] [height]
# Сохраняет в "temporary screenshots/screenshot-N-label.png"
set -euo pipefail
cd "$(dirname "$0")/.."
URL="$1"; LABEL="${2:-shot}"; W="${3:-1440}"; H="${4:-900}"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
DIR="temporary screenshots"; mkdir -p "$DIR"
N=1; while [ -e "$DIR/screenshot-$N-$LABEL.png" ] || ls "$DIR"/screenshot-$N-*.png >/dev/null 2>&1; do N=$((N+1)); done
OUT="$(cygpath -w "$PWD/$DIR/screenshot-$N-$LABEL.png")"
PROFILE="$(cygpath -w "${TMPDIR:-/tmp}/chrome-shot-profile")"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-first-run --user-data-dir="$PROFILE" \
  --window-size="$W,$H" --virtual-time-budget=4000 --screenshot="$OUT" "$URL" >/dev/null 2>&1 || true
echo "$DIR/screenshot-$N-$LABEL.png"
