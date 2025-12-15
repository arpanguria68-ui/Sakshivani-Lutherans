#!/usr/bin/env python3
"""
Comprehensive matra alignment checker
Scans all 353 songs for matra positioning errors
"""
import json
import re
from collections import Counter

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

print(f"Analyzing {len(songs)} songs for matra issues...")

# Matra position patterns that indicate errors
error_patterns = {
    # Halant before matra (wrong order)
    'halant_before_matra': re.compile(r'([क-ह])्([ािीुूृेैोौ])'),
    
    # Standalone i-matra without consonant
    'standalone_i_matra': re.compile(r'(?<![क-हअ-औ०-९])ि'),
    
    # Double matras (consecutive)
    'double_matra': re.compile(r'[ािीुूृेैोौं]{2,}'),
    
    # Halant at end of word (incomplete conjunct)
    'ending_halant': re.compile(r'्(?=\s|$|[।,॥.!?])'),
    
    # i-matra after consonant+halant (should be before)
    'i_after_halant': re.compile(r'([क-ह])्([क-ह])ि'),
}

issues_found = {}
total_issues = 0

for song in songs:
    song_id = song['id']
    text = song.get('title', '') + ' ' + song.get('lyrics', '')
    song_issues = []
    
    for error_type, pattern in error_patterns.items():
        matches = list(pattern.finditer(text))
        if matches:
            for match in matches:
                context_start = max(0, match.start() - 10)
                context_end = min(len(text), match.end() + 10)
                context = text[context_start:context_end]
                song_issues.append({
                    'type': error_type,
                    'match': match.group(),
                    'context': context,
                    'position': match.start()
                })
    
    if song_issues:
        issues_found[song_id] = {
            'title': song['title'],
            'issues': song_issues
        }
        total_issues += len(song_issues)

# Save detailed report
with open('matra_errors_report.txt', 'w', encoding='utf-8') as f:
    f.write("="*80 + "\n")
    f.write("COMPREHENSIVE MATRA ALIGNMENT ERROR REPORT\n")
    f.write("="*80 + "\n\n")
    
    f.write(f"Total songs analyzed: {len(songs)}\n")
    f.write(f"Songs with issues: {len(issues_found)}\n")
    f.write(f"Total issues found: {total_issues}\n\n")
    
    if not issues_found:
        f.write("✓ NO MATRA ERRORS FOUND! All songs are correct.\n")
    else:
        f.write("="*80 + "\n")
        f.write("DETAILED ISSUES BY SONG\n")
        f.write("="*80 + "\n\n")
        
        for song_id in sorted(issues_found.keys()):
            info = issues_found[song_id]
            f.write(f"\nSong {song_id}: {info['title']}\n")
            f.write("-"*80 + "\n")
            
            for issue in info['issues']:
                f.write(f"  Type: {issue['type']}\n")
                f.write(f"  Error: '{issue['match']}'\n")
                f.write(f"  Context: ...{issue['context']}...\n")
                f.write(f"  Position: {issue['position']}\n\n")
        
        # Summary by error type
        f.write("\n" + "="*80 + "\n")
        f.write("SUMMARY BY ERROR TYPE\n")
        f.write("="*80 + "\n\n")
        
        error_type_counts = Counter()
        for info in issues_found.values():
            for issue in info['issues']:
                error_type_counts[issue['type']] += 1
        
        for error_type, count in error_type_counts.most_common():
            f.write(f"{error_type:30} : {count} issues\n")

print(f"\nAnalysis complete!")
print(f"Songs with issues: {len(issues_found)}")
print(f"Total issues: {total_issues}")
print(f"Report saved to: matra_errors_report.txt")

# Print summary to console
if issues_found:
    print(f"\nTop 10 problematic songs:")
    sorted_songs = sorted(issues_found.items(), key=lambda x: len(x[1]['issues']), reverse=True)
    for song_id, info in sorted_songs[:10]:
        print(f"  Song {song_id}: {len(info['issues'])} issues - {info['title'][:50]}")
