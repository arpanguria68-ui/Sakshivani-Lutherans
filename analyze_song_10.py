import sqlite3
import json

# Check raw database for Song 10
db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT Song_Id, Title, Lyric FROM tbSakshivani WHERE Song_Id=10")
row = cursor.fetchone()

with open('song_10_analysis.txt', 'w', encoding='utf-8') as f:
    if row:
        song_id, title, lyric = row
        f.write("="*80 + "\n")
        f.write("SONG 10 ANALYSIS\n")
        f.write("="*80 + "\n\n")
        
        f.write("RAW CHANAKYA TITLE:\n")
        f.write(f"{repr(title)}\n\n")
        
        f.write("RAW CHANAKYA LYRICS (first 500 chars):\n")
        f.write(f"{repr(lyric[:500])}\n\n")
        
        f.write("-"*80 + "\n")
        f.write("FULL RAW LYRICS:\n")
        f.write("-"*80 + "\n")
        f.write(lyric + "\n")

conn.close()

# Also check converted version
with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

song_10 = [s for s in songs if s['id'] == 10][0]

with open('song_10_analysis.txt', 'a', encoding='utf-8') as f:
    f.write("\n\n" + "="*80 + "\n")
    f.write("CONVERTED UNICODE VERSION\n")
    f.write("="*80 + "\n\n")
    
    f.write(f"Title: {song_10['title']}\n\n")
    f.write("Lyrics:\n")
    f.write(song_10['lyrics'])

print("Analysis saved to song_10_analysis.txt")
