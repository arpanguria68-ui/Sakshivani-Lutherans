#!/usr/bin/env python3
"""
Extract ONLY real matra errors (halant_before_matra and standalone_i_matra)
These indicate incorrect matra positioning that needs fixing
"""
import json
import re
from collections import Counter, defaultdict

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

# Only the REAL error patterns
real_errors = {
    # Halant before matra (DEFINITELY wrong - matra should come before halant)
    'halant_before_matra': re.compile(r'([क-ह])्([ािीुूृेैोौ])'),
    
    # Standalone i-matra after halant (wrong position)
    'standalone_i_after_halant': re.compile(r'्ि(?![क-ह])'),
}

issues_by_pattern = defaultdict(Counter)
songs_to_fix = {}

for song in songs:
    song_id = song['id']
    text = song.get('title', '') + ' ' + song.get('lyrics', '')
    
    for error_type, pattern in real_errors.items():
        matches = list(pattern.finditer(text))
        if matches:
            for match in matches:
                wrong_text = match.group()
                issues_by_pattern[error_type][wrong_text] += 1
                
                if song_id not in songs_to_fix:
                    songs_to_fix[song_id] = []
                
                context_start = max(0, match.start() - 15)
                context_end = min(len(text), match.end() + 15)
                context = text[context_start:context_end]
                
                songs_to_fix[song_id].append({
                    'type': error_type,
                    'wrong': wrong_text,
                    'context': context
                })

# Generate fix mappings
with open('real_matra_fixes.txt', 'w', encoding='utf-8') as f:
    f.write("="*80 + "\n")
    f.write("REAL MATRA ERRORS TO FIX\n")
    f.write("="*80 + "\n\n")
    
    f.write(f"Total songs with REAL errors: {len(songs_to_fix)}\n\n")
    
    f.write("PATTERNS TO FIX:\n")
    f.write("-"*80 + "\n\n")
    
    all_fixes = []
    
    for error_type, patterns in issues_by_pattern.items():
        f.write(f"\n{error_type}:\n")
        for wrong, count in patterns.most_common():
            # Generate correct version
            if error_type == 'halant_before_matra':
                # Pattern: consonant + halant + matra
                # Fix: consonstant + matra + halant (swap matra and halant)
                consonant = wrong[0]
                matra = wrong[2]
                correct = consonant + matra + '्'
            elif error_type == 'standalone_i_after_halant':
                # Just remove standalone i-matra after halant
                correct = '्'  # Just the halant
            else:
                correct = wrong  # No change
            
            f.write(f"  '{wrong}' → '{correct}' ({count} times)\n")
            all_fixes.append((wrong, correct))
    
    f.write("\n\n" + "="*80 + "\n")
    f.write("PYTHON FIX CODE:\n")
    f.write("="*80 + "\n\n")
    
    f.write("word_fixes = [\n")
    for wrong, correct in all_fixes:
        f.write(f"    ('{wrong}', '{correct}'),\n")
    f.write("]\n")

print(f"\nReal errors found: {sum(len(v) for v in songs_to_fix.values())}")
print(f"Songs affected: {len(songs_to_fix)}")
print(f"Unique patterns: {sum(len(v) for v in issues_by_pattern.values())}")
print(f"\nFix mappings saved to: real_matra_fixes.txt")
