import json
import os

base_dir = r"f:\SuperTech\Sakshivani-Lutherans\pwa"
json_path = os.path.join(base_dir, "songs.json")
js_path = os.path.join(base_dir, "songs.js")

try:
    print(f"Reading {json_path}...")
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Writing to {js_path}...")
    with open(js_path, 'w', encoding='utf-8') as f:
        # Assign to global const SONGS_DATA
        f.write("const SONGS_DATA = ")
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write(";")
    
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
