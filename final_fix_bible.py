
import json
import os
import re

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

    # --- FIX 1: Judges (Book 6) Ch 10 (Index 9) ---
    print(f"\n--- Fixing Judges (Book 6) Ch 10 ---")
    judges_ch10 = data['Book'][6]['Chapter'][9]
    verses = judges_ch10['Verse']
    
    if len(verses) == 36:
        print("Detected 36 verses. Applying fix: Keeping Text from V19-36 with IDs from V1-18.")
        part1 = verses[:18] # Has correct IDs
        part2 = verses[18:] # Has correct Text
        
        new_verses = []
        for i in range(18):
            v_obj = part2[i].copy()
            v_obj['Verseid'] = part1[i]['Verseid']
            new_verses.append(v_obj)
            
        judges_ch10['Verse'] = new_verses
        print(f"Fixed Judges 10. Count: {len(judges_ch10['Verse'])}")
    else:
        print(f"Unexpected count {len(verses)}. Skipping Judges fix.")

    # --- FIX 2: Micah (Book 32) Ch 3 (Index 2) ---
    print(f"\n--- Fixing Micah (Book 32) Ch 3 ---")
    micah_ch3 = data['Book'][32]['Chapter'][2]
    m_verses = micah_ch3['Verse']
    
    if len(m_verses) == 13:
        print("Detected 13 verses. Removing last verse (corrupted duplicate).")
        micah_ch3['Verse'] = m_verses[:12]
        print(f"Fixed Micah 3. Count: {len(micah_ch3['Verse'])}")
    else:
        print(f"Unexpected count {len(m_verses)}. Skipping Micah fix.")

    # --- SAVE ---
    print("\nSaving corrections...")
    success, msg = save_js_data(hi_path, data)
    if success:
        print("Successfully saved hi_data.js")
    else:
        print(f"Failed to save: {msg}")

if __name__ == "__main__":
    fix_data()
