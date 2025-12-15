#!/usr/bin/env python3
"""
Scan for legacy font corruption patterns:
1. Duplicated ब्र्ब / र्ब्र clusters
2. Floating matras (standalone ा ि ी ु ू)
3. Legacy glyphs (ä ÿ _ Â Ã)
"""
import json
import re

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

corruption_patterns = {
    'duplicated_ba': re.compile(r'[बप]्र्[बप]'),  # ब्र्ब or similar
    'floating_aa': re.compile(r'(?<![क-ह])\u093e'),  # ा without consonant
    'floating_i': re.compile(r'(?<![क-ह])\u093f'),  # ि without consonant
    'legacy_glyphs': re.compile(r'[äÿ_ÂÃšð›]'),  # Known legacy chars
}

findings = {}

for song in songs:
    text = song.get('title', '') + '\n' + song.get('lyrics', '')
    song_issues = []
    
    for pattern_name, pattern in corruption_patterns.items():
        matches = list(pattern.finditer(text))
        if matches:
            for match in matches:
                context_start = max(0, match.start() - 15)
                context_end = min(len(text), match.end() + 15)
                context = text[context_start:context_end].replace('\n', ' ')
                
                song_issues.append({
                    'type': pattern_name,
                    'match': match.group(),
                    'context': context
                })
    
    if song_issues:
        findings[song['id']] = {
            'title': song['title'],
            'issues': song_issues
        }

# Save report
with open('legacy_corruption_scan.txt', 'w', encoding='utf-8') as f:
    f.write("LEGACY FONT CORRUPTION SCAN\n")
    f.write("="*80 + "\n\n")
    
    total = sum(len(v['issues']) for v in findings.values())
    f.write(f"Songs with issues: {len(findings)}\n")
    f.write(f"Total issues: {total}\n\n")
    
    if findings:
        issue_counts = {}
        for info in findings.values():
            for issue in info['issues']:
                issue_type = issue['type']
                issue_counts[issue_type] = issue_counts.get(issue_type, 0) + 1
        
        f.write("BREAKDOWN:\n")
        f.write("-"*80 + "\n")
        for issue_type, count in sorted(issue_counts.items()):
            f.write(f"{issue_type:20} : {count}\n")
        
        f.write("\n\nEXAMPLES (First 50 songs):\n")
        f.write("-"*80 + "\n")
        
        for song_id in sorted(findings.keys())[:50]:
            info = findings[song_id]
            f.write(f"\nSong {song_id}: {info['title']}\n")
            for issue in info['issues'][:3]:
                f.write(f"  {issue['type']}: '{issue['match']}'\n")
                f.write(f"  Context: ...{issue['context']}...\n")
    else:
        f.write("✓ NO CORRUPTION FOUND!\n")

print(f"Scan complete: {total} issues in {len(findings)} songs")
print(f"Report: legacy_corruption_scan.txt")
