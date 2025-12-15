#!/usr/bin/env python3
"""
Create a clean, well-structured Unicode database from the cleaned songs.json
"""
import json
import sqlite3
import os

# Load cleaned data
with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

# Create new clean database
db_file = 'assets/Sakshivani_Unicode_Clean.db'

# Remove old file if exists
if os.path.exists(db_file):
    os.remove(db_file)

# Create connection
conn = sqlite3.connect(db_file)
cursor = conn.cursor()

# Create well-structured table with proper schema
cursor.execute('''
CREATE TABLE songs (
    song_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    lyrics TEXT NOT NULL,
    category TEXT,
    reference TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
''')

# Create indexes for better query performance
cursor.execute('CREATE INDEX idx_category ON songs(category)')
cursor.execute('CREATE INDEX idx_title ON songs(title)')
cursor.execute('CREATE INDEX idx_reference ON songs(reference)')

# Create full-text search table for lyrics
cursor.execute('''
CREATE VIRTUAL TABLE songs_fts USING fts5(
    title,
    lyrics,
    category,
    content=songs,
    content_rowid=song_id
)
''')

# Insert all cleaned data
print(f"Inserting {len(songs)} songs into database...")

for song in songs:
    cursor.execute('''
        INSERT INTO songs (song_id, title, lyrics, category, reference)
        VALUES (?, ?, ?, ?, ?)
    ''', (
        song['id'],
        song['title'],
        song['lyrics'],
        song.get('category', ''),
        song.get('reference', '')
    ))
    
    # Also insert into FTS table
    cursor.execute('''
        INSERT INTO songs_fts (rowid, title, lyrics, category)
        VALUES (?, ?, ?, ?)
    ''', (
        song['id'],
        song['title'],
        song['lyrics'],
        song.get('category', '')
    ))

# Create metadata table
cursor.execute('''
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT
)
''')

cursor.execute('''
    INSERT INTO metadata (key, value) VALUES 
    ('version', 'v20_unicode_clean'),
    ('total_songs', ?),
    ('encoding', 'UTF-8'),
    ('conversion_date', datetime('now')),
    ('corrections_applied', '2220+'),
    ('source', 'Chanakya to Unicode conversion')
''', (len(songs),))

# Commit and close
conn.commit()

# Verify
cursor.execute('SELECT COUNT(*) FROM songs')
count = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM songs_fts')
fts_count = cursor.fetchone()[0]

print(f"\n✅ Database created successfully!")
print(f"   Location: {db_file}")
print(f"   Songs: {count}")
print(f"   FTS entries: {fts_count}")
print(f"   Encoding: UTF-8")
print(f"   Status: Production-ready")

# Show sample
cursor.execute('SELECT song_id, title, reference FROM songs LIMIT 5')
print(f"\n📋 Sample entries:")
for row in cursor.fetchall():
    print(f"   {row[0]:3}. {row[1][:50]:50} | {row[2]}")

conn.close()

print(f"\n🎉 Clean Unicode database ready for production!")
