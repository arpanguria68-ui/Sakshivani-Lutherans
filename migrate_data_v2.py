import sqlite3
import json
import re
import os

def krutidev_to_unicode(text):
    if not text:
        return ""
    
    # Pad text
    text = " " + text + " "
    
    # --- 1. Pre-processing: Move 'f' ---
    chars = list(text)
    i = 0
    while i < len(chars):
        if chars[i] == 'f':
            if i + 1 < len(chars):
                chars[i], chars[i+1] = chars[i+1], chars[i]
                i += 1 
        i += 1
    text = "".join(chars)

    # --- 1.1 Pre-processing: Fix Chanakya patterns with wrong matra order ---
    # In some Chanakya sequences, halant character appears before the matra character
    # We need to swap them BEFORE doing the Unicode mapping
    # Pattern: consonant + '~' (halant in Chanakya) + matra char
    # Fix: consonant + matra char + '~'
    
    chanakya_matra_fixes = [
        # Most common: '~f' (halant + i-matra) should be 'f~' (i-matra + halant)
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~f', r'\1f~'),  # क्ि → कि्
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~h', r'\1h~'),  # ी-matra
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~q', r'\1q~'),  # ु-matra  
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~w', r'\1w~'),  # ू-matra
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~k', r'\1k~'),  # ा-matra
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~s', r'\1s~'),  # े-matra
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~S', r'\1S~'),  # ै-matra
        (r'([kKɛxCNTnpQtdDrbljgyqZSslomvhf])~ks', r'\1ks~'), # ो-matra
    ]
    
    for wrong_pattern, correct_pattern in chanakya_matra_fixes:
        text = re.sub(wrong_pattern, correct_pattern, text)

    # --- 2. Main Character Mapping ---
    # REORDERED LIST: Longest sequences FIRST to prevent partial replacement
    mapping = [
        # 3-4 char sequences
        ('Q+Z','फ़्'), ('nzZ','र्द्र'), ('=kk','त्र'), ('f=k','त्रि'), 
        
        # Specific Combos (Vowels + Matras) - MUST be before generic matras
        ('v‚','ऑ'), ('vks','ओ'), ('vkS','औ'), ('pkS','चै'), 
        ('vk','आ'), ('b±','ईं'), ('bZ','ई'), 
        ('b','इ'), 
        
        # Consonants + Halants
        ('aa','a'), ('pp','ç'), ('qq','æ'), ('«','त्र्'), 
        ('»','त्र'), ('‘','\"'), ('’','\"'), ('“',"'"), 
        ('”',"'"), ('å','०'), ('ƒ','१'), ('„','२'), 
        ('…','३'), ('†','४'), ('‡','५'), ('ˆ','६'), 
        ('‰','७'), ('Š','८'), ('‹','९'), ('¶','फ्'), 
        ('d+','क़'), ('[+k','ख़'), ('[+','ख़्'), ('x+','ग़'), 
        ('T+','ज़्'), ('t+','ज़'), ('M+','ड़'), ('<+','ढ़'), 
        ('Q+','फ़'), (';+','य़'), ('j+','ऱ'), ('u+','ऩ'), 
        ('Ùk','त्त'), ('Ù','त्त्'), ('Dr','क्त'), ('–','दृ'), 
        ('—','कृ'), ('é','न्न'), ('™','न्न्'), 
        ('à','ह्न'), ('á','ह्य'), ('â','हृ'), 
        ('ã','ह्म'), ('ºz','ह्र'), ('º','ह्'), ('í','द्द'), 
        ('{k','क्ष'), ('{','क्ष्'), ('=','त्र'), ('Nî','छ्य'), 
        ('Vî','ट्य'), ('Bî','ठ्य'), ('Mî','ड्य'), ('<î','ढ्य'), 
        ('|','द्य'), ('K','ज्ञ'), ('}','द्व'), ('J','श्र'), 
        ('Vª','ट्र'), ('Mª','ड्र'), ('<ªª','ढ्र'), ('Nª','छ्र'), 
        ('Ø','क्र'), ('Ý','फ्र'), ('æ','द्र'), 
        ('ç','प्र'), ('Á','प्र'), ('xz','ग्र'), ('#','रु'), 
        (':','रू'), 
        # Special Conjuncts & Common Words (MUST be before base character mappings)
        # These handle specific word patterns that don't follow standard rules
        ('/eZ','धर्म'), ('/e','धर्म'), # dharma - VERIFIED WORKING
        (f'Hk{chr(0xd9)}kkZ','भर्ता'), # bhartha with byte 0xd9
        ('vf/i','अधिप'), # adhipa
        ('f/i','धिप'), # dhipa
        
        # Legacy glyphs that map to conjuncts (CRITICAL - before other mappings)
        ('š','क्त'),  # Legacy glyph for क्त (Song 300: शाš मान → शक्तिमान)
        ('ä','क्त'),  # Alternative legacy glyph for क्त
        
        # Additional common conjuncts
        ('RrkZ','त्ता'), ('Rrk','त्त'), # tta combinations
        
        # Fix 'L' conflict (Swarg issue)
        ('L','स्'), 
        
        ('v','अ'), ('m','उ'), ('Å','ऊ'), 
        (',s','ऐ'), (',','ए'), ('_','ऋ'), ('ô','क्क'), 
        ('d','क'), ('Dk','क'), ('D','क्'), ('[k','ख'), 
        ('[','ख्'), ('x','ग'), ('Xk','ग'), ('X','ग्'), 
        ('Ä','घ'), ('?k','घ'), ('?','घ्'), ('³','ङ'), 
        ('p','च'), ('Pk','च'), ('P','च्'), 
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
        (';','य'), ('¸','य्'), ('j','र'), 
        ('y','ल'), ('Lk','ल'), 
        ('Y','ळ'), ('o','व'), 
        ('Ok','व'), ('O','व्'), 
        
        # 'Sha' handling
        ("'k",'श'), # Fix for Yeshu (;h'kq)
        ("'",'श्'), 
        ('"k','श'), 
        ('"','श'), 
        
        ('l','स'), 
        ('g','ह'), ('È','ीं'), ('z','्र'), ('Ì','द्द'), 
        ('Í','ट्ट'), ('Î','ट्ठ'), ('Ï','ड्ड'), ('Ñ','कृ'), 
        ('Ò','भ'), ('Ó','्य'), ('Ô','ड्ढ'), ('Ö','झ्'), 
        ('Ø','क्र'), ('Ù','त्त्'), ('Ü','श'), ('x','ग'), 
        ('T','ज्'), ('f','ि'), ('h','ी'), ('q','ु'), 
        ('w','ू'), ('`','ृ'), 
        # ('s','े'), ('S','ै'), # MOVED TO BOTTOM
        ('a','ं'), ('¡','ँ'), ('%','ः'), ('W','ॅ'), 
        ('•','ऽ'), ('·','ऽ'), ('∙','ऽ'), ('~j','्र'), 
        ('~','्'), ('\\?','़'), ('^','‘'), ('*','’'), 
        ('ß','“'), ('Þ','”'), ('(','_'), (')','_'), 
        ('{','_'), ('}','_'), ('|','_'), ('ZM+','ड़'),
        
        # Matras (Mapping Order Critical)
        ('kS','ौ'), ('ks','ो'), 
        ('k','ा'), 
        ('s','े'), ('S','ै'), # Moved here

        # Additional vowel: Long Ū (from reference table)
        ('mZ','ऊ'),  # Long u (matches reference: mZ → ऊ)

        # Vedic & Musical Markers (for hymns, bhajans, shlokas)
        ('vkse','ॐ'),  # Om symbol (common in songs)
        ('AA','॥'),    # Double danda (verse end)
        ('¡','ँ'),     # Chandrabindu (already present above but ensuring)
        
        # Punctuation
        ('A','।'),  # Single danda (line end)
        (';','।'),  # Alternative for danda
    ]
    
    for k, v in mapping:
        text = text.replace(k, v)
        
    # --- 3. Post-processing: Handle 'Z' (Reph/Rakar) ---
    chars = list(text)
    i = 0
    while i < len(chars):
        if chars[i] == 'Z':
            chars[i] = '' 
            if i > 0:
                chars.insert(i-1, 'र्') 
        i += 1
    
    text = "".join(chars).strip()
    
    # --- 4. Post-processing: Fix specific word patterns ---
    # These are words that don't convert correctly with character-level mapping
    word_fixes = [
        # Original fixes
        ('भत्तर्ा', 'भर्ता'),  # bhartā
        ('अध्िप', 'अधिप'),   # adhipa  
        ('भत्तर्', 'भर्त'),   # bharth (without ā)
        
        # Systematic issues found across all songs (from comprehensive analysis)
        ('ख्िा्रस्त', 'क्रिस्त'),  # Christ - 100+ instances
        ('धर्मर्ात्मा', 'धर्मात्मा'),  # dharmātmā
        ('अधर्मर्', 'अधर्म'),  # adharma
        
        # Misplaced matra patterns (42 instances)
        ('पि्रय', 'प्रिय'),  # priya (beloved)
        ('पि्रये', 'प्रिये'),  # priye
        ('पि्रयों', 'प्रियों'),  # priyoṁ
        ('पि्रत', 'प्रित'),  # prit
        
        # Halant issues
        ('बन्ध्ु', 'बन्धु'),  # bandhu (7 instances)
        ('बन्ध्', 'बन्ध'),  # bandh (37 instances)
        ('ध्ीर', 'धीर'),  # dhīr (33 instances)
        ('ध्ीरज', 'धीरज'),  # dhīraj
        
        # Matra misplacement
        ('स्िथर', 'स्थिर'),  # sthir (30 instances)
        ('स्िधर', 'स्थिर'),  # sthir variant
        ('अध्ीन', 'अधीन'),  # adhīn (22 instances)
        ('अध्िकार', 'अधिकार'),  # adhikār (7 instances)
        
        # Extra halants in conjuncts
        ('कत्तर्ा', 'कर्ता'),  # kartā (creator) - 16 instances
        ('सृशिटकत्तर्ा', 'सृष्टिकर्ता'),  # creator
        ('जगकत्तर्ा', 'जगत्कर्ता'),  # world creator
        ('जगभतर्ा', 'जगभर्ता'),  # jagabhartha - 1 instance
        
        # Wrong consonant/conjunct
        ('सृशिट', 'सृष्टि'),  # sṛṣṭi (creation) - 14 instances
        ('सृशट', 'सृष्टि'),  # sṛṣṭi variant - 2 instances
        
        # Double halant issues
        ('जगत्त्रणी', 'जगत्राणी'),  # jagattrāṇī - 3 instances
        ('सिध््द', 'सिद्ध'),  # siddha - 2 instances
        ('विपत्त्िा', 'विपत्ति'),  # vipatti (calamity)
        ('सम्पत्त्िा', 'सम्पत्ति'),  # sampatti (prosperity)
        ('निधर््न', 'निर्धन'),  # nirdhan (poor)
        ('निदि्रत', 'निद्रित'),  # nidrit (asleep)
        ('ध्म्मर्ात्मा', 'धर्मात्मा'),  # dharmātmā - 2 instances
        
        # Additional common patterns
        ('स्रपा', 'स्राप'),  # srāpa (curse)
        ('ख्रीस्त', 'क्रिस्त'),  # Christ variant
        
        # User-reported issues (Song-specific corrections)
        ('शुð', 'शुद्ध'),  # shuddha (pure)
        ('कोरेरेरस', 'कोरस'),  # chorus
        ('मं›ल', 'मंगल'),  # mangal
        ('रात्रिा', 'रात्रि'),  # raatri (night)
        ('अन्ध्ेरा', 'अंधेरा'),  # andhera (darkness)
        ('कृिस्त', 'क्रिस्त'),  # Christ
        ('अन्िध्यारा', 'अंधियारा'),  # andhiyara
        ('मुक्ितदाता', 'मुक्तिदाता'),  # muktidaata (savior)
        ('उðारियो', 'उद्धारियो'),  # uddhariyo
        ('तृप्ित', 'तृप्ति'),  # tripti (satisfaction)
        
        # Character mapping issues
        ('ð', 'द्ध'),  # Special character → proper conjunct
        ('›', ''),  # Remove invalid character
        ('_', ''),  # Remove underscore (40 instances)
        
        # Duplication corruption patterns
        ('पूब्र्ब', 'पूर्व'),  # Corrupted reph - 2 instances in Song 37
        ('ब्र्ब', 'र्व'),  # Generic fix for duplicated ba-ra-ba
        
        # OCR/Legacy junk characters
        ('स्वगो±', 'स्वर्गों'),  # ± is OCR junk
        ('±', ''),  # Remove ± anywhere
        
        # Missing matras
        ('आधर', 'आधार'),  # Missing ा matra
        
        # Incorrect halant/conjunct patterns
        ('ध्न्य', 'धन्य'),  # Extra halant: ध् + न् + य → ध + न् + य
        ('ध्न', 'धन'),  # Extra halant: ध् + न → ध + न
        ('पवत्रि', 'पवित्र'),  # i-matra misplaced: should be before व
        
        # Bible reference fixes (extra halants)
        ('प््रेारित', 'प्रेरित'),  # Acts - extra halants
        ('प््रे', 'प्रे'),  # Generic prefix fix
        ('फिलिप्पि', 'फिलिप्पी'),  # Philippians
        ('कॉरिन्थ', 'कुरिन्थियों'),  # Corinthians
        
        # Additional legacy cleanup
        ('िा', 'िया'),  # Common matra sequence issue
        ('ाा', 'ा'),  # Doubled aa matra
    ]
    
    for wrong, correct in word_fixes:
        text = text.replace(wrong, correct)
    
    # --- 5. Remove Chanakya separator symbol ---
    # The ']' character appears in Chanakya as a line/phrase separator
    # It should be removed in Unicode (790 instances across 125 songs)
    text = text.replace(']', ',')  # Replace with comma for natural pause
    
    # --- 6. Fix matra alignment issues ---
    # Some conversions have halant appearing after matra (wrong order)
    # The issue is: शक्ितमान should be शक्तिमान (remove halant between consonant and matra)
    
    matra_alignment_fixes = {
        'क्ि': 'कि',
        'ध्ि': 'धि', 
        'र्ी': 'री',
        'न्ि': 'नि',
        'श्ि': 'शि',
        'ख्ि': 'खि',
        'ध्ू': 'धू',
        'र्ा': 'रा',
        'ध्े': 'धे',
        'र्ो': 'रो',
        'ध्ी': 'धी',
        'ध्ु': 'धु',
        'भ्ि': 'भि',
        'त्ि': 'ति',
        'र्ि': 'रि',
        'ग्ि': 'गि',
        'थ्ि': 'थि',
        'स्ि': 'सि',
        'प्ि': 'पि',
        'घ्ि': 'घि',
        'म्ि': 'मि',
        'र्ु': 'रु',
        'ष्ि': 'षि',
        'भ्ु': 'भु',
        'ध्ै': 'धै',
        'स्ा': 'सा',
    }
    
    for wrong, correct in matra_alignment_fixes.items():
        text = text.replace(wrong, correct)
    
    # --- 7. Fix extra character patterns ---
    extra_char_fixes = {
        'काय्र्य': 'कार्य',  # Extra र् 
        'ध्म्र्म': 'धर्म',   # Extra म् 
        'त्रिाएक': 'त्रिएक', # Extra ा
    }
    
    for wrong, correct in extra_char_fixes.items():
        text = text.replace(wrong, correct)
    
    # --- 8. Replace ampersand symbol with dash ---
    # The & symbol is used in Chanakya as a "repeat" marker (e.g., &2 means repeat twice)
    # Replace with dash for cleaner display - 202 instances
    text = text.replace('&', '-')
    
    # --- 9. Remove visarga (ः) - NOT used in modern Hindi ---
    # Visarga (ः U+0903) is Sanskrit-only, not modern Hindi
    # Context-aware replacement based on linguistic guidelines:
    #   - In titles/headings: remove completely
    #   - Before space (pause marker): replace with em dash —
    #   - End of line: remove (not needed)
    #   - Before comma: remove (comma already marks pause)
    
    # Simple approach: Remove all visarga for clean modern Hindi hymns
    # Professional hymn books don't use visarga
    text = text.replace('ः', '')
    
    # Clean up any double spaces created by removal
    while '  ' in text:
        text = text.replace('  ', ' ')
    
    return text

