#!/usr/bin/env python3
"""
Comprehensive Final Validation Script
Checks all 353 songs for any remaining Unicode issues
"""
import json
import re
from collections import defaultdict

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

# All validation patterns based on our fixes
validation_patterns = {
    # Legacy glyphs (should be ZERO)
    'legacy_glyphs': re.compile(r'[äšðÿ±_›ÂÃ]'),
    
    # Visarga in Hindi (Sanskrit-only, not allowed)
    'visarga_hindi': re.compile(r'ः'),
    
    # Ampersand (should be replaced with -)
    'ampersand': re.compile(r'&'),
    
    # Bracket separator (should be comma)
    'bracket': re.compile(r'\]'),
    
    # Incorrect halants
    'extra_halant_dhn': re.compile(r'ध्न(?!्य)'),  # ध्न but not ध्न्य
    'extra_halant_dhny': re.compile(r'ध्न्य'),
    
    # Matra misplacement
    'pavitri_wrong': re.compile(r'पवत्रि'),
    
    # Duplicated clusters
    'duplicated_ba': re.compile(r'ब्र्ब'),
    
    # Floating matras (invalid)
    'floating_aa_standalone': re.compile(r'(?<![क-ह])\s*ा\s*(?![क-ह])'),
    
    # i-matra after halant+consonant (wrong order)
    'i_after_conjunct_wrong': re.compile(r'([क-ह])्([क-ह])ि(?![क-ह])'),
}

issues_found = defaultdict(list)
clean_songs = []

for song in songs:
    song_id = song['id']
    text = song.get('title', '') + '\n' + song.get('lyrics', '')
    song_issues = []
    
    for pattern_name, pattern in validation_patterns.items():
        matches = list(pattern.finditer(text))
        if matches:
            for match in matches:
                context_start = max(0, match.start() - 20)
                context_end = min(len(text), match.end() + 20)
                context = text[context_start:context_end].replace('\n', ' ')
                
                song_issues.append({
                    'pattern': pattern_name,
                    'match': match.group(),
                    'context': context
                })
    
    if song_issues:
        issues_found[song_id] = {
            'title': song['title'],
            'issues': song_issues
        }
    else:
        clean_songs.append(song_id)

# Generate report
with open('final_validation_report.txt', 'w', encoding='utf-8') as f:
    f.write("="*80 + "\n")
    f.write("FINAL COMPREHENSIVE VALIDATION REPORT\n")
    f.write("="*80 + "\n\n")
    
    f.write(f"Total songs: {len(songs)}\n")
    f.write(f"Clean songs: {len(clean_songs)}\n")
    f.write(f"Songs with issues: {len(issues_found)}\n")
    
    if issues_found:
        # Count by pattern
        pattern_counts = defaultdict(int)
        for info in issues_found.values():
            for issue in info['issues']:
                pattern_counts[issue['pattern']] += 1
        
        f.write("\n\nISSUES BY PATTERN:\n")
        f.write("-"*80 + "\n")
        for pattern, count in sorted(pattern_counts.items()):
            f.write(f"{pattern:30} : {count}\n")
        
        f.write("\n\nDETAILED ISSUES (First 30 songs):\n")
        f.write("-"*80 + "\n")
        
        for song_id in sorted(issues_found.keys())[:30]:
            info = issues_found[song_id]
            f.write(f"\n❌ Song {song_id}: {info['title']}\n")
            for issue in info['issues'][:5]:
                f.write(f"  Pattern: {issue['pattern']}\n")
                f.write(f"  Match: '{issue['match']}'\n")
                f.write(f"  Context: ...{issue['context']}...\n\n")
    else:
        f.write("\n\n" + "="*80 + "\n")
        f.write("✅ VALIDATION PASSED!\n")
        f.write("="*80 + "\n")
        f.write("All 353 songs are Unicode-clean and print-ready!\n")
        f.write("No legacy glyphs, no visarga, no incorrect patterns.\n")

print(f"Validation complete!")
print(f"Clean songs: {len(clean_songs)}/{len(songs)}")
print(f"Songs with issues: {len(issues_found)}")
print(f"\nReport: final_validation_report.txt")
