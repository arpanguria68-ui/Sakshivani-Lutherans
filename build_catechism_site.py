#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import sys 

# Ensure UTF-8 env
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def read_md():
    if not os.path.exists('catechism.md'):
        print("Error: catechism.md not found")
        return None
    with open('catechism.md', 'r', encoding='utf-8') as f:
        return f.read()

def process_markdown_section(text):
    """Convert markdown chunk to HTML"""
    lines = text.split('\n')
    html_lines = []
    
    in_list = False
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Clean cite markers
        line = re.sub(r'\[cite_start\]|\[cite:\s*\d+-?\d*\]', '', line)
        
        # Headers
        if line.startswith('# '):
             # Skip main header in sub-content, handled by template
             pass
        elif line.startswith('## '):
            html_lines.append(f'<h3 class="sub-heading">{line[3:].strip()}</h3>')
        elif line.startswith('### '):
            html_lines.append(f'<h4 class="question-heading">{line[4:].strip()}</h4>')
            
        # Lists
        elif line.startswith('* '):
             if not in_list:
                 html_lines.append('<ul class="duties-list">')
                 in_list = True
             html_lines.append(f'<li>{line[2:].strip()}</li>')
        elif re.match(r'^\d+\.\s+', line):
             # For numbered lists in appendix
             clean_line = re.sub(r'^\d+\.\s+', '', line)
             html_lines.append(f'<p class="numbered-item"><strong>{clean_line}</strong></p>')
        
        # Blockquotes
        elif line.startswith('> '):
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append(f'<div class="answer-text"><p>{line[2:].strip()}</p></div>')
            
        # Bold text
        elif line.startswith('**'):
             if in_list:
                html_lines.append('</ul>')
                in_list = False
             line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)
             html_lines.append(f'<p class="standout-text">{line}</p>')
             
        # Regular text
        else:
             if in_list:
                html_lines.append('</ul>')
                in_list = False
             line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)
             html_lines.append(f'<p>{line}</p>')
             
    if in_list:
        html_lines.append('</ul>')
        
    return '\n'.join(html_lines)

def generate_page(title, content, prev_link=None, next_link=None, is_index=False):
    """Generate full HTML page"""
    
    navigation = ''
    if not is_index:
        nav_items = []
        nav_items.append(f'<a href="../catechism.html" class="nav-button home-btn">🏠 मुख्य (Home)</a>')
        if prev_link:
            nav_items.append(f'<a href="{prev_link}" class="nav-button prev-btn">← पिछला (Prev)</a>')
        if next_link:
            nav_items.append(f'<a href="{next_link}" class="nav-button next-btn">अगला (Next) →</a>')
        
        navigation = f'<div class="page-nav">{" ".join(nav_items)}</div>'

    html = f'''<!DOCTYPE html>
<html lang="hi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} | धर्मशिक्षा</title>
    <link rel="stylesheet" href="../style.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;700&family=Noto+Serif+Devanagari:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body {{ font-family: 'Noto Serif Devanagari', serif; line-height: 1.8; background: #fdfbf7; color: #2c3e50; margin: 0; padding: 0; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }}
        .header h1 {{ margin: 0; font-family: 'Noto Sans Devanagari', sans-serif; font-size: 1.5rem; }}
        .container {{ max-width: 800px; margin: 0 auto; padding: 20px; padding-bottom: 80px; }}
        
        /* Typography */
        h2, h3, h4 {{ font-family: 'Noto Sans Devanagari', sans-serif; color: #667eea; }}
        h2 {{ border-bottom: 3px solid #667eea; padding-bottom: 10px; margin-top: 30px; }}
        h3.sub-heading {{ color: #764ba2; margin-top: 40px; background: #f3e5f5; padding: 10px; border-radius: 8px; }}
        h4.question-heading {{ color: #555; margin-top: 20px; font-weight: bold; }}
        
        /* Elements */
        .answer-text {{ background: #f0f4f8; padding: 15px; border-left: 5px solid #667eea; margin: 15px 0; border-radius: 5px; }}
        .duties-list {{ background: #e0f2f1; padding: 20px 20px 20px 40px; border-radius: 10px; margin: 20px 0; }}
        .duties-list li {{ margin-bottom: 10px; }}
        .numbered-item {{ background: #fff8e1; padding: 10px; border-left: 4px solid #ffb300; margin: 10px 0; }}
        .standout-text {{ font-weight: bold; font-size: 1.1em; color: #2c3e50; margin: 20px 0; }}
        
        /* Navigation */
        .toc-list {{ list-style: none; padding: 0; }}
        .toc-list li {{ margin: 15px 0; }}
        .toc-list a {{ display: block; padding: 15px; background: white; border-radius: 10px; text-decoration: none; color: #333; box-shadow: 0 2px 5px rgba(0,0,0,0.05); transition: transform 0.2s; border-left: 5px solid #667eea; font-weight: bold; font-family: 'Noto Sans Devanagari', sans-serif; }}
        .toc-list a:hover {{ transform: translateX(5px); background: #f8f9fa; }}
        
        .page-nav {{ position: fixed; bottom: 0; left: 0; right: 0; background: white; padding: 15px; box-shadow: 0 -2px 10px rgba(0,0,0,0.1); display: flex; justify-content: space-between; gap: 10px; }}
        .nav-button {{ flex: 1; text-align: center; padding: 12px; border-radius: 8px; text-decoration: none; color: white; font-weight: bold; font-size: 0.9rem; font-family: 'Noto Sans Devanagari', sans-serif; }}
        .home-btn {{ background: #7f8c8d; flex: 0 0 50px; font-size: 1.2rem; }}
        .prev-btn {{ background: #667eea; }}
        .next-btn {{ background: #764ba2; }}
        
    </style>
</head>
<body>
    <div class="header">
        <h1>{title}</h1>
    </div>
    <div class="container">
        {content}
    </div>
    {navigation}
</body>
</html>'''
    return html

