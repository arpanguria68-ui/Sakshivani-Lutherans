"""Apply known Devanagari matra ordering fixes to the bundled songs SQLite DB."""

from __future__ import annotations

import shutil
import sqlite3
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "assets" / "Sakshivani_Unicode_Clean.db"

# Halant-before-matra and similar legacy corruption patterns.
WORD_FIXES: list[tuple[str, str]] = [
    ("क्ि", "कि"),
    ("ध्ि", "धि"),
    ("र्ी", "री"),
    ("न्ि", "नि"),
    ("श्ि", "शि"),
    ("ख्ि", "खि"),
    ("ध्ू", "धू"),
    ("र्ा", "रा"),
    ("ध्े", "धे"),
    ("र्ो", "रो"),
    ("ध्ी", "धी"),
    ("ध्ु", "धु"),
    ("भ्ि", "भि"),
    ("त्ि", "ति"),
    ("र्ि", "रि"),
    ("ग्ि", "गि"),
    ("थ्ि", "थि"),
    ("स्ि", "सि"),
    ("प्ि", "पि"),
    ("घ्ि", "घि"),
    ("म्ि", "मि"),
    ("र्ु", "रु"),
    ("ष्ि", "षि"),
    ("भ्ु", "भु"),
    ("ध्ै", "धै"),
    ("स्ा", "सा"),
    # Standalone floating aa matra after halant clusters (common OCR/export bug).
    ("्ा", "ा"),
]


def normalize_fixes() -> list[tuple[str, str]]:
    return [
        (unicodedata.normalize("NFC", bad), unicodedata.normalize("NFC", good))
        for bad, good in WORD_FIXES
    ]


def apply_text_fixes(text: str, fixes: list[tuple[str, str]]) -> str:
    for bad, good in fixes:
        text = text.replace(bad, good)
    return text


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(f"Missing database: {DB_PATH}")

    backup = DB_PATH.with_suffix(".db.bak")
    if not backup.exists():
        shutil.copy2(DB_PATH, backup)
        print(f"Backup written to {backup}")

    fixes = normalize_fixes()
    conn = sqlite3.connect(DB_PATH)
    try:
        tables = [
            row[0]
            for row in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
        ]
        print("Tables:", tables)

        text_columns: list[tuple[str, str]] = []
        for table in tables:
            if table.startswith("songs_fts"):
                continue
            for row in conn.execute(f"PRAGMA table_info({table})"):
                col_name = row[1]
                col_type = (row[2] or "").upper()
                if col_type in {"TEXT", "CLOB"} or "CHAR" in col_type:
                    text_columns.append((table, col_name))

        total_rows = 0
        total_fields = 0
        for table, column in text_columns:
            rows = conn.execute(
                f"SELECT rowid, {column} FROM {table} WHERE {column} IS NOT NULL"
            ).fetchall()
            for rowid, value in rows:
                if not isinstance(value, str) or not value:
                    continue
                fixed = apply_text_fixes(value, fixes)
                if fixed != value:
                    conn.execute(
                        f"UPDATE {table} SET {column}=? WHERE rowid=?",
                        (fixed, rowid),
                    )
                    total_fields += 1
                total_rows += 1

        conn.commit()
        print(f"Scanned {total_rows} text fields; updated {total_fields}.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
