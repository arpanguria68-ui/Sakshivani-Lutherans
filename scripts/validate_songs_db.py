#!/usr/bin/env python3
"""Validate the Flutter songs SQLite DB for real Unicode corruption (not false positives)."""

from __future__ import annotations

import re
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "assets" / "Sakshivani_Unicode_Clean.db"

# Real corruption signatures — avoids flagging valid words like तृप्ति / सृष्टि.
PATTERNS: dict[str, re.Pattern[str]] = {
    "legacy_glyphs": re.compile(r"[äšðÿ±_›ÂÃ]"),
    "visarga_hindi": re.compile(r"ः"),
    "ampersand": re.compile(r"&"),
    "halant_before_i_matra": re.compile("\u094d\u093f"),
    "i_matra_before_halant": re.compile("\u093f\u094d"),
    "pavitri_wrong": re.compile(r"पवत्रि"),
    "duplicated_ba": re.compile(r"ब्र्ब"),
}


def main() -> int:
    if not DB_PATH.exists():
        print(f"Missing {DB_PATH}", file=sys.stderr)
        return 1

    conn = sqlite3.connect(DB_PATH)
    issues: dict[int, list[str]] = defaultdict(list)
    try:
        total = conn.execute("SELECT COUNT(*) FROM songs").fetchone()[0]
        for song_id, title, lyrics in conn.execute("SELECT song_id, title, lyrics FROM songs"):
            text = f"{title or ''}\n{lyrics or ''}"
            for name, pattern in PATTERNS.items():
                if pattern.search(text):
                    issues[int(song_id)].append(name)
    finally:
        conn.close()

    print(f"Songs scanned: {total}")
    print(f"Songs with real issues: {len(issues)}")
    if issues:
        for song_id in sorted(issues)[:20]:
            print(f"  #{song_id}: {', '.join(issues[song_id])}")
        return 1

    print("SQLite songs DB passed validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
