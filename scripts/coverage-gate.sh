#!/bin/bash
# Enforce a minimum line coverage on Recito's non-View code.
#
# Usage: scripts/coverage-gate.sh <path.xcresult> [--min 0.80]
set -euo pipefail

usage() {
  echo "usage: $0 <path.xcresult> [--min FRACTION]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
RESULT="$1"
shift
MIN="0.80"
while [ $# -gt 0 ]; do
  case "$1" in
    --min)
      [ $# -ge 2 ] || { echo "error: --min needs a value" >&2; usage; }
      MIN="$2"
      shift 2
      ;;
    *) echo "error: unknown argument: $1" >&2; usage ;;
  esac
done

if [ ! -d "$RESULT" ]; then
  echo "error: result bundle not found: $RESULT" >&2
  exit 2
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

REPORT="$(xcrun xccov view --report --json "$RESULT")" || {
  echo "error: xccov could not read coverage from $RESULT (was it run with -enableCodeCoverage YES?)" >&2
  exit 2
}

printf '%s' "$REPORT" | python3 -I "$HERE/coverage_gate.py" --min "$MIN" --root "$ROOT"
