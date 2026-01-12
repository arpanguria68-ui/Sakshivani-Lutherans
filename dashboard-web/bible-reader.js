/**
 * Bible Reader Logic
 * Handles data loading, navigation, and search.
 */

// State
const state = {
    lang: 'en', // 'en' or 'hi'
    currentBookIndex: 0,
    currentChapterIndex: 0,
    isSidebarOpen: window.innerWidth > 768,
    searchResults: [],
    // Diagnostic State
    lastError: null,
    dataStatus: { en: false, hi: false }
};

// DOM Elements
const elements = {
    bookSelect: document.getElementById('book-select'),
    chapterSelect: document.getElementById('chapter-select'),
    prevBtn: document.getElementById('prev-chapter'),
    nextBtn: document.getElementById('next-chapter'),
    verseDisplay: document.getElementById('verse-display'),
    chapterTitle: document.querySelector('.chapter-title'),
    langBtns: document.querySelectorAll('.lang-btn'),
    sidebar: document.getElementById('sidebar'),
    sidebarToggle: document.getElementById('sidebar-toggle'),
    searchInput: document.getElementById('search-input'),
    bookList: document.getElementById('book-list'),
    searchResults: document.getElementById('search-results'),
    loader: document.getElementById('loader'),
    readerContainer: document.getElementById('reader-container')
};

// --- Initialization ---

function init() {
    // 1. Try to load from Hash first (Deep Linking)
    const hash = window.location.hash.substring(1); // Remove #
    let loadedFromHash = false;

    if (hash) {
        // Expected format: BookName/ChapterNum (e.g. "Genesis/1")
        const [bookNameURI, chapterNum] = hash.split('/');
        if (bookNameURI && chapterNum) {
            const bookNames = getBookNames();
            // Find book index (ignoring case/spaces for robustness)
            const bookIndex = bookNames.findIndex(b =>
                b.replace(/\s+/g, '').toLowerCase() === bookNameURI.toLowerCase()
            );

            if (bookIndex !== -1) {
                state.currentBookIndex = bookIndex;
                state.currentChapterIndex = Math.max(0, parseInt(chapterNum) - 1); // 1-based to 0-based
                loadedFromHash = true;
            }
        }
    }

    // 2. Fallback to localStorage if no valid hash
    if (!loadedFromHash) {
        const saved = localStorage.getItem('bibleState');
        if (saved) {
            const parsed = JSON.parse(saved);
            state.lang = parsed.lang || 'en';
            state.currentBookIndex = parsed.currentBookIndex || 0;
            state.currentChapterIndex = parsed.currentChapterIndex || 0;
        }
    }

    // Set initial UI state
    updateLangUI();
    populateBookSelect();
    populateChapterSelect();
    renderSidebarBooks();

    // Load initial content
    loadChapter();

    // Event Listeners
    setupEventListeners();

    // Explicit Hash Change Listener for manual URL edits
    window.addEventListener('hashchange', handleHashChange);

    // Update history correctly if we loaded from storage/default
    if (!loadedFromHash) {
        pushHistoryState();
    }

    // Inject Diagnostics -> REMOVED

}

function handleHashChange() {
    const hash = window.location.hash.substring(1);
    const [bookNameURI, chapterNum] = hash.split('/');
    if (bookNameURI && chapterNum) {
        const bookNames = getBookNames();
        const bookIndex = bookNames.findIndex(b =>
            b.replace(/\s+/g, '').toLowerCase() === bookNameURI.toLowerCase()
        );

        if (bookIndex !== -1) {
            const newChapterIndex = Math.max(0, parseInt(chapterNum) - 1);

            // Only reload if changed
            if (bookIndex !== state.currentBookIndex || newChapterIndex !== state.currentChapterIndex) {
                state.currentBookIndex = bookIndex;
                state.currentChapterIndex = newChapterIndex;
                loadChapter();
                // We do NOT call pushHistoryState here to avoid loop, 
                // but we should update selects
                elements.bookSelect.value = state.currentBookIndex;
                populateChapterSelect();
                elements.chapterSelect.value = state.currentChapterIndex;
                renderSidebarBooks();
            }
        }
    }
}

