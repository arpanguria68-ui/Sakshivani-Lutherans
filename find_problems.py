import sqlite3

#Test without printing special unicode in output
db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT Lyric FROM tbSakshivani WHERE Song_Id=1")
row = cursor.fetchone()
lyric = row[0]

# Find the word causing issues
words = lyric.split()
for i, word in enumerate(words[:40]):
    if 'Hk' in word and '\xd9' in word:
        print(f"Word {i}: {repr(word)}")
        # Print as hex
        print(f"  Hex: {word.encode('latin-1').hex()}")
        
    if 'vf/i' in word:
        print(f"Word {i}: {repr(word)}")
        print(f"  Hex: {word.encode('latin-1').hex()}")

conn.close()
