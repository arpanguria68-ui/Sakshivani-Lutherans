// Theme Toggle
const themeToggle = document.getElementById('theme-toggle');
const root = document.documentElement;

let isDark = true;

if (themeToggle) {
    themeToggle.addEventListener('click', () => {
        isDark = !isDark;

        if (isDark) {
            root.removeAttribute('data-theme');
            themeToggle.querySelector('ion-icon').setAttribute('name', 'moon');
        } else {
            root.setAttribute('data-theme', 'light');
            themeToggle.querySelector('ion-icon').setAttribute('name', 'sunny');
        }

        // Save preference
        localStorage.setItem('theme', isDark ? 'dark' : 'light');
    });

    // Load saved theme
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'light') {
        isDark = false;
        root.setAttribute('data-theme', 'light');
        themeToggle.querySelector('ion-icon').setAttribute('name', 'sunny');
    }
}

// Navigation
function navigateTo(url) {
    window.location.href = url;
}

// Greeting based on time
function updateGreeting() {
    const greetingEl = document.querySelector('.greeting');
    if (!greetingEl) return;

    const hour = new Date().getHours();
    let greeting = 'Good Morning';

    if (hour >= 12 && hour < 17) {
        greeting = 'Good Afternoon';
    } else if (hour >= 17) {
        greeting = 'Good Evening';
    }

    greetingEl.textContent = greeting;
}

updateGreeting();

// Daily Verse (Random selection - in production, fetch from API or database)
// Daily Verse from Bible Database
function loadDailyVerse() {
    const verseText = document.querySelector('.verse-text');
    const verseRef = document.querySelector('.verse-reference');

    if (!verseText || !verseRef) return;

    // Check if we already have a verse for today to avoid changing it on reload
    const today = new Date().toDateString();
    const savedDate = localStorage.getItem('verseDate');

    if (savedDate === today) {
        // Load saved verse
        verseText.textContent = localStorage.getItem('verseText');
        verseRef.textContent = localStorage.getItem('verseRef');
        return;
    }

    // Generate new verse from database if available
    if (typeof HI_BIBLE !== 'undefined' && typeof BIBLE_BOOKS !== 'undefined') {
        try {
            // Pick Random Book
            const books = HI_BIBLE.Book;
            const bookIndex = Math.floor(Math.random() * books.length);
            const book = books[bookIndex];
            const bookName = BIBLE_BOOKS['hi'][bookIndex];

            // Pick Random Chapter
            const chapterIndex = Math.floor(Math.random() * book.Chapter.length);
            const chapter = book.Chapter[chapterIndex];

            // Pick Random Verse
            // Handle array vs single object for Verse
            const verses = Array.isArray(chapter.Verse) ? chapter.Verse : [chapter.Verse];
            const verseIndex = Math.floor(Math.random() * verses.length);
            const verseObj = verses[verseIndex];

            // Format parts
            const cleanText = verseObj.Verse.replace(/"/g, ''); // Remove existing quotes if any
            const vText = `"${cleanText}"`;

            // Calculate real verse number
            let vNum = verseIndex + 1;
            if (verseObj.Verseid) {
                vNum = parseInt(verseObj.Verseid) % 1000 + 1;
            }

            const vRef = `— ${bookName} ${chapterIndex + 1}:${vNum}`;

            // Update UI
            verseText.textContent = vText;
            verseRef.textContent = vRef;

            // Save for the day
            localStorage.setItem('verseDate', today);
            localStorage.setItem('verseText', vText);
            localStorage.setItem('verseRef', vRef);

        } catch (e) {
            console.error("Error generating verse:", e);
            // Fallback
            verseText.textContent = '"परमेश्वर ही हमारा आश्रय और शक्ति है, संकट में अति सहायक।"';
            verseRef.textContent = '— भजन संहिता 46:1';
        }
    } else {
        // Fallback if data not loaded
        verseText.textContent = '"प्रभु पर भरोसा रखो और भलाई करो, धरती पर बसो और विश्वासयोग्यता से जीवित रहो।"';
        verseRef.textContent = '— भजन संहिता 37:3';
    }
}

loadDailyVerse();

// Share Verse
const shareBtn = document.querySelector('.share-btn');
if (shareBtn) {
    shareBtn.addEventListener('click', async () => {
        const verseText = document.querySelector('.verse-text').textContent;
        const verseRef = document.querySelector('.verse-reference').textContent;
        const shareText = `${verseText}\n\n${verseRef}`;

        if (navigator.share) {
            try {
                await navigator.share({
                    title: 'Verse of the Day',
                    text: shareText
                });
            } catch (err) {
                console.log('Share cancelled');
            }
        } else {
            // Fallback: Copy to clipboard
            navigator.clipboard.writeText(shareText);
            alert('Verse copied to clipboard!');
        }
    });
}

// Tracking Store (Simple localStorage implementation)
const trackingStore = {
    getPrayerCount() {
        const logs = JSON.parse(localStorage.getItem('prayerLogs') || '[]');
        return logs.length;
    },

    getBibleReadingCount() {
        const logs = JSON.parse(localStorage.getItem('bibleLogs') || '[]');
        return logs.length;
    },

    getChurchCount() {
        const logs = JSON.parse(localStorage.getItem('churchLogs') || '[]');
        return logs.length;
    },

    getReflectionCount() {
        const logs = JSON.parse(localStorage.getItem('reflectionLogs') || '[]');
        return logs.length;
    },

    addPrayerLog(log) {
        const logs = JSON.parse(localStorage.getItem('prayerLogs') || '[]');
        logs.push({ ...log, timestamp: new Date().toISOString() });
        localStorage.setItem('prayerLogs', JSON.stringify(logs));
    },

    addBibleLog(log) {
        const logs = JSON.parse(localStorage.getItem('bibleLogs') || '[]');
        logs.push({ ...log, timestamp: new Date().toISOString() });
        localStorage.setItem('bibleLogs', JSON.stringify(logs));
    },

    addChurchLog(log) {
        const logs = JSON.parse(localStorage.getItem('churchLogs') || '[]');
        logs.push({ ...log, timestamp: new Date().toISOString() });
        localStorage.setItem('churchLogs', JSON.stringify(logs));
    },

    addReflectionLog(log) {
        const logs = JSON.parse(localStorage.getItem('reflectionLogs') || '[]');
        logs.push({ ...log, timestamp: new Date().toISOString() });
        localStorage.setItem('reflectionLogs', JSON.stringify(logs));
    }
};

// Update dashboard stats if on dashboard page
function updateDashboardStats() {
    const prayerStat = document.getElementById('prayer-stat');
    const bibleStat = document.getElementById('bible-stat');
    const churchStat = document.getElementById('church-stat');
    const reflectionStat = document.getElementById('reflection-stat');

    if (prayerStat) prayerStat.textContent = trackingStore.getPrayerCount();
    if (bibleStat) bibleStat.textContent = trackingStore.getBibleReadingCount();
    if (churchStat) churchStat.textContent = trackingStore.getChurchCount();
    if (reflectionStat) reflectionStat.textContent = trackingStore.getReflectionCount();
}

updateDashboardStats();
