#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/dist"
mkdir -p "$OUT"
# Tests are Node-only; they must not ship in the IPK.
ares-package "$ROOT/tv" -o "$OUT" -e "test" -e "*.cjs" -e ".DS_Store"
