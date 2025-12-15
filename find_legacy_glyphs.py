#!/usr/bin/env python3
"""
Find the specific legacy glyphs that were detected
"""
import json
import re

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

legacy_pattern = re.compile(r'[äšðÿ±_›ÂÃ]')
legacy_chars = {}

for song in songs:
    text = song.get('title', '') + '\n' + song.get('lyrics', '')
    
    for match in legacy_pattern.finditer(text):
        char = match.group()
        if char not in legacy_chars:
            legacy_chars[char] = []
        
        context_start = max(0, match.start() - 25)
        context_end = min(len(text), match.end() + 25)
        context = text[context_start:context_end].replace('\n', ' ')
        
        legacy_chars[char].append({
            'song_id': song['id'],
            'title': song['title'],
            'context': context
        })

print(f"Legacy characters found: {len(legacy_chars)}")
print(f"Total instances: {sum(len(v) for v in legacy_chars.values())}\n")

for char, instances in sorted(legacy_chars.items()):
    print(f"\nCharacter '{char}' (U+{ord(char):04X}): {len(instances)} instances")
    for inst in instances[:3]:
        print(f"  Song {inst['song_id']}: ...{inst['context']}...")
