
import json
import os
import re

# Parsing helper
def load_js_data(filepath):
    """
    Loads a JS file that assigns a JSON object to a variable, e.g., 'var EN_BIBLE = {...};'
    Returns the parsed Python dictionary.
    """
    if not os.path.exists(filepath):
        return None, f"File not found: {filepath}"
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Remove var declaration and trailing semicolon
            # Regex to find the JSON part
            match = re.search(r'=\s*(\{.*\});?', content, re.DOTALL)
            if match:
                json_str = match.group(1)
                # Fix trailing commas which JSON spec doesn't allow but JS does
                json_str = re.sub(r',\s*([\]}])', r'\1', json_str)
                return json.loads(json_str), None
            else:
                return None, "No JSON structure found after variable assignment"
    except Exception as e:
        return None, str(e)

def validate_bible(data, lang_code):
    report = []
    stats = {
        'books': 0,
        'chapters': 0,
        'verses': 0,
        'empty_books': 0,
        'empty_chapters': 0,
        'empty_verses': 0,
        'structure_errors': 0
    }
    
    if not data or 'Book' not in data:
        report.append(f"[{lang_code}] CRITICAL: 'Book' key missing in root.")
        return report, stats

    books = data['Book']
    stats['books'] = len(books)
    
    if len(books) != 66:
        report.append(f"[{lang_code}] CRITICAL: Invalid Book Count: {len(books)} (Expected 66)")

    for b_idx, book in enumerate(books):
        # Book structure check
        if 'Chapter' not in book:
            report.append(f"[{lang_code}] Book {b_idx} missing 'Chapter' array.")
            stats['empty_books'] += 1
            stats['structure_errors'] += 1
            continue
            
        chapters = book['Chapter']
        stats['chapters'] += len(chapters)
        
        if len(chapters) == 0:
             report.append(f"[{lang_code}] Book {b_idx} has 0 Chapters.")
             stats['empty_books'] += 1
        
        for c_idx, chapter in enumerate(chapters):
            # Verse structure check
            # Handle potential single object instead of array (though typically array)
            verses = []
            if 'Verse' in chapter:
                verses = chapter['Verse'] if isinstance(chapter['Verse'], list) else [chapter['Verse']]
            
            if not verses:
                report.append(f"[{lang_code}] Book {b_idx} Chapter {c_idx+1} has 0 Verses.")
                stats['empty_chapters'] += 1
                continue
                
            stats['verses'] += len(verses)
            
            for v_idx, verse in enumerate(verses):
                 # VerseID check
                 # Expected format could be strict, but just checking presence for now
                 if 'Verseid' not in verse:
                     report.append(f"[{lang_code}] Book {b_idx} Ch {c_idx+1} V {v_idx+1} missing Verseid.")
                     stats['structure_errors'] += 1
                 
                 # Content check
                 if 'Verse' not in verse or not verse['Verse'].strip():
                     report.append(f"[{lang_code}] Book {b_idx} Ch {c_idx+1} V {v_idx+1} has EMPTY content.")
                     stats['empty_verses'] += 1

    return report, stats

def run_audit():
    base_dir = r"f:\SuperTech\Sakshivani-Lutherans\dashboard-web\data\bible"
    en_path = os.path.join(base_dir, "en_data.js")
    hi_path = os.path.join(base_dir, "hi_data.js")
    
    print("--- Bible Data Integrity Audit ---")
    
    # Load Data
    print(f"Loading {en_path}...")
    en_data, en_err = load_js_data(en_path)
    if en_err:
        print(f"FATAL: Could not load EN data: {en_err}")
        return

    print(f"Loading {hi_path}...")
    hi_data, hi_err = load_js_data(hi_path)
    if hi_err:
        print(f"FATAL: Could not load HI data: {hi_err}")
        return

    # Validate Individually
    print("\nValidating English Data...")
    en_report, en_stats = validate_bible(en_data, "EN")
    
    print("\nValidating Hindi Data...")
    hi_report, hi_stats = validate_bible(hi_data, "HI")
    
    # Print Stats
    print("\n--- Statistics ---")
    print(f"EN: {en_stats['books']} Books, {en_stats['chapters']} Chapters, {en_stats['verses']} Verses")
    print(f"HI: {hi_stats['books']} Books, {hi_stats['chapters']} Chapters, {hi_stats['verses']} Verses")
    
    # Compare
    print("\n--- Consistency Check (EN vs HI) ---")
    
    discrepancies = []
    
    # Book Count
    if en_stats['books'] != hi_stats['books']:
        discrepancies.append(f"Book count mismatch: EN={en_stats['books']}, HI={hi_stats['books']}")
    
    # Detailed Chapter/Verse Count Comparison
    en_books = en_data['Book']
    hi_books = hi_data['Book']
    
    limit = min(len(en_books), len(hi_books))
    
    for i in range(limit):
        en_chaps = en_books[i].get('Chapter', [])
        hi_chaps = hi_books[i].get('Chapter', [])
        
        # Chapter Count
        if len(en_chaps) != len(hi_chaps):
            discrepancies.append(f"Book {i} Chapter count mismatch: EN={len(en_chaps)}, HI={len(hi_chaps)}")
        
        # Verse Count
        ch_limit = min(len(en_chaps), len(hi_chaps))
        for j in range(ch_limit):
            en_vs = en_chaps[j].get('Verse', [])
            hi_vs = hi_chaps[j].get('Verse', [])
            
            if not isinstance(en_vs, list): en_vs = [en_vs]
            if not isinstance(hi_vs, list): hi_vs = [hi_vs]
            
            if len(en_vs) != len(hi_vs):
                 discrepancies.append(f"Book {i} Ch {j+1} Verse count mismatch: EN={len(en_vs)}, HI={len(hi_vs)}")

    if discrepancies:
        print(f"FOUND {len(discrepancies)} DISCREPANCIES:")
        for d in discrepancies[:20]:
            print(f"- {d}")
        if len(discrepancies) > 20:
            print(f"... and {len(discrepancies)-20} more.")
            
        print("\n--- Discrepancy details ---")
        # Specific check for known issues to print content
        # Book 6 (Judges) Ch 10
        print("\nDetails for Book 6 (Judges) Chapter 10:")
        try:
            en_len = len(en_books[6]['Chapter'][9]['Verse'])
            hi_len = len(hi_books[6]['Chapter'][9]['Verse'])
            print(f"EN Verses: {en_len}")
            print(f"HI Verses: {hi_len}")
            # Print last few verses of HI to see if it merged next chapter
            if hi_len > en_len:
                print("Last 3 verses of HI Judges 10:")
                for v in hi_books[6]['Chapter'][9]['Verse'][-3:]:
                    print(f"  V{v.get('Verseid', '???')}: {v.get('Verse', '')[:50]}...")
        except Exception as e:
            print(f"Error inspecting Judges: {e}")

    else:
        print("SUCCESS: EN and HI structures match perfectly.")

    # Print individual reports if critical
    if en_report:
        print("\n--- EN Data Issues ---")
        for r in en_report: print(r)
        
    if hi_report:
        print("\n--- HI Data Issues ---")
        for r in hi_report: print(r)

    if not en_report and not hi_report and not discrepancies:
        print("\nOVERALL STATUS: PASSED")
    else:
        print("\nOVERALL STATUS: WARNINGS FOUND")

if __name__ == "__main__":
    run_audit()
