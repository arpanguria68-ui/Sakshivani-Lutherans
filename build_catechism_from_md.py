#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Complete Catechism HTML Builder
Parses catechism.md and generates full responsive HTML
"""
import re
import sys

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def read_md():
    with open('catechism.md', 'r', encoding='utf-8') as f:
        return f.read()

def parse_markdown_to_html(md_content):
    """Convert markdown catechism to HTML"""
    
    # Extract sections
    sections = re.split(r'\n---\n', md_content)
    
    html_sections = []
    
    for section in sections[1:]:  # Skip frontmatter
        # Process each section
        section = section.strip()
        
        # Main headings (# )
        section = re.sub(r'^# (.+)$', r'<h2 class="main-heading">\1</h2>', section, flags=re.MULTILINE)
        
        # Sub headings (## )
        section = re.sub(r'^## (.+)$', r'<h3 class="sub-heading">\1</h3>', section, flags=re.MULTILINE)
        
        # Sub-sub headings (### )
        section = re.sub(r'^### (.+)$', r'<h4 class="question-heading">\1</h4>', section, flags=re.MULTILINE)
        
        # Bold text
        section = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', section)
        
        # Blockquotes (> )
        section = re.sub(r'^> (.+)$', r'<p class="answer-text">\1</p>', section, flags=re.MULTILINE)
        
        # Regular paragraphs
        lines = section.split('\n')
        processed_lines = []
        in_list = False
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # List items
            if line.startswith('* '):
                if not in_list:
                    processed_lines.append('<ul class="duties-list">')
                    in_list = True
                item = line[2:].strip()
                # Remove cite markers for cleaner display
                item = re.sub(r'\[cite_start\]|\[cite:\s*\d+-?\d*\]', '', item)
                processed_lines.append(f'<li>{item}</li>')
            elif line.startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '10.')):
                # Handle numbered lists in appendix
                if in_list:
                    processed_lines.append('</ul>')
                    in_list = False
                item = re.sub(r'^\d+\.\s+', '', line)
                item = re.sub(r'\[cite_start\]|\[cite:\s*\d+-?\d*\]', '', item)
                processed_lines.append(f'<p class="numbered-item">{item}</p>')
            else:
                if in_list:
                    processed_lines.append('</ul>')
                    in_list = False
                    
                # Skip if already HTML tag
                if not line.startswith('<'):
                    # Remove cite markers
                    line = re.sub(r'\[cite_start\]|\[cite:\s*\d+-?\d*\]', '', line)
                    if line:
                        processed_lines.append(line)
                else:
                    processed_lines.append(line)
        
        if in_list:
            processed_lines.append('</ul>')
        
        html_sections.append('\n'.join(processed_lines))
    
    return html_sections

print("Reading catechism.md...")
md_content = read_md()

print("Parsing markdown...")
html_sections = parse_markdown_to_html(md_content)

# Build complete HTML
html = '''<!DOCTYPE html>
<html lang="hi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="लूथर की छोटी धर्मशिक्षा - Luther's Small Catechism in Hindi">
    <title>धर्मशिक्षा - Sakshi Vani</title>
    <link rel="stylesheet" href="style.css">
    <link rel="manifest" href="manifest.json">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;700&family=Noto+Serif+Devanagari:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Noto Serif Devanagari', serif; line-height: 1.8; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); color: #333; padding: 0; margin: 0; }
        .container { max-width: 1000px; margin: 0 auto; padding: 20px; }
        
        /* Header */
        .catechism-header { text-align: center; padding: 50px 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 20px; margin-bottom: 40px; box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3); }
        .catechism-header h1 { font-size: 3rem; margin-bottom: 15px; font-weight: 700; font-family: 'Noto Sans Devanagari', sans-serif; text-shadow: 2px 2px 4px rgba(0,0,0,0.2); }
        .catechism-header p { font-size: 1.3rem; opacity: 0.95; }
        
        /* Table of Contents */
        .toc { background: white; border-radius: 20px; padding: 40px; margin-bottom: 50px; box-shadow: 0 8px 24px rgba(0,0,0,0.1); }
        .toc h2 { color: #667eea; font-size: 2.2rem; margin-bottom: 25px; padding-bottom: 15px; border-bottom: 4px solid #667eea; font-family: 'Noto Sans Devanagari', sans-serif; }
        .toc ul { list-style: none; padding: 0; }
        .toc li { margin: 18px 0; }
        .toc a { color: #333; text-decoration: none; font-size: 1.2rem; display: block; padding: 15px 25px; border-radius: 12px; background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); transition: all 0.3s ease; border-left: 5px solid transparent; }
        .toc a:hover { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; transform: translateX(15px); border-left-color: white; box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4); }
        
        /* Sections */
        .section { background: white; padding: 50px; margin-bottom: 40px; border-radius: 20px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
        .main-heading { color: #667eea; font-size: 2.5rem; margin: 0 0 40px 0; padding-bottom: 20px; border-bottom: 5px solid #667eea; font-family: 'Noto Sans Devanagari', sans-serif; font-weight: 700; }
        .sub-heading { color: #764ba2; font-size: 1.8rem; margin: 40px 0 25px 0; padding: 15px; background: linear-gradient(to right, #f3e5f5, #e1bee7); border-left: 6px solid #764ba2; border-radius: 8px; font-family: 'Noto Sans Devanagari', sans-serif; }
        .question-heading { color: #667eea; font-size: 1.4rem; margin: 30px 0 15px 0; font-weight: 600; padding-left: 15px; border-left: 4px solid #667eea; }
        
        /* Content */
        .answer-text { line-height: 2; font-size: 1.15rem; margin: 15px 0; padding: 20px; background: linear-gradient(135deg, #f5f5f5 0%, #eeeeee 100%); border-left: 5px solid #764ba2; border-radius: 10px; box-shadow: 0 3px 10px rgba(118, 75, 162, 0.1); }
        .numbered-item { font-size: 1.15rem; margin: 20px 0; padding: 18px; background: linear-gradient(to right, #fff9e6, #fef5cd); border-left: 5px solid #f39c12; border-radius: 10px; }
        .duties-list { list-style: none; padding-left: 0; margin: 20px 0; }
        .duties-list li { padding: 15px 20px; margin: 12px 0; background: linear-gradient(to right, #e8f8f5, #d1f2eb); border-left: 5px solid #1abc9c; border-radius: 8px; font-size: 1.1rem; line-height: 1.9; }
        
        strong { color: #2c3e50; font-weight: 700; }
        
        /* Navigation */
        .nav-buttons { position: fixed; bottom: 30px; right: 30px; z-index: 1000; }
        .nav-button { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 35px; border: none; border-radius: 50px; font-size: 1.1rem; font-weight: 600; cursor: pointer; box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4); transition: all 0.3s ease; text-decoration: none; display: inline-block; font-family: 'Noto Sans Devanagari', sans-serif; }
        .nav-button:hover { transform: translateY(-5px); box-shadow: 0 12px 35px rgba(102, 126, 234, 0.5); }
        
        /* Responsive */
        @media (max-width: 768px) {
            .catechism-header h1 { font-size: 2rem; }
            .catechism-header { padding: 35px 20px; }
            .section { padding: 30px 25px; }
            .toc { padding: 30px 20px; }
            .main-heading { font-size: 2rem; }
            .sub-heading { font-size: 1.5rem; }
            .nav-buttons { bottom: 20px; right: 20px; }
            .nav-button { padding: 16px 28px; font-size: 1rem; }
            .toc a { font-size: 1.05rem; padding: 12px 18px; }
        }
        
        @media (max-width: 480px) {
            .container { padding: 15px; }
            .catechism-header h1 { font-size: 1.6rem; }
            .section { padding: 25px 20px; }
            .main-heading { font-size: 1.7rem; }
            .sub-heading { font-size: 1.3rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="catechism-header">
            <h1>लूथर की छोटी धर्मशिक्षा</h1>
            <p>Luther's Small Catechism in Hindi</p>
        </div>
'''

# Add Table of Contents
html += '''
        <div class="toc">
            <h2>विषय सूची</h2>
            <ul>
                <li><a href="#commandments">1. दस आज्ञा (Ten Commandments)</a></li>
                <li><a href="#creed">2. प्रेरितों का विश्वास दर्पण (The Creed)</a></li>
                <li><a href="#prayer">3. प्रभु की प्रार्थना (Lord's Prayer)</a></li>
                <li><a href="#baptism">4. बपतिस्मा का सक्रामेन्त (Holy Baptism)</a></li>
                <li><a href="#communion">5. प्रभुभोज का सक्रामेन्त (Holy Communion)</a></li>
                <li><a href="#confession">6. पाप स्वीकार (Confession)</a></li>
                <li><a href="#appendix1">परिशिष्ट 1: प्रश्नोत्तर</a></li>
                <li><a href="#appendix2">परिशिष्ट 2: दैनिक प्रार्थना</a></li>
                <li><a href="#appendix3">परिशिष्ट 3: घर की पटिया</a></li>
                <li><a href="#appendix4">परिशिष्ट 4: व्यक्तिगत प्रार्थनाएँ</a></li>
            </ul>
        </div>
'''

# Add sections with IDs
section_ids = ['commandments', 'creed', 'prayer', 'baptism', 'communion', 'confession', 
               'appendix1', 'appendix2', 'appendix3', 'appendix4']

for i, section_html in enumerate(html_sections):
    section_id = section_ids[i] if i < len(section_ids) else f'section{i}'
    html += f'<div id="{section_id}" class="section">\n{section_html}\n</div>\n\n'

# Close HTML
html += '''
    </div>
    
    <div class="nav-buttons">
        <a href="index.html" class="nav-button">← गीत (Songs)</a>
    </div>
</body>
</html>'''

# Write to file
print("Writing HTML...")
with open('pwa/catechism.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("✓ Complete catechism page generated!")
print(f"✓ Sections: {len(html_sections)}")
print("✓ File: pwa/catechism.html")
print("✓ Fully responsive with all content from catechism.md")
