import sqlite3
import json

# Check raw DB
db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get first 5 songs to analyze
cursor.execute("SELECT Song_Id, Title, Lyric FROM tbSakshivani LIMIT 50")
rows = cursor.fetchall()

with open('bracket_analysis.txt', 'w', encoding='utf-8') as f:
    f.write("Analyzing raw Chanakya text for ']' character source\n")
    f.write("="*80 + "\n\n")
    
    # Check each song
    for song_id, title, lyric in rows:
        if lyric and (']' in lyric or ']' in repr(lyric)):
            f.write(f"\nSong {song_id}: {title}\n")
            f.write(f"Raw hex: {lyric[:200].encode('latin-1', errors='replace').hex()}\n")
            f.write(f"Contains ']': {']' in lyric}\n")
            f.write(f"First 200 chars: {repr(lyric[:200])}\n")
            f.write("-"*80 + "\n")

conn.close()

# Also check converted
with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

with open('bracket_analysis.txt', 'a', encoding='utf-8') as f:
    f.write("\n\n" + "="*80 + "\n")
    f.write("CONVERTED SONGS WITH ']' SYMBOL\n")
    f.write("="*80 + "\n\n")
    
    count = 0
    for song in songs:
        if ']' in song.get('lyrics', ''):
            f.write(f"\nSong {song['id']}: {song['title']}\n")
            lyrics = song['lyrics']
            # Find lines with ]
            for line in lyrics.split('\n')[:10]:
                if ']' in line:
                    f.write(f"  Line: {line}\n")
            count += 1
            if count >= 10:
                break

print("Analysis saved to bracket_analysis.txt")
