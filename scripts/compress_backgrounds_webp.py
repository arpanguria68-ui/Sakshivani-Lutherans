"""Convert verse background PNGs to WebP to shrink the Android bundle."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BG_DIR = ROOT / "assets" / "backgrounds"
QUALITY = 82


def main() -> None:
    if not BG_DIR.is_dir():
        raise SystemExit(f"Missing directory: {BG_DIR}")

    saved_bytes = 0
    for png in sorted(BG_DIR.glob("*.png")):
        webp = png.with_suffix(".webp")
        try:
            with Image.open(png) as img:
                img.save(webp, "WEBP", quality=QUALITY, method=6)
        except OSError as e:
            print(f"SKIP {png.name}: {e}")
            continue
        before = png.stat().st_size
        after = webp.stat().st_size
        saved_bytes += before - after
        print(f"{png.name}: {before/1_048_576:.2f} MB -> {after/1_048_576:.2f} MB")
        png.unlink()

    print(f"Total saved: {saved_bytes/1_048_576:.2f} MB")


if __name__ == "__main__":
    main()
