import sqlite3
import sys
sys.path.insert(0, '.')
from migrate_data_v2 import krutidev_to_unicode
sys.stdout.reconfigure(encoding='utf-8')

# Test problematic words from user
test_cases = [
    ('tx Hk\xd9kkZ', 'जग भर्ता'),  # Expected: "jag bhartā"  
    ('vf/i', 'अधिप'),  # Expected: "adhipa"
    ('/eZ', 'धर्म'),  # Expected: "dharma" - FIXED
]

print("Testing specific conversions:\n")
for raw, expected in test_cases:
    converted = krutidev_to_unicode(raw)
    status = "[OK]" if converted == expected else "[FAIL]"
    print(f"{status} Input: {repr(raw)}")
    print(f"  Expected: {expected}")
    print(f"  Got:      {converted}\n")

# Now scan the actual database for patterns
print("\n" + "="*60)
print("Scanning Song 1 for all words to identify issues:")
print("="*60 + "\n")

db_path = 'assets/Sakshivani_db.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT Title, Lyric FROM tbSakshivani WHERE Song_Id=1")
row = cursor.fetchone()

raw_lyric = row[1]
converted_lyric = krutidev_to_unicode(raw_lyric)

# Split into words and show conversions
raw_words = raw_lyric.split()
converted_words = converted_lyric.split()

# Find mismatched conversions (words with special chars)
issues = []
for i, (raw_word, conv_word) in enumerate(zip(raw_words[:30], converted_words[:30])):  # First 30 words
    if any(ord(c) > 127 for c in raw_word):  # Has special char
        if '\xd9' in raw_word or 'f/' in raw_word or 'vf/' in raw_word or 'Hk' in raw_word:
            issues.append((raw_word, conv_word))

print("Problematic conversions found:")
for raw, conv in issues:
    print(f"  {repr(raw):30} → {conv}")

conn.close()
