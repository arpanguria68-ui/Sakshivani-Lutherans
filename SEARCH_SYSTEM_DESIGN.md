# Search & Filtering System Design - Sakshi Vani PWA

## Overview
Comprehensive search system for 353 Hindi hymns with intelligent filtering, ranking, and user-friendly UX.

---

## Search Techniques & Architecture

### 1. **Full-Text Search (FTS5)** - Primary Search Engine

**Already Implemented:**
```sql
CREATE VIRTUAL TABLE songs_fts USING fts5(
    title, lyrics, category,
    content=songs,
    content_rowid=song_id
);
```

**Capabilities:**
- ✅ Instant search across titles, lyrics, categories
- ✅ Boolean operators (AND, OR, NOT)
- ✅ Phrase matching
- ✅ Prefix matching (`यीशु*`)
- ✅ Column-specific search (`title:पवित्र`)

**Query Examples:**
```javascript
// Basic search
SELECT * FROM songs_fts WHERE songs_fts MATCH 'यीशु';

// Multiple words (AND by default)
SELECT * FROM songs_fts WHERE songs_fts MATCH 'यीशु प्रभु';

// Phrase search
SELECT * FROM songs_fts WHERE songs_fts MATCH '"पवित्र यीशु"';

// Title-only search
SELECT * FROM songs_fts WHERE songs_fts MATCH 'title:धन्यवाद';

// Prefix (autocomplete)
SELECT * FROM songs_fts WHERE songs_fts MATCH 'यीश*';
```

---

### 2. **Multi-Level Filtering System**

#### A. Category Filtering
```javascript
const categories = [
  'त्रियाएक परमेश्वर का गुणानुवाद',
  'यीशु का जन्म',
  'प्रभु यीशु का दुख और मरण',
  // ... all categories
];

// Filter + Search combined
SELECT s.* FROM songs s
JOIN songs_fts ON s.song_id = songs_fts.rowid
WHERE songs_fts MATCH ?
AND s.category = ?;
```

#### B. Bible Reference Filtering
```javascript
// Reference-based filtering
SELECT * FROM songs 
WHERE reference LIKE '%युहन्ना%'
OR reference LIKE '%मत्ती%';

// Combined with search
SELECT s.* FROM songs s
JOIN songs_fts ON s.song_id = songs_fts.rowid
WHERE songs_fts MATCH ?
AND s.reference IS NOT NULL;
```

#### C. First Letter Browse (Hindi Alphabet)
```javascript
// Browse by starting letter
const hindiAlphabet = ['अ', 'आ', 'इ', 'ई', ... 'ह'];

SELECT * FROM songs 
WHERE title LIKE 'अ%'
ORDER BY title;
```

---

### 3. **Fuzzy/Phonetic Matching** (For Typos)

**Problem:** Users might make typing errors in Hindi

**Solution 1: Soundex for Hindi** (Custom implementation)
```javascript
function hindiSoundex(word) {
  // Map similar sounding characters
  const soundMap = {
    'श': 'स', 'ष': 'स',  // All sibilants → स
    'ण': 'न',            // Retroflex → dental
    'ढ': 'ड',
    // ... more mappings
  };
  
  return word.split('').map(c => soundMap[c] || c).join('');
}

// Search with phonetic similarity
```

**Solution 2: Levenshtein Distance** (Edit distance)
```javascript
function searchWithTolerance(query, maxDistance = 2) {
  // Find songs within edit distance
  // Good for short titles
}
```

---

### 4. **Search Ranking & Relevance**

**Built-in FTS5 Ranking:**
```sql
SELECT *, rank FROM songs_fts 
WHERE songs_fts MATCH ?
ORDER BY rank;  -- BM25 algorithm
```

**Custom Ranking Factors:**
```javascript
const calculateScore = (result, query) => {
  let score = result.rank; // Base FTS5 score
  
  // Boost exact title matches
  if (result.title.toLowerCase() === query.toLowerCase()) {
    score *= 3;
  }
  
  // Boost if query appears in first line
  const firstLine = result.lyrics.split('\n')[0];
  if (firstLine.includes(query)) {
    score *= 1.5;
  }
  
  // Boost popular songs (if you have usage data)
  score *= (1 + result.view_count / 1000);
  
  return score;
};
```

---

### 5. **Smart Search Features**

#### A. **Auto-Suggest / Autocomplete**
```javascript
// As user types "यी"
SELECT DISTINCT title FROM songs 
WHERE title LIKE 'यी%' 
LIMIT 10;

// FTS5 prefix search
SELECT * FROM songs_fts 
WHERE songs_fts MATCH 'यी*' 
LIMIT 10;
```

#### B. **Search Highlighting**
```javascript
function highlightMatches(text, query) {
  const regex = new RegExp(`(${query})`, 'gi');
  return text.replace(regex, '<mark>$1</mark>');
}
```

#### C. **Recent Searches**
```javascript
// Store in localStorage
const recentSearches = JSON.parse(
  localStorage.getItem('recentSearches') || '[]'
);

function addRecentSearch(query) {
  recentSearches.unshift(query);
  recentSearches.splice(5); // Keep only 5
  localStorage.setItem('recentSearches', 
    JSON.stringify(recentSearches)
  );
}
```

