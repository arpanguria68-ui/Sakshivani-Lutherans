#!/usr/bin/env python3
"""
Find all visarga (ः) usage in songs and categorize by context
"""
import json
import re

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

visarga_patterns = {
    'in_title': 0,
    'before_space': 0,
    'before_comma': 0,
    'before_newline': 0,
    'end_of_line': 0,
    'other': 0
}

examples = {
    'in_title': [],
    'before_space': [],
    'end_of_line': []
}

for song in songs:
    # Check title
    if 'ः' in song.get('title', ''):
        visarga_patterns['in_title'] += song['title'].count('ः')
        if len(examples['in_title']) < 5:
            examples['in_title'].append(f"Song {song['id']}: {song['title']}")
    
    # Check lyrics
    lyrics = song.get('lyrics', '')
    if 'ः' in lyrics:
        lines = lyrics.split('\n')
        for line in lines:
            if 'ः' in line:
                # Categorize each visarga
                for match in re.finditer('ः', line):
                    pos = match.start()
                    next_char = line[pos+1] if pos+1 < len(line) else ''
                    
                    if not next_char or next_char == '\n':
                        visarga_patterns['end_of_line'] += 1
                        if len(examples['end_of_line']) < 5:
                            examples['end_of_line'].append(f"Song {song['id']}: ...{line[max(0,pos-20):pos+5]}...")
                    elif next_char == ' ':
                        visarga_patterns['before_space'] += 1
                        if len(examples['before_space']) < 5:
                            examples['before_space'].append(f"Song {song['id']}: ...{line[max(0,pos-20):pos+20]}...")
                    elif next_char == ',':
                        visarga_patterns['before_comma'] += 1
                    else:
                        visarga_patterns['other'] += 1

with open('visarga_analysis.txt', 'w', encoding='utf-8') as f:
    f.write("VISARGA (ः) USAGE ANALYSIS\n")
    f.write("="*80 + "\n\n")
    
    total = sum(visarga_patterns.values())
    f.write(f"Total visarga found: {total}\n\n")
    
    f.write("BREAKDOWN BY CONTEXT:\n")
    f.write("-"*80 + "\n")
    for context, count in visarga_patterns.items():
        f.write(f"{context:20} : {count} instances\n")
    
    f.write("\n\nEXAMPLES:\n")
    f.write("-"*80 + "\n")
    for context, example_list in examples.items():
        if example_list:
            f.write(f"\n{context}:\n")
            for ex in example_list:
                f.write(f"  {ex}\n")

print(f"Total visarga found: {total}")
print(f"Analysis saved to: visarga_analysis.txt")
