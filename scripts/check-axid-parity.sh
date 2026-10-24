#!/bin/bash
# Fail when RecitoUITests/Support/AXID.swift drifts from the app's identifier
# files. Compares the sorted set of identifier string literals (declared on
# `static` lines) on both sides.
#
# Usage: scripts/check-axid-parity.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_FILES=(
  "$ROOT/Recito/App/AccessibilityID.swift"
  "$ROOT/Recito/Views/Reader/ReaderAXID.swift"
  "$ROOT/Recito/Views/VersePane/VersePaneAXID.swift"
  "$ROOT/Recito/Views/Library/LibraryAccessibilityIDs.swift"
  "$ROOT/Recito/Views/Sheets/SheetAccessibilityIDs.swift"
)
TEST_FILE="$ROOT/RecitoUITests/Support/AXID.swift"

literals() {
  grep -h 'static' "$@" | grep -o '"[a-z][A-Za-z]*\.[^"]*"' | sort -u
}

for f in "${APP_FILES[@]}" "$TEST_FILE"; do
  [ -f "$f" ] || { echo "error: missing $f" >&2; exit 2; }
done

APP="$(literals "${APP_FILES[@]}")"
TEST="$(literals "$TEST_FILE")"

if DIFF="$(diff <(printf '%s\n' "$APP") <(printf '%s\n' "$TEST"))"; then
  echo "AXID parity OK ($(printf '%s\n' "$APP" | wc -l | tr -d ' ') identifiers)"
else
  echo "AXID drift (< app only, > UI tests only):" >&2
  echo "$DIFF" >&2
  exit 1
fi
