#!/usr/bin/env python3
"""
Comprehensive scanner for ALL remaining Unicode/matra issues
Scans all 353 songs and reports any problematic patterns
"""
import json
import re
from collections import Counter

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

print(f"Scanning {len(songs)} songs for remaining issues...\n")

# Patterns to detect
issue_patterns = {
    'unmapped_chars': re.compile(r'[ð›\u00ad\u200b-\u200f\u202a-\u202e]'),  # Special chars that shouldn't be there
    'extra_visarga': re.compile(r'ः\s*,\s*ः'),  # Multiple visarga with comma
    'halant_matra_wrong': re.compile(r'([क-ह])्([ािीुूृेैोौ])'),  # Still checking this
    'double_halant': re.compile(r'््'),  # Double halant
    'orphan_matra': re.compile(r'(?<![क-हअ-औ०-९\s])[ािीुूृेैोौं]'),  # Matra without base
}

all_issues = {}
issue_counts = Counter()

for song in songs:
    song_id = song['id']
    text = song.get('title', '') + '\n' + song.get('lyrics', '')
    song_issues = []
    
    for issue_type, pattern in issue_patterns.items():
        matches = pattern.finditer(text)
        for match in matches:
            context_start = max(0, match.start() - 20)
            context_end = min(len(text), match.end() + 20)
            context = text[context_start:context_end]
            
            song_issues.append({
                'type': issue_type,
                'match': match.group(),
                'context': context.replace('\n', ' ')
            })
            issue_counts[issue_type] += 1
    
    if song_issues:
        all_issues[song_id] = {
            'title': song['title'],
            'issues': song_issues
        }

# Save report
with open('remaining_issues_report.txt', 'w', encoding='utf-8') as f:
    f.write("="*80 + "\n")
    f.write("COMPREHENSIVE SCAN - REMAINING ISSUES\n")
    f.write("="*80 + "\n\n")
    
    f.write(f"Total songs scanned: {len(songs)}\n")
    f.write(f"Songs with issues: {len(all_issues)}\n")
    f.write(f"Total issues found: {sum(issue_counts.values())}\n\n")
    
    if issue_counts:
        f.write("ISSUE BREAKDOWN:\n")
        f.write("-"*80 + "\n")
        for issue_type, count in issue_counts.most_common():
            f.write(f"{issue_type:25} : {count} instances\n")
        
        f.write("\n\n" + "="*80 + "\n")
        f.write("DETAILED ISSUES BY SONG\n")
        f.write("="*80 + "\n")
        
        for song_id in sorted(all_issues.keys())[:50]:  # First 50 songs
            info = all_issues[song_id]
            f.write(f"\nSong {song_id}: {info['title']}\n")
            f.write("-"*80 + "\n")
            for issue in info['issues'][:5]:  # First 5 issues per song
                f.write(f"  {issue['type']}: '{issue['match']}'\n")
                f.write(f"  Context: ...{issue['context']}...\n\n")
    else:
        f.write("✓ NO ISSUES FOUND! All songs are clean.\n")

print(f"Scan complete!")
print(f"Songs with issues: {len(all_issues)}")
print(f"Total issues: {sum(issue_counts.values())}")
print(f"\nReport saved to: remaining_issues_report.txt")

if issue_counts:
    print(f"\nIssue breakdown:")
    for issue_type, count in issue_counts.most_common():
        print(f"  {issue_type}: {count}")
