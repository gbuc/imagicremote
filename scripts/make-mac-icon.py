#!/usr/bin/env python3
"""Write an .iconset by scaling assets/app-icon.png."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "app-icon.png"


def main() -> None:
  if len(sys.argv) != 2:
    print("usage: make-mac-icon.py ICONSET_DIR", file=sys.stderr)
    sys.exit(2)
  if not MASTER.is_file():
    print(f"missing master icon: {MASTER}", file=sys.stderr)
    sys.exit(1)
  dest = Path(sys.argv[1])
  dest.mkdir(parents=True, exist_ok=True)
  for base in (16, 32, 128, 256, 512):
    for name, size in ((f"icon_{base}x{base}.png", base), (f"icon_{base}x{base}@2x.png", base * 2)):
      subprocess.check_call(
        ["sips", "-z", str(size), str(size), str(MASTER), "--out", str(dest / name)],
        stdout=subprocess.DEVNULL,
      )


if __name__ == "__main__":
  main()
