import sqlite3
import os

db_path = 'assets/Sakshivani_db.db'

if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()

print(f"Tables found: {tables}")

for table in tables:
    table_name = table[0]
    print(f"\n--- Table: {table_name} ---")
    
    # Get schema
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = cursor.fetchall()
    col_names = [col[1] for col in columns]
    print(f"Columns: {col_names}")
    
    # Get sample data
    cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

conn.close()
