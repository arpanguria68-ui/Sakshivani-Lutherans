#!/usr/bin/env python3
"""
Parse the full catechism file and generate complete HTML page
"""
import re

def read_file():
    with open('assets/catechism', 'r', encoding='utf-8') as f:
        return f.read()

def parse_section(content, start_marker, end_marker=None):
    """Extract a section between markers"""
    pattern = re.escape(start_marker) + r'(.*?)'
    if end_marker:
        pattern += re.escape(end_marker)
    else:
        pattern += r'(?=\n\n\d+\.|$)'
    
    match = re.search(pattern, content, re.DOTALL)
    return match.group(1).strip() if match else ""

def format_qa(text):
    """Format question-answer pairs"""
    parts = text.split('इसका क्या अर्थ है?')
    if len(parts) == 2:
        question_html = f'''        <div class="question">
            <strong>इसका क्या अर्थ है?</strong>
        </div>
        <div class="answer">
            <p>{parts[1].strip()}</p>
        </div>'''
        return parts[0].strip(), question_html
    return text, ""

# Read content
content = read_file()

# Start building HTML
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
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;700&family=Noto+Serif+Devanagari:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Noto Sans Devanagari', sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
        .catechism-container { max-width: 900px; margin: 0 auto; padding: 20px; }
        .catechism-header { text-align: center; padding: 30px 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 12px; margin-bottom: 30px; }
        .catechism-header h1 { font-size: 2.5rem; margin: 0; font-weight: 700; }
        .catechism-header p { font-size: 1.1rem; margin: 10px 0 0 0; opacity: 0.9; }
        .toc { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-bottom: 40px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .toc h2 { color: #667eea; margin-top: 0; font-size: 1.8rem; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        .toc ul { list-style: none; padding: 0; }
        .toc li { margin: 12px 0; padding-left: 20px; }
        .toc a { color: #333; text-decoration: none; font-size: 1.1rem; display: block; padding: 8px 12px; border-radius: 6px; transition: all 0.3s; }
        .toc a:hover { background: #667eea; color: white; transform: translateX(10px); }
        .section { background: white; padding: 30px; margin-bottom: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .section h2 { color: #667eea; font-size: 2rem; margin-top: 0; border-bottom: 3px solid #667eea; padding-bottom: 15px; margin-bottom: 25px; }
        .section h3 { color: #764ba2; font-size: 1.5rem; margin-top: 30px; margin-bottom: 15px; }
        .section h4 { color: #555; font-size: 1.2rem; margin-top: 20px; margin-bottom: 10px; font-weight: 600; }
        .section p { line-height: 1.8; font-size: 1.1rem; color: #333; margin: 15px 0; }
        .question { background: #e8eaf6; padding: 15px; border-left: 4px solid #667eea; margin: 20px 0; border-radius: 6px; }
        .question strong { color: #667eea; font-size: 1.15rem; }
        .answer { background: #f5f5f5; padding: 15px; border-left: 4px solid #764ba2; margin: 20px 0; border-radius: 6px; }
        .answer strong { color: #764ba2; }
        .commandment { background: linear-gradient(to right, #fef9e7, #fcf3cf); padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 5px solid #f39c12; }
        .prayer { background: linear-gradient(to right, #e8f8f5, #d1f2eb); padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 5px solid #1abc9c; }
        .nav-buttons { position: fixed; bottom: 20px; right: 20px; z-index: 1000; }
        .nav-button { background: #667eea; color: white; padding: 15px 25px; border: none; border-radius: 50px; font-size: 1rem; cursor: pointer; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4); transition: all 0.3s; display: inline-block; margin-left: 10px; text-decoration: none; }
        .nav-button:hover { transform: translateY(-3px); box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5); }
        @media (max-width: 768px) {
            .catechism-header h1 { font-size: 1.8rem; }
            .section { padding: 20px; }
            .nav-buttons { bottom: 10px; right: 10px; }
        }
    </style>
</head>
<body>
    <div class="catechism-container">
        <div class="catechism-header">
            <h1>लूथर की छोटी धर्मशिक्षा</h1>
            <p>Luther's Small Catechism in Hindi</p>
        </div>

        <div class="toc">
            <h2>विषय सूची (Table of Contents)</h2>
            <ul>
                <li><a href="#commandments">1. दस आज्ञा (The Ten Commandments)</a></li>
                <li><a href="#creed">2. प्रेरितों का विश्वास दर्पण (The Creed)</a></li>
                <li><a href="#prayer">3. प्रभु की प्रार्थना (The Lord's Prayer)</a></li>
                <li><a href="#baptism">4. बपतिस्मा का सक्रामेन्त (Holy Baptism)</a></li>
                <li><a href="#communion">5. प्रभुभोज का सक्रामेन्त (Holy Communion)</a></li>
                <li><a href="#confession">6. पाप स्वीकार (Confession)</a></li>
            </ul>
        </div>
'''

# Parse Ten Commandments
commandments_section = parse_section(content, '1. दस आज्ञा (The Ten Commandments)', '2. प्रेरितों का विश्वास')

html += '''
        <!-- Section 1: Ten Commandments -->
        <div id="commandments" class="section">
            <h2>1. दस आज्ञा (The Ten Commandments)</h2>
'''

# Extract each commandment
cmd_names = ['पहली', 'दूसरी', 'तीसरी', 'चौथी', 'पाँचवी', 'छठवीं', 'सातवीं', 'आठवीं', 'नवीं', 'दसवीं']
for i, name in enumerate(cmd_names):
    # Find this commandment
    if i < len(cmd_names) - 1:
        cmd_pattern = f'{name} आज्ञा(.*?)(?={cmd_names[i+1]} आज्ञा|आज्ञाओं का निष्कर्ष)'
    else:
        cmd_pattern = f'{name} आज्ञा(.*?)(?=आज्ञाओं का निष्कर्ष)'
    
    cmd_match = re.search(cmd_pattern, commandments_section, re.DOTALL)
    if cmd_match:
        cmd_text = cmd_match.group(1).strip()
        statement, qa = format_qa(cmd_text)
        
        html += f'''
            <div class="commandment">
                <h4>{name} आज्ञा</h4>
                <p><strong>{statement}</strong></p>
{qa}
            </div>
'''

# Add conclusion
conclusion_match = re.search(r'आज्ञाओं का निष्कर्ष(.*?)(?=2\. प्रेरितों का विश्वास|\Z)', commandments_section, re.DOTALL)
if conclusion_match:
    conclusion_text = conclusion_match.group(1).strip()
    statement, qa = format_qa(conclusion_text)
    html += f'''
            <div class="commandment">
                <h4>आज्ञाओं का निष्कर्ष</h4>
                <p><strong>{statement.replace("ईश्वर इन सब आज्ञाओं के विषय में क्या कहता है?", "").strip()}</strong></p>
{qa}
            </div>
'''

html += '''
        </div>
'''

# Write to file
with open('pwa/catechism_full.html', 'w', encoding='utf-8') as f:
    f.write(html)
    f.write('''
    </div>
    <div class="nav-buttons">
        <a href="index.html" class="nav-button">← गीत (Songs)</a>
    </div>
</body>
</html>''')

print("✅ Generated catechism_full.html with Ten Commandments section!")
print("File saved to: pwa/catechism_full.html")
