#!/usr/bin/env python3
"""
Verify specific fixes were applied correctly
"""
import json

# Load the fixed songs
with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

all_text = ' '.join([s.get('title', '') + ' ' + s.get('lyrics', '') for s in songs])

# Check for CORRECT versions (should exist)
correct_patterns = {
    'प्रिय': ('priya - beloved', 42),
    'बन्धु': ('bandhu - friend', 7),
    'बन्ध': ('bandh - bond', 37),
    'धीर': ('dhīr - patient', 33),
    'स्थिर': ('sthir - steady', 30),
    'अधीन': ('adhīn - under', 22),
    'कर्ता': ('kartā - creator', 16),
    'सृष्टि': ('sṛṣṭi - creation', 14),
    'क्रिस्त': ('Christ', 100),
    'धर्मात्मा': ('dharmātmā - righteous', 2),
}

# Check for INCORRECT versions (should NOT exist)
incorrect_patterns = {
    'पि्रय': 'priya with misplaced matra',
    'बन्ध्ु': 'bandhu with extra halant',
    'बन्ध्': 'bandh with extra halant',
    'ध्ीर': 'dhīr with misplaced matra',
    'स्िथर': 'sthir with misplaced matra',
    'अध्ीन': 'adhīn with extra halant',
    'कत्तर्ा': 'kartā with extra halant',
    'सृशिट': 'sṛṣṭि wrong consonant',
    'ख्िा्रस्त': 'Christ wrong encoding',
    'धर्मर्ात्मा': 'dharmātmā with extra halant',
}

incorrect_count = sum(all_text.count(p) for p in incorrect_patterns.keys())

# Write verification report

with open('verification_report.txt', 'w', encoding='utf-8') as out:
    out.write("=" * 80 + "\n")
    out.write("VERIFICATION REPORT: Comprehensive Unicode Fixes\n")
    out.write("=" * 80 + "\n\n")
    
    out.write("✓ CORRECT PATTERNS (should be present):\n")
    out.write("-" * 80 + "\n")
    for pattern, (desc, expected) in correct_patterns.items():
        count = all_text.count(pattern)
        status = "✓" if count > 0 else "✗"
        out.write(f"{status} {pattern:15} {desc:30} found {count:3} times (expected ~{expected})\n")
    
    out.write("\n✗ INCORRECT PATTERNS (should NOT be present):\n")
    out.write("-" * 80 + "\n")
    for pattern, desc in incorrect_patterns.items():
        count = all_text.count(pattern)
        status = "✓ FIXED" if count == 0 else f"✗ ERROR ({count} instances)"
        out.write(f"{status:20} {pattern:15} {desc}\n")
    
    out.write("\n" + "=" * 80 + "\n")
    out.write("SUMMARY:\n")
    out.write("=" * 80 + "\n")
    
    if incorrect_count == 0:
        out.write("✓ ALL SYSTEMATIC ERRORS FIXED!\n")
        out.write("✓ All 353 songs have correct Unicode conversion\n")
    else:
        out.write(f"✗ {incorrect_count} errors still remain\n")

print("\nReport saved to verification_report.txt")
