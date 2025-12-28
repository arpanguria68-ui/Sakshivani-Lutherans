import json
import os

def convert_json_to_js(json_path, js_path, var_name):
    print(f"Reading {json_path}...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"Writing to {js_path}...")
        with open(js_path, 'w', encoding='utf-8') as f:
            f.write(f"const {var_name} = ")
            json.dump(data, f, ensure_ascii=False)
            f.write(";")
        
        print(f"Success: {var_name} created at {js_path}")
    except Exception as e:
        print(f"Error processing {json_path}: {e}")

# Paths
base_dir = r"f:\SuperTech\Sakshivani-Lutherans"
english_json = os.path.join(base_dir, "temp_bible_db", "English", "bible.json")
hindi_json = os.path.join(base_dir, "temp_bible_db", "Hindi", "bible.json")

english_js = os.path.join(base_dir, "dashboard-web", "data", "bible", "en_data.js")
hindi_js = os.path.join(base_dir, "dashboard-web", "data", "bible", "hi_data.js")

# Convert
convert_json_to_js(english_json, english_js, "EN_BIBLE")
convert_json_to_js(hindi_json, hindi_js, "HI_BIBLE")
