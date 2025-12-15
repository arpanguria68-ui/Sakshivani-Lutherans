import json
import re

def parse_catechism_to_json():
    # Read the markdown file
    try:
        with open('catechism.md', 'r', encoding='utf-8') as f:
            md_content = f.read()
    except FileNotFoundError:
        print("Error: catechism.md not found")
        return

    # Split sections by '---'
    # First part is frontmatter
    parts = re.split(r'\n---\n', md_content)
    
    # We expect 11 parts total based on file structure
    # 0: Frontmatter
    # 1: TOC (Skip for JSON, we use metadata)
    # 2: Ten Commandments
    # ...
    
    chapters = []
    
    # Metadata mapping
    sections_meta = [
        {'id': '1-commandments', 'title': '1. दस आज्ञा (Ten Commandments)'},
        {'id': '2-creed', 'title': '2. प्रेरितों का विश्वास (The Creed)'},
        {'id': '3-prayer', 'title': '3. प्रभु की प्रार्थना (Lord\'s Prayer)'},
        {'id': '4-baptism', 'title': '4. बपतिस्मा (Holy Baptism)'},
        {'id': '5-communion', 'title': '5. प्रभुभोज (Holy Communion)'},
        {'id': '6-confession', 'title': '6. पाप स्वीकार (Confession)'},
        {'id': '7-app1', 'title': 'परिशिष्ट 1: प्रश्नोत्तर'},
        {'id': '8-app2', 'title': 'परिशिष्ट 2: दैनिक प्रार्थना'},
        {'id': '9-app3', 'title': 'परिशिष्ट 3: घर की पटिया'},
        {'id': '10-app4', 'title': 'परिशिष्ट 4: व्यक्तिगत प्रार्थनाएँ'},
    ]
    
    for i, meta in enumerate(sections_meta):
        # Find corresponding part (offset by 2 for frontmatter + toc)
        part_idx = i + 2
        if part_idx >= len(parts):
            break
            
        content = parts[part_idx].strip()
        
        # Clean up some markdown artifacts for simpler mobile rendering if needed
        # For now, we keep markdown as is, React Native Markdown renderer can handle it
        
        chapter_obj = {
            'id': meta['id'],
            'title': meta['title'],
            'content': content
        }
        chapters.append(chapter_obj)

    # Write to JSON
    with open('catechism.json', 'w', encoding='utf-8') as f:
        json.dump(chapters, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully converted catechism to JSON with {len(chapters)} chapters.")

if __name__ == '__main__':
    parse_catechism_to_json()