#### D. **Popular Searches** (Optional)
Track what users search for most:
```sql
CREATE TABLE search_analytics (
  query TEXT PRIMARY KEY,
  count INTEGER DEFAULT 1,
  last_searched TIMESTAMP
);
```

---

### 6. **Unicode-Specific Considerations**

#### A. **Matra Normalization**
Users might type matras in wrong order:
```javascript
function normalizeHindi(text) {
  // Reorder matras if needed
  // Remove zero-width characters
  return text.normalize('NFC');
}
```

#### B. **Devanagari Number Support**
```javascript
// Convert Devanagari numbers to Arabic for reference search
const devaToArabic = {
  '०': '0', '१': '1', '२': '2', '३': '3',
  '४': '4', '५': '5', '६': '6', '७': '7',
  '८': '8', '९': '9'
};

function normalizeNumbers(ref) {
  return ref.replace(/[०-९]/g, c => devaToArabic[c]);
}
```

---

## Implementation Architecture

### Frontend (PWA)

```javascript
// Main Search Component
class SongSearch {
  constructor() {
    this.db = null; // IndexedDB or SQLite
    this.filters = {
      category: null,
      hasReference: false,
      letter: null
    };
  }
  
  async search(query) {
    // 1. Normalize input
    const normalized = this.normalizeQuery(query);
    
    // 2. Apply filters
    const filters = this.buildFilters();
    
    // 3. Execute FTS search
    const results = await this.ftsSearch(normalized, filters);
    
    // 4. Rank results
    const ranked = this.rankResults(results, query);
    
    // 5. Return with highlighting
    return ranked.map(r => ({
      ...r,
      highlightedTitle: this.highlight(r.title, query),
      highlightedSnippet: this.getSnippet(r.lyrics, query)
    }));
  }
  
  normalizeQuery(q) {
    return q.trim().normalize('NFC');
  }
  
  buildFilters() {
    const conditions = [];
    
    if (this.filters.category) {
      conditions.push(`category = "${this.filters.category}"`);
    }
    
    if (this.filters.hasReference) {
      conditions.push(`reference IS NOT NULL`);
    }
    
    if (this.filters.letter) {
      conditions.push(`title LIKE "${this.filters.letter}%"`);
    }
    
    return conditions.join(' AND ');
  }
  
  async ftsSearch(query, filters) {
    const sql = `
      SELECT s.* FROM songs s
      JOIN songs_fts ON s.song_id = songs_fts.rowid
      WHERE songs_fts MATCH ?
      ${filters ? 'AND ' + filters : ''}
      ORDER BY rank
      LIMIT 50
    `;
    
    return await this.db.execute(sql, [query]);
  }
}
```

### Search UI Components

```javascript
// 1. Search Bar with Autocomplete
<input 
  type="search"
  placeholder="गीत खोजें (Search song)..."
  @input="debounce(handleSearch, 300)"
/>

// 2. Filter Chips
<div class="filters">
  <select v-model="category">
    <option value="">सभी श्रेणियाँ</option>
    <option v-for="cat in categories">{{cat}}</option>
  </select>
  
  <div class="alphabet-nav">
    <button v-for="letter in alphabet">{{letter}}</button>
  </div>
</div>

// 3. Results List
<div class="results">
  <div v-for="song in results" class="result-item">
    <h3 v-html="song.highlightedTitle"></h3>
    <p class="category">{{song.category}}</p>
    <p class="snippet" v-html="song.highlightedSnippet"></p>
    <span class="reference">{{song.reference}}</span>
  </div>
</div>
```

---

## Advanced Features

### 1. **Voice Search** (Optional)
```javascript
const recognition = new webkitSpeechRecognition();
recognition.lang = 'hi-IN';
recognition.onresult = (event) => {
  const query = event.results[0][0].transcript;
  performSearch(query);
};
```

### 2. **Search by Song Number**
```javascript
// Direct navigation
if (/^\d+$/.test(query)) {
  const songId = parseInt(query);
  navigateToSong(songId);
}
```

### 3. **Multi-Language Search** (romanized Hindi)
```javascript
const romanToDevanagari = {
  'yesu': 'यीशु',
  'prabhu': 'प्रभु',
  'dhanyavad': 'धन्यवाद'
  // ... transliteration map
};
```

### 4. **Smart Query Understanding**
```javascript
function parseQuery(query) {
  // Detect search intent
  if (query.match(/\d+:\d+/)) {
    return { type: 'reference', value: query };
  }
  if (query.match(/^[अ-ह]$/)) {
    return { type: 'letter', value: query };
  }
  if (query.match(/^\d+$/)) {
    return { type: 'songNumber', value: query };
  }
  return { type: 'text', value: query };
}
```

---

## Performance Optimization

### 1. **Debouncing**
```javascript
const debounce = (fn, delay) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn(...args), delay);
  };
};
```

