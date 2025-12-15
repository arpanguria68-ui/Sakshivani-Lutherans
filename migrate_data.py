import sqlite3
import json
import re
import os

def krutidev_to_unicode(text):
    if not text:
        return ""
    
    # Pad text to handle edge cases for 'f' and 'Z' processing
    text = " " + text + " "
    
    # --- 1. Pre-processing: Move 'f' (chhoti ee matra) to correct position ---
    chars = list(text)
    i = 0
    while i < len(chars):
        if chars[i] == 'f':
            # Swap 'f' with the character following it
            if i + 1 < len(chars):
                chars[i], chars[i+1] = chars[i+1], chars[i]
                i += 1 
        i += 1
    text = "".join(chars)

    # --- 2. Main Character Mapping (Kruti Dev -> Unicode) ---
    # User provided mapping
    mapping = [
        ('Q+Z','फ़्'), ('Q+','फ़'), ('ks','ो'), ('kS','ौ'), 
        ('aa','a'), ('pp','ç'), ('qq','æ'), ('«','त्र्'), 
        ('»','त्र'), ('‘','\"'), ('’','\"'), ('“',"'"), 
        ('”',"'"), ('å','०'), ('ƒ','१'), ('„','२'), 
        ('…','३'), ('†','४'), ('‡','५'), ('ˆ','६'), 
        ('‰','७'), ('Š','८'), ('‹','९'), ('¶','फ्'), 
        ('d+','क़'), ('[+k','ख़'), ('[+','ख़्'), ('x+','ग़'), 
        ('T+','ज़्'), ('t+','ज़'), ('M+','ड़'), ('<+','ढ़'), 
        ('Q+','फ़'), (';+','य़'), ('j+','ऱ'), ('u+','ऩ'), 
        ('Ùk','त्त'), ('Ù','त्त्'), ('Dr','क्त'), ('–','दृ'), 
        ('—','कृ'), ('é','न्न'), ('™','न्न्'), ('=kk','त्र'), 
        ('f=k','त्रि'), ('à','ह्न'), ('á','ह्य'), ('â','हृ'), 
        ('ã','ह्म'), ('ºz','ह्र'), ('º','ह्'), ('í','द्द'), 
        ('{k','क्ष'), ('{','क्ष्'), ('=','त्र'), ('Nî','छ्य'), 
        ('Vî','ट्य'), ('Bî','ठ्य'), ('Mî','ड्य'), ('<î','ढ्य'), 
        ('|','द्य'), ('K','ज्ञ'), ('}','द्व'), ('J','श्र'), 
        ('Vª','ट्र'), ('Mª','ड्र'), ('<ªª','ढ्र'), ('Nª','छ्र'), 
        ('Ø','क्र'), ('Ý','फ्र'), ('nzZ','र्द्र'), ('æ','द्र'), 
        ('ç','प्र'), ('Á','प्र'), ('xz','ग्र'), ('#','रु'), 
        (':','रू'), ('v‚','ऑ'), ('vks','ओ'), ('vkS','औ'), 
        ('vk','आ'), ('v','अ'), ('b±','ईं'), ('Ã','ई'), 
        ('bZ','ई'), ('b','इ'), ('m','उ'), ('Å','ऊ'), 
        (',s','ऐ'), (',','ए'), ('_','ऋ'), ('ô','क्क'), 
        ('d','क'), ('Dk','क'), ('D','क्'), ('[k','ख'), 
        ('[','ख्'), ('x','ग'), ('Xk','ग'), ('X','ग्'), 
        ('Ä','घ'), ('?k','घ'), ('?','घ्'), ('³','ङ'), 
        ('pkS','चै'), ('p','च'), ('Pk','च'), ('P','च्'), 
        ('N','छ'), ('t','ज'), ('Tk','ज'), ('T','ज्'), 
        ('>','झ'), ('÷','झ्'), ('¥','ञ'), ('ê','ट्ट'), 
        ('ë','ट्ठ'), ('V','ट'), ('B','ठ'), ('ì','ड्ड'), 
        ('ï','ड्ढ'), ('M','ड'), ('<','ढ'), ('.k','ण'), 
        ('.','ण'), ('R','त्'), ('r','त'), ('Fk','थ'), 
        ('F','थ्'), (')','द्ध'), ('n','द'), ('/k','ध'), 
        ('èk','ध'), ('/','ध्'), ('è','ध्'), ('Ë','ध्'), 
        ('u','न'), ('Uk','न'), ('U','न्'), ('i','प'), 
        ('Ik','प'), ('I','प्'), ('Q','फ'), ('¶','फ्'), 
        ('c','ब'), ('Ck','ब'), ('C','ब्'), ('Hk','भ'), 
        ('H','भ्'), ('e','म'), ('Ek','म'), ('E','म्'), 
        (';','य'), ('¸','य्'), ('j','र'), ('y','ल'), 
        ('Lk','ल'), ('L','ल्'), ('Y','ळ'), ('o','व'), 
        ('Ok','व'), ('O','व्'), ("'",'श्'), ('"k','श'), 
        ('"','श'), ('l','स'), ('Lk','स'), ('L','स्'), 
        ('g','ह'), ('È','ीं'), ('z','्र'), ('Ì','द्द'), 
        ('Í','ट्ट'), ('Î','ट्ठ'), ('Ï','ड्ड'), ('Ñ','कृ'), 
        ('Ò','भ'), ('Ó','्य'), ('Ô','ड्ढ'), ('Ö','झ्'), 
        ('Ø','क्र'), ('Ù','त्त्'), ('Ü','श'), ('x','ग'), 
        ('T','ज्'), ('f','ि'), ('h','ी'), ('q','ु'), 
        ('w','ू'), ('`','ृ'), ('s','े'), ('S','ै'), 
        ('a','ं'), ('¡','ँ'), ('%','ः'), ('W','ॅ'), 
        ('•','ऽ'), ('·','ऽ'), ('∙','ऽ'), ('~j','्र'), 
        ('~','्'), ('\\?','़'), ('^','‘'), ('*','’'), 
        ('ß','“'), ('Þ','”'), ('(','_'), (')','_'), 
        ('{','_'), ('}','_'), ('|','_'), ('ZM+','ड़'),
        ('k','ा'), ('Z','r'), 
    ]
    
    for k, v in mapping:
        text = text.replace(k, v)
        
    # --- 3. Post-processing: Handle 'Z' (Reph/Rakar) ---
    chars = list(text)
    i = 0
    while i < len(chars):
        if chars[i] == 'Z':
            chars[i] = '' # Remove Z
            if i > 0:
                chars.insert(i-1, 'र्') # Insert Reph before previous char
        i += 1
    
    return "".join(chars).strip()

