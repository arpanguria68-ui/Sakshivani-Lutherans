import json

with open('pwa/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

# Find all songs with & or š
problems = []

for song in songs:
    text = song.get('title', '') + '\n' + song.get('lyrics', '')
    
    if '&' in text or 'š' in text:
        # Find contexts
        lines = text.split('\n')
        for i, line in enumerate(lines):
            if '&' in line or 'š' in line:
                problems.append({
                    'song_id': song['id'],
                    'title': song['title'],
                    'line': line,
                    'has_amp': '&' in line,
                    'has_s_caron': 'š' in line
                })

with open('ampersand_issues.txt', 'w', encoding='utf-8') as f:
    f.write(f"Found {len(problems)} lines with & or š\n\n")
    
    for p in problems[:100]:  # First 100
        f.write(f"Song {p['song_id']}: {p['title']}\n")
        f.write(f"  Line: {p['line']}\n\n")

print(f"Found {len(problems)} problematic lines")
print(f"Report saved to: ampersand_issues.txt")
