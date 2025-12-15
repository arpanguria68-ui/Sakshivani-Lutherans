#!/usr/bin/env python3
"""
Find and analyze the ']' symbol usage in songs
"""
import json

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

all_text = ' '.join([s.get('title', '') + ' ' + s.get('lyrics', '') for s in songs])

bracket_count = all_text.count(']')
print(f"Found {bracket_count} instances of ']' across all songs")

# Find songs with brackets
songs_with_bracket = []
for song in songs:
    text = song.get('title', '') + ' ' + song.get('lyrics', '')
    if ']' in text:
        count = text.count(']')
        songs_with_bracket.append((song['id'], song['title'], count))

print(f"\n{len(songs_with_bracket)} songs contain the ']' symbol\n")

# Show first 10 examples
print("First 10 songs with ']':")
for song_id, title, count in songs_with_bracket[:10]:
    print(f"Song {song_id}: {title} ({count} instances)")

# Find the actual context
print("\n" + "="*80)
print("CONTEXT EXAMPLES:")
print("="*80)

for song in songs[:20]:
    lyrics = song.get('lyrics', '')
    if ']' in lyrics:
        # Show lines with brackets
        lines = lyrics.split('\n')
        for line in lines[:5]:
            if ']' in line:
                print(f"\nSong {song['id']}: {song['title']}")
                print(f"  '{line}'")
                break
