#!/usr/bin/env bash
# Build a menu-bar .app so Accessibility / Open at Login see a real bundle.
# Default is a universal (arm64 + x86_64) binary. Pass --native for this Mac only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="iMagicRemote"
EXEC_NAME="iMagicRemote"
BUNDLE_ID="com.gbuc.imagicremote.mac"
OUT="${ROOT}/dist/${APP_NAME}.app"
INSTALL=0
UNIVERSAL=1
MACOS_MIN="13.0"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --native) UNIVERSAL=0 ;;
    -h|--help)
      echo "usage: $0 [--install] [--native]"
      echo "  writes ${OUT} (universal arm64+x86_64 unless --native)"
      echo "  --install also copies to /Applications and launches"
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

cd "$ROOT/mac"

build_one() {
  local arch="$1"
  local triple="${arch}-apple-macosx${MACOS_MIN}"
  local scratch=".build/${arch}"
  swift build -c release --product "$EXEC_NAME" \
    --scratch-path "$scratch" \
    --sdk "$SDKROOT" \
    --triple "$triple" >&2
  local bin
  bin="$(swift build -c release --product "$EXEC_NAME" \
    --scratch-path "$scratch" \
    --sdk "$SDKROOT" \
    --triple "$triple" \
    --show-bin-path)"
  printf '%s\n' "${bin}/${EXEC_NAME}"
}

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"

ICONSET="$(mktemp -d /tmp/imagicremote-iconset.XXXXXX)"
trap 'rm -rf "$ICONSET"' EXIT
python3 "$ROOT/scripts/make-mac-icon.py" "$ICONSET"
# iconutil requires the folder name to end in .iconset
NAMED="${ICONSET}.iconset"
mv "$ICONSET" "$NAMED"
ICONSET="$NAMED"
iconutil -c icns -o "$OUT/Contents/Resources/AppIcon.icns" "$ICONSET"

if [[ "$UNIVERSAL" -eq 1 ]]; then
  ARM_BIN="$(build_one arm64)"
  X86_BIN="$(build_one x86_64)"
  lipo -create "$ARM_BIN" "$X86_BIN" -output "$OUT/Contents/MacOS/${EXEC_NAME}"
else
  HOST_ARCH="$(uname -m)"
  cp "$(build_one "$HOST_ARCH")" "$OUT/Contents/MacOS/${EXEC_NAME}"
fi
chmod +x "$OUT/Contents/MacOS/${EXEC_NAME}"
lipo -info "$OUT/Contents/MacOS/${EXEC_NAME}"
cp "$ROOT/mac/Info.plist" "$OUT/Contents/Info.plist"
printf 'APPL????' > "$OUT/Contents/PkgInfo"

# Ad-hoc sign with a designated requirement that is the bundle id only.
# Default ad-hoc DR is a cdhash, which changes every rebuild and drops Accessibility.
REQ="=designated => identifier \"${BUNDLE_ID}\""
codesign --force --sign - --identifier "$BUNDLE_ID" --requirements "$REQ" \
  --timestamp=none "$OUT/Contents/MacOS/${EXEC_NAME}"
codesign --force --sign - --identifier "$BUNDLE_ID" --requirements "$REQ" \
  --timestamp=none "$OUT"

id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$OUT/Contents/Info.plist")"
if [[ "$id" != "$BUNDLE_ID" ]]; then
  echo "bundle id mismatch: $id" >&2
  exit 1
fi

echo "Built $OUT"
echo "Bundle id $BUNDLE_ID — grant Accessibility to “${APP_NAME}”"

if [[ "$INSTALL" -eq 1 ]]; then
  DEST="/Applications/${APP_NAME}.app"
  if [[ ! -w /Applications ]]; then
    DEST="${HOME}/Applications/${APP_NAME}.app"
    mkdir -p "${HOME}/Applications"
  fi
  # Free port 18734 if an older helper is still running.
  killall "$EXEC_NAME" 2>/dev/null || true
  sleep 0.3
  rm -rf "$DEST"
  ditto "$OUT" "$DEST"
  open "$DEST"
  echo "Installed and launched $DEST"
fi