def main():
    db_file = 'assets/Sakshivani_db.db'
    output_file = 'songs.json'
    
    if not os.path.exists(db_file):
        print(f"Error: Database file {db_file} not found.")
        return

    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # Select all relevant columns including Category and Reference
        # Note: Added Category and Reference as requested
        cursor.execute("SELECT Song_Id, Title, Lyric, Category, Reference FROM tbSakshivani")
        rows = cursor.fetchall()
        
        print(f"Found {len(rows)} songs. Converting...")
        
        songs = []
        for row in rows:
            # 0:Id, 1:Title, 2:Lyric, 3:Category, 4:Reference
            try:
                converted_title = krutidev_to_unicode(row[1])
                converted_lyric = krutidev_to_unicode(row[2])
                converted_category = krutidev_to_unicode(row[3]) if row[3] else ""
                converted_reference = krutidev_to_unicode(row[4]) if row[4] else ""
                
                songs.append({
                    "id": row[0],
                    "title": converted_title,
                    "lyrics": converted_lyric,
                    "category": converted_category,
                    "reference": converted_reference
                })
            except Exception as e:
                print(f"Error converting song ID {row[0]}: {e}")

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(songs, f, ensure_ascii=False, indent=2)
            
        print(f"Successfully converted {len(songs)} songs to {output_file}")
        
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
