from bs4 import BeautifulSoup
import json
import os

def extract_catechism_content(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        html = f.read()
    
    soup = BeautifulSoup(html, 'html.parser')
    
    # Extract intro
    intro_card = soup.find('div', class_='intro-card')
    intro = intro_card.find('div', class_='intro-text').get_text(strip=True) if intro_card else ''
    
    # Extract sections
    sections = []
    for item in soup.find_all('div', class_='accordion-item'):
        sub_label = item.find('span', class_='sub-label')
        main_title = item.find('span', class_='main-title')
        standout = item.find('p', class_='standout-text')
        content_inner = item.find('div', class_='content-inner')
        
        if sub_label and main_title and standout and content_inner:
            question = f"{sub_label.get_text(strip=True)} - {main_title.get_text(strip=True)}"
            answer = standout.get_text(strip=True)
            
            # Get explanation (last p tag in content-inner)
            paragraphs = content_inner.find_all('p')
            explanation = paragraphs[-1].get_text(strip=True) if paragraphs else ''
            
            sections.append({
                'question': question,
                'answer': answer,
                'explanation': explanation
            })
    
    return {
        'intro': intro,
        'sections': sections
    }

# Extract all chapters
chapters = {}
catechism_files = [
    ('1', '1-commandments.html', 'The Ten Commandments', 'दस आज्ञाएँ', 2, 'विश्वास-कथन (Creed)'),
    ('2', '2-creed.html', "The Apostles' Creed", 'प्रेरितों का विश्वास-कथन', 3, 'प्रभु की प्रार्थना (Prayer)'),
    ('3', '3-prayer.html', "The Lord's Prayer", 'प्रभु की प्रार्थना', 4, 'पवित्र बपतिस्मा (Baptism)'),
    ('4', '4-baptism.html', 'Holy Baptism', 'पवित्र बपतिस्मा', 5, 'पवित्र भोज (Communion)'),
    ('5', '5-communion.html', 'Holy Communion', 'पवित्र भोज', 6, 'पाप-स्वीकार (Confession)'),
    ('6', '6-confession.html', 'Confession', 'पाप-स्वीकार', None, None)
]

for id, filename, title, titleHindi, next_id, next_title in catechism_files:
    file_path = f'pwa/catechism/{filename}'
    if os.path.exists(file_path):
        content = extract_catechism_content(file_path)
        chapters[id] = {
            'id': int(id),
            'title': title,
            'titleHindi': titleHindi,
            'intro': content['intro'],
            'sections': content['sections']
        }
        if next_id and next_title:
            chapters[id]['nextChapter'] = {'id': next_id, 'title': next_title}

# Write to JSON file
with open('public/pwa/catechism-data.json', 'w', encoding='utf-8') as f:
    json.dump(chapters, f, ensure_ascii=False, indent=2)

print("Catechism data extracted successfully!")
print(f"Total chapters: {len(chapters)}")
for id, data in chapters.items():
    print(f"Chapter {id}: {data['titleHindi']} - {len(data['sections'])} sections")
