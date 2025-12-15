import sqlite3

db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get Song 15 which showed errors in the screenshot
cursor.execute("SELECT Title, Lyric FROM tbSakshivani WHERE Song_Id=15")
row = cursor.fetchone()

if row:
    print("--- RAW TITLE ---")
    print(repr(row[0]))
    print("\n--- RAW LYRIC ---")
    print(repr(row[1]))

conn.close()
