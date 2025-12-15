import sqlite3

db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get all unique characters used in the database
cursor.execute("SELECT Title, Lyric FROM tbSakshivani")
all_text = ""
for row in cursor.fetchall():
    if row[0]:
        all_text += row[0] + " "
    if row[1]:
        all_text += row[1] + " "

# Find unique bytes
unique_chars = sorted(set(all_text))
print(f"Total unique characters: {len(unique_chars)}")
print("\nSpecial characters (non-ASCII):")
for char in unique_chars:
    code = ord(char)
    if code > 127:
        print(f"  {repr(char)} -> U+{code:04X} (byte {code})")

conn.close()
