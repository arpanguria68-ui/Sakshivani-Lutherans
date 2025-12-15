# Clean Unicode Database - Schema Documentation

## Database File
**Name:** `Sakshivani_Unicode_Clean.db`  
**Location:** `assets/Sakshivani_Unicode_Clean.db`  
**Encoding:** UTF-8  
**Version:** v20_unicode_clean

---

## Tables

### 1. `songs` (Main table)
Primary storage for all 353 hymn songs with clean Unicode text.

**Schema:**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `song_id` | INTEGER | PRIMARY KEY | Unique song identifier (1-353) |
| `title` | TEXT | NOT NULL | Song title in clean Unicode Hindi |
| `lyrics` | TEXT | NOT NULL | Full song lyrics with proper formatting |
| `category` | TEXT | | Song category/classification |
| `reference` | TEXT | | Bible/Scripture reference |
| `created_date` | TIMESTAMP | DEFAULT NOW | Record creation timestamp |
| `updated_date` | TIMESTAMP | DEFAULT NOW | Last update timestamp |

**Indexes:**
- `idx_category` - Fast category filtering
- `idx_title` - Title search optimization
- `idx_reference` - Reference lookup

---

### 2. `songs_fts` (Full-Text Search)
Virtual FTS5 table for fast text search across titles and lyrics.

**Schema:**
```sql
CREATE VIRTUAL TABLE songs_fts USING fts5(
    title,
    lyrics,
    category,
    content=songs,
    content_rowid=song_id
)
```

**Usage:**
```sql
SELECT * FROM songs_fts WHERE songs_fts MATCH 'यीशु';
```

---

### 3. `metadata`
Database metadata and version information.

**Schema:**
| Key | Value |
|-----|-------|
| `version` | v20_unicode_clean |
| `total_songs` | 353 |
| `encoding` | UTF-8 |
| `conversion_date` | 2025-12-14 |
| `corrections_applied` | 2220+ |
| `source` | Chanakya to Unicode conversion |

---

## Data Quality

### Applied Corrections (2,220+)
- ✅ Character mapping (90+ patterns)
- ✅ Matra alignment (580 fixes)
- ✅ Halant corrections (10+)
- ✅ Punctuation (1,436 fixes)
- ✅ Bible references (reformatted)
- ✅ Legacy glyph removal

### Validation
- ✅ No legacy characters (ä š ð ± ÿ _)
- ✅ No visarga in Hindi text
- ✅ All matras correctly positioned
- ✅ All Bible references properly formatted
- ✅ Clean UTF-8 encoding

---

## Usage Examples

### Query all songs
```sql
SELECT * FROM songs ORDER BY song_id;
```

### Search by category
```sql
SELECT song_id, title FROM songs 
WHERE category = 'यीशु का जन्म';
```

### Full-text search
```sql
SELECT song_id, title 
FROM songs_fts 
WHERE songs_fts MATCH 'प्रभु यीशु'
LIMIT 10;
```

### Get song with reference
```sql
SELECT * FROM songs 
WHERE reference LIKE '%युहन्ना%';
```

---

## Production Ready
✅ Clean Unicode data  
✅ Indexed for performance  
✅ FTS enabled for search  
✅ Publication-ready  
✅ Backup recommended
