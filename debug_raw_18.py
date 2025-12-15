import sqlite3

db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get Song 18 To check "Yeshu"
cursor.execute("SELECT Title, Lyric FROM tbSakshivani WHERE Song_Id=18")
row = cursor.fetchone()

if row:
    print("--- RAW TITLE ---")
    print(repr(row[0]))

conn.close()