def main():
    md_content = read_md()
    if not md_content:
        return

    # Split sections by '---'
    # First part is frontmatter
    parts = re.split(r'\n---\n', md_content)
    
    # parts[0] = frontmatter (skip)
    # parts[1] = TOC (we will regenerate or use as index)
    # parts[2]... = Content sections
    
    # We expect 11 parts total based on file structure
    # 0: Frontmatter
    # 1: TOC (Used for index.html)
    # 2: Ten Commandments
    # 3: Creed
    # 4: Lord's Prayer
    # 5: Baptism
    # 6: Communion
    # 7: Confession
    # 8: Appendix 1
    # 9: Appendix 2
    # 10: Appendix 3
    # 11: Appendix 4
    
    if len(parts) < 3:
        print(f"Error: Expected multiple sections, got {len(parts)}")
        return

    # Ensure output dir
    os.makedirs('pwa/catechism', exist_ok=True)
    
    # Section metadata
    sections_meta = [
        {'id': '1-commandments', 'title': '1. दस आज्ञा (Ten Commandments)', 'file': '1-commandments.html'},
        {'id': '2-creed', 'title': '2. प्रेरितों का विश्वास (The Creed)', 'file': '2-creed.html'},
        {'id': '3-prayer', 'title': '3. प्रभु की प्रार्थना (Lord\'s Prayer)', 'file': '3-prayer.html'},
        {'id': '4-baptism', 'title': '4. बपतिस्मा (Holy Baptism)', 'file': '4-baptism.html'},
        {'id': '5-communion', 'title': '5. प्रभुभोज (Holy Communion)', 'file': '5-communion.html'},
        {'id': '6-confession', 'title': '6. पाप स्वीकार (Confession)', 'file': '6-confession.html'},
        {'id': '7-app1', 'title': 'परिशिष्ट 1: प्रश्नोत्तर', 'file': '7-app1.html'},
        {'id': '8-app2', 'title': 'परिशिष्ट 2: दैनिक प्रार्थना', 'file': '8-app2.html'},
        {'id': '9-app3', 'title': 'परिशिष्ट 3: घर की पटिया', 'file': '9-app3.html'},
        {'id': '10-app4', 'title': 'परिशिष्ट 4: व्यक्तिगत प्रार्थनाएँ', 'file': '10-app4.html'},
    ]
    
    # Generate Index Page
    toc_html = '<ul class="toc-list">'
    for sec in sections_meta:
        toc_html += f'<li><a href="catechism/{sec["file"]}">{sec["title"]}</a></li>'
    toc_html += '</ul>'
    
    index_html = generate_page(
        "धर्मशिक्षा (Catechism)", 
        toc_html, 
        is_index=True
    ).replace('href="../style.css"', 'href="style.css"') # Fix CSS link for root page
    
    # Add back to songs link
    index_html = index_html.replace('</body>', 
        '<div style="text-align: center; margin-top: 30px;"><a href="index.html" style="display: inline-block; padding: 15px 30px; background: #333; color: white; text-decoration: none; border-radius: 25px; font-weight: bold;">← गीत (Songs)</a></div></body>')
    
    with open('pwa/catechism.html', 'w', encoding='utf-8') as f:
        f.write(index_html)
        
    # Process Content Sections
    # parts[2] corresponds to sections_meta[0]
    
    for i, meta in enumerate(sections_meta):
        # Find corresponding part (offset by 2 for frontmatter + toc)
        part_idx = i + 2
        if part_idx >= len(parts):
            break
            
        content_html = process_markdown_section(parts[part_idx])
        
        # Determine nav links
        prev_link = sections_meta[i-1]['file'] if i > 0 else None
        next_link = sections_meta[i+1]['file'] if i < len(sections_meta)-1 else None
        
        full_html = generate_page(meta['title'], content_html, prev_link, next_link)
        
        with open(f'pwa/catechism/{meta["file"]}', 'w', encoding='utf-8') as f:
            f.write(full_html)
            print(f"Generated {meta['file']}")

if __name__ == '__main__':
    main()
