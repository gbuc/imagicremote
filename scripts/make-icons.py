#!/usr/bin/env python3
"""Resize assets/app-icon.png to the webOS launcher sizes."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "app-icon.png"
TV = ROOT / "tv"


def sips_resize(dest: Path, size: int) -> None:
  subprocess.check_call(
    ["sips", "-z", str(size), str(size), str(MASTER), "--out", str(dest)],
    stdout=subprocess.DEVNULL,
  )


def main() -> None:
  if not MASTER.is_file():
    print(f"missing master icon: {MASTER}", file=sys.stderr)
    sys.exit(1)
  TV.mkdir(parents=True, exist_ok=True)
  sips_resize(TV / "icon-v5.png", 80)
  sips_resize(TV / "largeIcon-v5.png", 130)


if __name__ == "__main__":
  main()
