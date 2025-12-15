#!/usr/bin/env python3
"""
Comprehensive Unicode error analyzer for Sakshi Vani songs.
Finds all systematic conversion errors across all 353 songs.
"""
import json
import re
from collections import Counter

# Load converted songs
with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

print(f"Analyzing {len(songs)} songs for Unicode errors...\n")

# Pattern detectors
extra_halant_pattern = re.compile(r'([क-ह])्([क-ह])्([ा-ौं-ः])')  # Extra halant before matra
misplaced_matra_pattern = re.compile(r'([ा-ौं-ः]{2,})')  # Consecutive matras
wrong_conjunct_pattern = re.compile(r'([क-ह])्([ािीुूृेैोौं])्')  # Halant + matra + halant

# Specific problematic sequences
problematic_words = Counter()
extra_halants = Counter()
weird_sequences = Counter()

for song in songs:
    text = song.get('title', '') + ' ' + song.get('lyrics', '')
    
    # Find words with potential issues
    words = text.split()
    for word in words:
        # Check for extra halants (र्, त्, etc. appearing multiple times)
        if word.count('्') > 3:  # More than 3 halants is suspicious
            problematic_words[word] += 1
        
        # Check for specific bad patterns
        if 'र्र्' in word or 'त्त्' in word or 'म्म्' in word:
            extra_halants[word] += 1
        
        # Check for matra + halant (wrong order)
        if re.search(r'[ािीुूृेैोौं]्[क-ह]', word):
            weird_sequences[word] += 1
        
        # Check for doubled halants
        if '््' in word:
            extra_halants[word] += 1

# Count common problematic patterns
all_text = ' '.join([s.get('title', '') + ' ' + s.get('lyrics', '') for s in songs])

patterns = {
    'पि्रय': all_text.count('पि्रय'),
    'सृशिट': all_text.count('सृशिट'),
    'कत्तर्ा': all_text.count('कत्तर्ा'),
    'अध्िकार': all_text.count('अध्िकार'),
    'अध्ीन': all_text.count('अध्ीन'),
    'बन्ध्ु': all_text.count('बन्ध्ु'),
    'बन्ध्': all_text.count('बन्ध्'),
    'स्िथर': all_text.count('स्िथर'),
    'ध्ीर': all_text.count('ध्ीर'),
    'स्रपा': all_text.count('स्रपा'),
    'पि्रत': all_text.count('पि्रत'),
    'जगभतर्ा': all_text.count('जगभतर्ा'),
    'सृशट': all_text.count('सृशट'),
}

# Save detailed results to file (skip console output due to encoding issues)
with open('error_analysis.txt', 'w', encoding='utf-8') as out:
    out.write("=" * 70 + "\n")
    out.write("COMPREHENSIVE UNICODE ERROR ANALYSIS\n")
    out.write("=" * 70 + "\n\n")
    
    out.write("TOP 50 WORDS WITH EXTRA HALANTS:\n")
    out.write("=" * 70 + "\n")
    for word, count in extra_halants.most_common(50):
        out.write(f"{word:40} (appears {count} times)\n")
    
    out.write("\n" + "=" * 70 + "\n")
    out.write("TOP 50 WORDS WITH WEIRD SEQUENCES:\n")
    out.write("=" * 70 + "\n")
    for word, count in weird_sequences.most_common(50):
        out.write(f"{word:40} (appears {count} times)\n")
    
    out.write("\n" + "=" * 70 + "\n")
    out.write("TOP 50 SUSPICIOUS WORDS (4+ halants):\n")
    out.write("=" * 70 + "\n")
    for word, count in problematic_words.most_common(50):
        out.write(f"{word:40} (appears {count} times)\n")
    
    out.write("\n" + "=" * 70 + "\n")
    out.write("COMMON PROBLEMATIC PATTERNS:\n")
    out.write("=" * 70 + "\n")
    
    for pattern, count in sorted(patterns.items(), key=lambda x: -x[1]):
        if count > 0:
            out.write(f"{pattern:30} appears {count} times\n")

print("\n" + "=" * 70)
print(f"ANALYSIS COMPLETE - Results saved to error_analysis.txt")
print(f"Found {len(extra_halants)} words with extra halants")
print(f"Found {len(weird_sequences)} words with weird sequences")
print(f"Found {len(problematic_words)} suspicious words")
print("=" * 70)
