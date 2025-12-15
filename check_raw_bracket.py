#!/usr/bin/env python3
"""
Check raw database for the character that's becoming ']'
"""
import sqlite3

db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get a song that we know has ']' in converted version
# Based on user's example, let's search for "सनातन"
cursor.execute("SELECT Song_Id, Title, Lyric FROM tbSakshivani WHERE Lyric LIKE '%lukru%' LIMIT 5")
rows = cursor.fetchall()

print("Songs with 'सनातन' pattern:")
print("="*80)

for row in rows:
    song_id, title, lyric = row
    print(f"\nSong {song_id}:")
    print(f"Title: {repr(title)}")
    print(f"\nRaw lyrics (first 300 chars):")
    print(repr(lyric[:300]))
    
    # Find the character before what might be ']'
    if lyric:
        lines = lyric.split('\n')
        for line in lines[:3]:
            print(f"\nLine: {repr(line)}")

conn.close()

# Also check what character code ']' is
print("\n" + "="*80)
print(f"Character ']' has ASCII code: {ord(']')}")
print(f"In hex: {hex(ord(']'))}")
