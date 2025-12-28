
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

def inspect():
    base_dir = r"f:\SuperTech\Sakshivani-Lutherans\dashboard-web\data\bible"
    hi_path = os.path.join(base_dir, "hi_data.js")
    
    data, err = load_js_data(hi_path)
    if err: return

    judges_ch10 = data['Book'][6]['Chapter'][9]['Verse']
    
    micah_ch3 = data['Book'][32]['Chapter'][2]['Verse']
    
    with open("judges_dump.txt", "w", encoding="utf-8") as f:
        f.write("--- Judges 10 ---\n")
        val_1_18 = []
        val_19_36 = []
        
        for i, v in enumerate(judges_ch10):
            txt = v.get('Verse', '')
            f.write(f"V{i+1}: {txt}\n")
            if i < 18: val_1_18.append(txt)
            else: val_19_36.append(txt)
            
        f.write("\n--- Micah 3 ---\n")
        for i, v in enumerate(micah_ch3):
             f.write(f"V{i+1}: {v.get('Verse', '')}\n")

if __name__ == "__main__":
    inspect()
