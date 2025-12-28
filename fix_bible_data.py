
import json
import os
import re

# Parsing helper (Same as validation script)
def load_js_data(filepath):
    if not os.path.exists(filepath):
        return None, f"File not found: {filepath}"
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            match = re.search(r'=\s*(\{.*\});?', content, re.DOTALL)
            if match:
                json_str = match.group(1)
                json_str = re.sub(r',\s*([\]}])', r'\1', json_str)
                return json.loads(json_str), None
            else:
                return None, "No JSON structure found"
    except Exception as e:
        return None, str(e)

def save_js_data(filepath, data):
    try:
        json_str = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
        content = f"const HI_BIBLE = {json_str};"
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True, None
    except Exception as e:
        return False, str(e)

def fix_data():
    base_dir = r"f:\SuperTech\Sakshivani-Lutherans\dashboard-web\data\bible"
    hi_path = os.path.join(base_dir, "hi_data.js")
    
    print(f"Loading {hi_path}...")
    data, err = load_js_data(hi_path)
    if err:
        print(f"Error: {err}")
        return

    # --- FIX 1: Judges (Book Index 6) Chapter 10 (Index 9) ---
    print(f"\n--- Checking Judges (Book 6) Ch 10 ---")
    judges = data['Book'][6]
    judges_ch10 = judges['Chapter'][9]
    verses = judges_ch10['Verse']
    
    print(f"Current Verse Count: {len(verses)}")
    
    if len(verses) == 36:
        half = 18
        part1 = verses[:half]
        part2 = verses[half:]
        
        match_count = 0
        for i in range(half):
            v1 = part1[i].get('Verse', '').strip()
            v2 = part2[i].get('Verse', '').strip()
            
            if v1 == v2:
                match_count += 1
            else:
                print(f"MISMATCH V{i+1} vs V{i+19}:")
                try:
                    safe_v1 = v1.encode('ascii', 'backslashreplace').decode('ascii')
                    safe_v2 = v2.encode('ascii', 'backslashreplace').decode('ascii')
                    print(f"  V{i+1}: {safe_v1}")
                    print(f"  V{i+19}: {safe_v2}")
                except:
                    print("  (Cannot print mismatch content)")

        if match_count == half:
            print("Confirmed: Verses 1-18 match 19-36 (ignoring whitespace). Fixing...")
            judges_ch10['Verse'] = part1
            print(f"New Verse Count: {len(judges_ch10['Verse'])}")
            
            # --- SAVE JUDGES FIX ---
            success, msg = save_js_data(hi_path, data)
            if success:
                print("Successfully saved hi_data.js with Judges fix.")
            else:
                print(f"Failed to save: {msg}")

        else:
            print(f"Critical Mismatches found ({match_count}/{half} matches). Aborting Fix 1.")

    # --- INSPECT Book Index 32 (Micah) Ch 3 (Index 2) ---
    print(f"\n--- Checking Book Index 32 Ch 3 ---")
    book_32 = data['Book'][32] 
    ch3_verses = book_32['Chapter'][2]['Verse']
    print(f"Verse Count: {len(ch3_verses)}")
    
    for i, v in enumerate(ch3_verses):
        v_text = v.get('Verse', '').strip()
        safe_v = v_text.encode('ascii', 'backslashreplace').decode('ascii')
        print(f"V{i+1}: {safe_v[:60]}...")

if __name__ == "__main__":
    fix_data()