function setupEventListeners() {
    // Navigation Dropdowns
    elements.bookSelect.addEventListener('change', (e) => {
        state.currentBookIndex = parseInt(e.target.value);
        state.currentChapterIndex = 0; // Reset to ch 1
        populateChapterSelect();
        loadChapter();
        pushHistoryState(); // Add to history
        saveState();
    });

    elements.chapterSelect.addEventListener('change', (e) => {
        state.currentChapterIndex = parseInt(e.target.value);
        loadChapter();
        pushHistoryState(); // Add to history
        saveState();
    });

    // Next/Prev Buttons
    elements.prevBtn.addEventListener('click', prevChapter);
    elements.nextBtn.addEventListener('click', nextChapter);

    // Sidebar Toggle
    elements.sidebarToggle.addEventListener('click', () => {
        elements.sidebar.classList.toggle('collapsed');
        elements.sidebar.classList.toggle('open'); // For mobile
    });

    // Language Toggle
    elements.langBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const newLang = btn.dataset.lang;
            if (newLang !== state.lang) {
                state.lang = newLang;
                updateLangUI();
                populateBookSelect(); // Re-populate with new language names
                renderSidebarBooks();
                loadChapter(); // Reload text in new language
                saveState();
            }
        });
    });

    // Search
    let searchTimeout;
    elements.searchInput.addEventListener('input', (e) => {
        clearTimeout(searchTimeout);
        const query = e.target.value.trim();

        if (query.length < 2) {
            elements.bookList.style.display = 'block';
            elements.searchResults.style.display = 'none';
            return;
        }

        searchTimeout = setTimeout(() => performSearch(query), 300);
    });
}

// --- Data Access Helpers ---

// --- Data Access Helpers ---

function getBibleData() {
    if (state.lang === 'en') {
        return typeof EN_BIBLE !== 'undefined' ? EN_BIBLE : null;
    } else {
        return typeof HI_BIBLE !== 'undefined' ? HI_BIBLE : null;
    }
}

function getBookNames() {
    return BIBLE_BOOKS[state.lang] || [];
}

function getCurrentBook() {
    const data = getBibleData();
    if (data && data.Book && data.Book[state.currentBookIndex]) {
        return data.Book[state.currentBookIndex];
    }
    return null;
}

function getCurrentChapter() {
    const book = getCurrentBook();
    if (book && book.Chapter && book.Chapter[state.currentChapterIndex]) {
        return book.Chapter[state.currentChapterIndex];
    }
    return null;
}

// --- Rendering ---