def main():
    db_file = 'assets/Sakshivani_db.db'
    output_file = 'pwa/songs.json' # Direct write to PWA
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        cursor.execute("SELECT Song_Id, Title, Lyric, Category, Reference FROM tbSakshivani")
        rows = cursor.fetchall()
        
        print(f"Found {len(rows)} songs. Converting...")
        
        songs = []
        for row in rows:
            try:
                converted_title = krutidev_to_unicode(row[1])
                converted_lyric = krutidev_to_unicode(row[2])
                converted_category = krutidev_to_unicode(row[3]) if row[3] else ""
                converted_reference = krutidev_to_unicode(row[4]) if row[4] else ""
                
                # Clean up Bible references specifically
                if converted_reference:
                    # Remove special characters that shouldn't be in references
                    converted_reference = converted_reference.replace('ए', ':')  # Common error
                    converted_reference = converted_reference.replace('$', ':')
                    converted_reference = converted_reference.replace('-', ':')
                    # Fix common Bible book name issues
                    converted_reference = converted_reference.replace('प््रा: वा:', 'प्रकाशितवाक्य')
                    converted_reference = converted_reference.replace('इब्रा:', 'इब्रानियों')
                    converted_reference = converted_reference.replace('एट', 'प्रेरितों')
                
                songs.append({
                    "id": row[0],
                    "title": converted_title,
                    "lyrics": converted_lyric,
                    "category": converted_category,
                    "reference": converted_reference
                })
            except Exception as e:
                print(f"Error converting song ID {row[0]}: {e}")

        # Ensure directory
        os.makedirs(os.path.dirname(output_file), exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(songs, f, ensure_ascii=False, indent=2)
            
        print(f"Success! Saved to {output_file}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