### 2. **Result Caching**
```javascript
const searchCache = new Map();

async function cachedSearch(query) {
  if (searchCache.has(query)) {
    return searchCache.get(query);
  }
  
  const results = await performSearch(query);
  searchCache.set(query, results);
  return results;
}
```

### 3. **Virtual Scrolling** (for large result sets)
Use virtual scrolling library for rendering 100+ results efficiently.

---

## UX Best Practices

1. **Instant Feedback**
   - Show results as user types (debounced)
   - Display "No results" with suggestions

2. **Clear Visual Hierarchy**
   - Title (bold, larger)
   - Category (subtle, labeled)
   - Snippet (highlighted matches)
   - Reference (if available)

3. **Quick Filters**
   - Category dropdown at top
   - Alphabet navigation for browsing
   - "Has reference" toggle

4. **Empty State**
   ```
   No results for "xyz"
   
   Suggestions:
   - Check spelling
   - Try simpler keywords
   - Browse by category
   - Browse alphabetically
   ```

5. **Loading States**
   - Skeleton screens while searching
   - "Searching..." indicator

---

## Implementation Priority

### Phase 1: Core Search ✅ (Already Done)
- [x] FTS5 database setup
- [x] Basic SQL search queries

### Phase 2: Basic UI (Week 1)
- [ ] Search input with debouncing
- [ ] Results list with highlighting
- [ ] Category filter dropdown
- [ ] Basic styling

### Phase 3: Enhanced Search (Week 2)
- [ ] Autocomplete suggestions
- [ ] Alphabet navigation
- [ ] Recent searches
- [ ] Search analytics

### Phase 4: Advanced Features (Week 3)
- [ ] Fuzzy matching
- [ ] Custom ranking
- [ ] Smart query parsing
- [ ] Performance optimization

---

## Sample Implementation

```javascript
// Complete working example
class SakshiVaniSearch {
  constructor(db) {
    this.db = db;
    this.setupEventListeners();
  }
  
  setupEventListeners() {
    const searchInput = document.getElementById('search');
    const categoryFilter = document.getElementById('category');
    
    searchInput.addEventListener('input', 
      this.debounce(async (e) => {
        await this.performSearch(e.target.value);
      }, 300)
    );
    
    categoryFilter.addEventListener('change', async (e) => {
      await this.performSearch(searchInput.value);
    });
  }
  
  async performSearch(query) {
    if (!query.trim()) {
      this.clearResults();
      return;
    }
    
    const category = document.getElementById('category').value;
    
    // Build FTS query
    let sql = `
      SELECT s.*, rank 
      FROM songs s
      JOIN songs_fts ON s.song_id = songs_fts.rowid
      WHERE songs_fts MATCH ?
    `;
    
    const params = [query];
    
    if (category) {
      sql += ` AND s.category = ?`;
      params.push(category);
    }
    
    sql += ` ORDER BY rank LIMIT 50`;
    
    const results = await this.db.execute(sql, params);
    this.displayResults(results, query);
  }
  
  displayResults(results, query) {
    const container = document.getElementById('results');
    
    if (results.length === 0) {
      container.innerHTML = `
        <div class="no-results">
          <p>कोई परिणाम नहीं मिला</p>
        </div>
      `;
      return;
    }
    
    container.innerHTML = results.map(song => `
      <div class="song-result" onclick="openSong(${song.song_id})">
        <h3>${this.highlight(song.title, query)}</h3>
        <p class="category">${song.category}</p>
        <p class="snippet">${this.getSnippet(song.lyrics, query)}</p>
        ${song.reference ? 
          `<span class="reference">${song.reference}</span>` : ''
        }
      </div>
    `).join('');
  }
  
  highlight(text, query) {
    const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  }
  
  getSnippet(lyrics, query, maxLength = 150) {
    const index = lyrics.toLowerCase().indexOf(query.toLowerCase());
    if (index === -1) {
      return lyrics.substring(0, maxLength) + '...';
    }
    
    const start = Math.max(0, index - 50);
    const end = Math.min(lyrics.length, index + query.length + 50);
    
    let snippet = lyrics.substring(start, end);
    if (start > 0) snippet = '...' + snippet;
    if (end < lyrics.length) snippet += '...';
    
    return this.highlight(snippet, query);
  }
  
  debounce(fn, delay) {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => fn(...args), delay);
    };
  }
  
  escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

// Initialize
const search = new SakshiVaniSearch(db);
```

---

## Conclusion

**Recommended Stack:**
1. **SQLite FTS5** - Primary search engine ✅ (Done)
2. **Debounced input** - UX optimization
3. **Multi-level filtering** - Category + Reference + Letter
4. **Smart ranking** - Title boost + relevance scoring
5. **Highlighting** - Visual feedback
6. **Fuzzy matching** - Error tolerance (Phase 3)

**Advantages:**
- ✅ Fast (FTS5 is very efficient)
- ✅ Offline-capable (PWA)
- ✅ Unicode-aware
- ✅ Scalable to thousands of songs
- ✅ No external dependencies

This design gives you a professional, user-friendly search experience for your Hindi hymn book! 🎯