function updateLangUI() {
    elements.langBtns.forEach(btn => {
        if (btn.dataset.lang === state.lang) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
}

function populateBookSelect() {
    const books = getBookNames();
    elements.bookSelect.innerHTML = books.map((name, index) =>
        `<option value="${index}" ${index === state.currentBookIndex ? 'selected' : ''}>${name}</option>`
    ).join('');
}

function populateChapterSelect() {
    const book = getCurrentBook();
    if (!book) return;

    const chapterCount = book.Chapter.length;
    elements.chapterSelect.innerHTML = Array.from({ length: chapterCount }, (_, i) =>
        `<option value="${i}" ${i === state.currentChapterIndex ? 'selected' : ''}>Ch ${i + 1}</option>`
    ).join('');
}

function renderSidebarBooks() {
    const books = getBookNames();
    elements.bookList.innerHTML = books.map((name, index) => `
        <div class="book-list-item ${index === state.currentBookIndex ? 'active' : ''}" 
             onclick="jumpToBook(${index})">
            <span>${name}</span>
            <ion-icon name="chevron-forward" style="opacity: 0.5"></ion-icon>
        </div>
    `).join('');
}

function loadChapter() {
    elements.loader.classList.add('visible');

    // Update Diagnostic Overlay
    // Update Diagnostic Overlay -> REMOVED

    setTimeout(() => {
        try {
            // Clear previous reader instance
            if (state.reader) {
                state.reader.destroy();
                state.reader = null;
            }

            const book = getCurrentBook();
            const chapter = getCurrentChapter();
            const bookNames = getBookNames();
            const bookName = bookNames[state.currentBookIndex] || 'Unknown Book';

            // Error Handling for Missing Content
            if (!book || !chapter) {
                console.error('Content missing for', state.lang, state.currentBookIndex, state.currentChapterIndex);

                elements.chapterTitle.textContent = "Error";
                elements.verseDisplay.innerHTML = `
                <div class="error-message" style="text-align: center; padding: 2rem; color: var(--text-muted);">
                    <h3>Content Unavailable</h3>
                    <p>The requested chapter could not be loaded.</p>
                    <p>Please check your connection or try another language/book.</p>
                    ${state.lang === 'hi' && typeof HI_BIBLE === 'undefined' ? '<p style="color:red; font-size: 0.9em;">(System Hint: Hindi Data File Missing)</p>' : ''}
                </div>
            `;
                elements.loader.classList.remove('visible');
                return;
            }

            // Update Title
            elements.chapterTitle.textContent = `${bookName} ${state.currentChapterIndex + 1}`;

            // Render Verses
            // Handle potential XML-JSON anomalies where single child is object not array
            let verses = [];
            if (chapter.Verse) {
                verses = Array.isArray(chapter.Verse) ? chapter.Verse : [chapter.Verse];
            }

            if (verses.length > 0) {
                elements.verseDisplay.innerHTML = verses.map(v => {
                    // Verseid is typically "00001000". slice(-3) gives "000". parseInt is 0. Conventionally this is Verse 1.
                    // We add 1 to correct the display.
                    const verseNum = parseInt(v.Verseid.slice(-3)) + 1;
                    return `
                <div class="verse-unit">
                    <sup class="verse-num">${verseNum}</sup>
                    <span class="text-content">${v.Verse}</span>
                </div>
            `}).join('');

                // Initialize Accessible Reader
                if (typeof AccessibleReader !== 'undefined') {
                    state.reader = new AccessibleReader(elements.readerContainer);
                    state.reader.setLanguage(state.lang);
                    state.reader.init();
                }
            } else {
                elements.verseDisplay.innerHTML = '<div style="padding:1rem;">(No verses found in this chapter)</div>';
            }

            // Sync Selects
            elements.bookSelect.value = state.currentBookIndex;
            populateChapterSelect();
            elements.chapterSelect.value = state.currentChapterIndex;

            // update sidebar active
            renderSidebarBooks();

            elements.readerContainer.scrollTop = 0;
            elements.loader.classList.remove('visible');

        } catch (e) {
            console.error("Critical Error in loadChapter:", e);
            state.lastError = e.message;
            elements.verseDisplay.innerHTML = `<div class="error-message">Error: ${e.message}</div>`;
        } finally {
            elements.loader.classList.remove('visible');

        }
    }, 50);
}



// --- Navigation Actions ---

function prevChapter() {
    if (state.currentChapterIndex > 0) {
        state.currentChapterIndex--;
        loadChapter();
        pushHistoryState();
    } else if (state.currentBookIndex > 0) {
        state.currentBookIndex--;
        // Go to last chapter of prev book
        const prevBook = getCurrentBook();
        if (prevBook && prevBook.Chapter) {
            state.currentChapterIndex = prevBook.Chapter.length - 1;
        } else {
            state.currentChapterIndex = 0; // Fallback
        }
        loadChapter();
        pushHistoryState();
    }
    saveState();
}

function nextChapter() {
    const book = getCurrentBook();
    if (!book || !book.Chapter) return; // Prevent crash if data missing

    if (state.currentChapterIndex < book.Chapter.length - 1) {
        state.currentChapterIndex++;
        loadChapter();
        pushHistoryState();
    } else if (state.currentBookIndex < getBookNames().length - 1) {
        state.currentBookIndex++;
        state.currentChapterIndex = 0;
        loadChapter();
        pushHistoryState();
    }
    saveState();
}

function jumpToBook(index) {
    state.currentBookIndex = index;
    state.currentChapterIndex = 0;
    populateChapterSelect();
    loadChapter();
    pushHistoryState();
    saveState();

    // On mobile, close sidebar
    if (window.innerWidth < 768) {
        elements.sidebar.classList.remove('open');
    }
}

function saveState() {
    localStorage.setItem('bibleState', JSON.stringify(state));
}

// --- Search Implementation ---

function performSearch(query) {
    elements.bookList.style.display = 'none';
    elements.searchResults.style.display = 'block';
    elements.searchResults.innerHTML = '<div style="padding: 10px; color: var(--text-muted);">Searching...</div>';

    // Offload to timeout to not freeze UI
    setTimeout(() => {
        const results = [];
        const data = getBibleData();
        const bookNames = getBookNames();
        const lowerQuery = query.toLowerCase();

        // Limit results for performance
        const MAX_RESULTS = 50;
        let count = 0;

        // Iterate Books
        data.Book.forEach((book, bIndex) => {
            if (count >= MAX_RESULTS) return;

            // Iterate Chapters
            book.Chapter.forEach((chapter, cIndex) => {
                if (count >= MAX_RESULTS) return;

                const verses = Array.isArray(chapter.Verse) ? chapter.Verse : [chapter.Verse];

                verses.forEach((verse, vIndex) => {
                    if (count >= MAX_RESULTS) return;

                    if (verse.Verse && verse.Verse.toLowerCase().includes(lowerQuery)) {
                        results.push({
                            bookIndex: bIndex,
                            chapterIndex: cIndex,
                            verseIndex: vIndex,
                            text: verse.Verse,
                            reference: `${bookNames[bIndex]} ${cIndex + 1}:${vIndex + 1}`
                        });
                        count++;
                    }
                });
            });
        });

        // Render Results
        if (results.length === 0) {
            elements.searchResults.innerHTML = '<div style="padding: 10px; color: var(--text-muted);">No results found.</div>';
        } else {
            elements.searchResults.innerHTML = results.map(r => `
                <div class="book-list-item" style="display: block;" 
                     onclick="jumpToResult(${r.bookIndex}, ${r.chapterIndex})">
                    <div style="font-weight: 600; color: var(--primary); margin-bottom: 4px;">${r.reference}</div>
                    <div style="font-size: 0.9em; opacity: 0.8; line-height: 1.4;">
                        ${highlightMatch(r.text, query)}
                    </div>
                </div>
            `).join('');
        }
    }, 10);
}

function highlightMatch(text, query) {
    const regex = new RegExp(`(${query})`, 'gi');
    return text.replace(regex, '<span style="background: rgba(59, 130, 246, 0.3); color: white;">$1</span>');
}

window.jumpToResult = function (bIndex, cIndex) {
    state.currentBookIndex = bIndex;
    state.currentChapterIndex = cIndex;
    loadChapter();
    pushHistoryState();

    // Close sidebar on mobile
    if (window.innerWidth < 768) {
        elements.sidebar.classList.remove('open');
        elements.sidebar.classList.add('collapsed');
    }
};

window.jumpToBook = jumpToBook;

// Start
document.addEventListener('DOMContentLoaded', init);

// --- History Management ---

function pushHistoryState() {
    const bookNames = getBookNames();
    const bookName = bookNames[state.currentBookIndex];
    // Create a readable hash or query if desired, but state object is key
    // We'll use a hash like #Genesis.1 for deep linking visibility if needed, 
    // or just rely on state object for the mechanism.
    // Let's use a nice hash format: #BookName/Chapter

    // Sanitize book name for URL
    const safeBookName = bookName.replace(/\s+/g, '');
    const urlHash = `#${safeBookName}/${state.currentChapterIndex + 1}`;

    history.pushState({
        ...state
    }, '', urlHash);
}

window.addEventListener('popstate', (event) => {
    if (event.state) {
        // Restore state from history
        state.lang = event.state.lang || state.lang;
        state.currentBookIndex = event.state.currentBookIndex;
        state.currentChapterIndex = event.state.currentChapterIndex;

        // Update UI without pushing new state
        // We need to handle this carefully to not create loops
        // Ideally loadChapter just renders.

        // Sync Controls
        updateLangUI();
        populateBookSelect(); // In case lang changed
        populateChapterSelect();

        loadChapter(false); // Pass false to indicate "don't push state"
    }
});

// override loadChapter to accept a pushState flag?
// No, better to call pushState explicitly in navigation actions.

// We need to modify navigation actions to call pushHistoryState()

