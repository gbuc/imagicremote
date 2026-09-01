#!/usr/bin/env bash
# Build downloadable artifacts: universal Mac .app zip + TV .ipk.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(python3 -c "import json; print(json.load(open('${ROOT}/tv/appinfo.json'))['version'])")"
DIST="${ROOT}/dist"
APP="${DIST}/iMagicRemote.app"
ZIP="${DIST}/iMagicRemote-${VERSION}-macos-universal.zip"
IPK="${DIST}/com.gbuc.imagicremote_${VERSION}_all.ipk"

mkdir -p "$DIST"
rm -f "$ZIP" "$IPK"

echo "==> Mac helper (universal)"
"$ROOT/scripts/package-mac.sh"

echo "==> TV ipk"
"$ROOT/scripts/package-tv.sh"

if [[ ! -d "$APP" ]]; then
  echo "missing $APP" >&2
  exit 1
fi
if [[ ! -f "$IPK" ]]; then
  echo "missing $IPK" >&2
  exit 1
fi

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo
echo "Release ${VERSION}:"
echo "  $ZIP"
echo "  $IPK"
ls -lh "$ZIP" "$IPK"
lipo -info "$APP/Contents/MacOS/iMagicRemote"
