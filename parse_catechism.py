#!/usr/bin/env python3
"""
Parse the catechism text file and generate complete HTML
"""
import re

def parse_catechism_file(filepath):
    """Parse the catechism text file into structured sections"""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split into major sections
    sections = {
        'toc': '',
        'commandments': [],
        'creed': {},
        'prayer': {},
        'baptism': {},
        'communion': {},
        'confession': {},
        'appendices': []
    }
    
    # Extract table of contents
    toc_match = re.search(r'विषय सूची.*?(?=\n\n-{4})', content, re.DOTALL)
    if toc_match:
        sections['toc'] = toc_match.group(0)
    
    # Extract Ten Commandments section
    cmd_match = re.search(r'1\. दस आज्ञा.*?(?=2\. प्रेरितों का विश्वास)', content, re.DOTALL)
    if cmd_match:
        cmd_text = cmd_match.group(0)
        # Parse individual commandments
        commandments = re.findall(r'(पहली|दूसरी|तीसरी|चौथी|पाँचवी|छठवीं|सातवीं|आठवीं|नवीं|दसवीं) आज्ञा\n\n(.*?)(?=\n\n(?:पहली|दूसरी|तीसरी|चौथी|पाँचवी|छठवीं|सातवीं|आठवीं|नवीं|दसवीं|आज्ञाओं का निष्कर्ष)|\Z)', cmd_text, re.DOTALL)
        
        for num, text in commandments:
            # Split into statement and meaning
            parts = text.split('इसका क्या अर्थ है?')
            if len(parts) == 2:
                sections['commandments'].append({
                    'number': num,
                    'statement': parts[0].strip(),
                    'meaning': parts[1].strip()
                })
    
    # Extract Creed
    creed_match = re.search(r'2\. प्रेरितों का विश्वास दर्पण.*?(?=3\. प्रभु की प्रार्थना)', content, re.DOTALL)
    if creed_match:
        sections['creed']['full_text'] = creed_match.group(0)
    
    # Extract Lord's Prayer
    prayer_match = re.search(r'3\. प्रभु की प्रार्थना.*?(?=4\. बपतिस्मा का सक्रामेन्त)', content, re.DOTALL)
    if prayer_match:
        sections['prayer']['full_text'] = prayer_match.group(0)
    
    # Extract Baptism
    baptism_match = re.search(r'4\. बपतिस्मा का सक्रामेन्त.*?(?=5\. प्रभुभोज)', content, re.DOTALL)
    if baptism_match:
        sections['baptism']['full_text'] = baptism_match.group(0)
    
    # Extract Communion
    communion_match = re.search(r'5\. प्रभुभोज.*?(?=6\. पाप स्वीकार)', content, re.DOTALL)
    if communion_match:
        sections['communion']['full_text'] = communion_match.group(0)
    
    # Extract Confession
    confession_match = re.search(r'6\. पाप स्वीकार.*?(?=परिशिष्ट 1:)', content, re.DOTALL)
    if confession_match:
        sections['confession']['full_text'] = confession_match.group(0)
    
    return sections

def generate_html_commandments(commandments):
    """Generate HTML for commandments section"""
    html = '<div id="commandments" class="section">\n'
    html += '    <h2>1. दस आज्ञा (The Ten Commandments)</h2>\n\n'
    
    for cmd in commandments:
        html += '    <div class="commandment">\n'
        html += f'        <h4>{cmd["number"]} आज्ञा</h4>\n'
        
        # Parse statement
        lines = cmd['statement'].split('\n')
        for line in lines:
            if line.strip():
                html += f'        <p><strong>{line.strip()}</strong></p>\n'
        
        html += '        <div class="question">\n'
        html += '            <strong>इसका क्या अर्थ है?</strong>\n'
        html += '        </div>\n'
        html += '        <div class="answer">\n'
        html += f'            <p>{cmd["meaning"]}</p>\n'
        html += '        </div>\n'
        html += '    </div>\n\n'
    
    html += '</div>\n'
    return html

# Parse the file
sections = parse_catechism_file('assets/catechism')

# Generate commandments HTML
commandments_html = generate_html_commandments(sections['commandments'])

print("Parsing complete!")
print(f"Found {len(sections['commandments'])} commandments")
print("\nSample HTML output:")
print(commandments_html[:500] + "...")

# Write to output file for review
with open('catechism_parsed.txt', 'w', encoding='utf-8') as f:
    f.write("=== COMMANDMENTS ===\n")
    f.write(commandments_html)
    f.write("\n\n=== CREED ===\n")
    if 'full_text' in sections['creed']:
        f.write(sections['creed']['full_text'][:1000])
    f.write("\n\n=== PRAYER ===\n")
    if 'full_text' in sections['prayer']:
        f.write(sections['prayer']['full_text'][:1000])

print("\nParsed content saved to catechism_parsed.txt")
