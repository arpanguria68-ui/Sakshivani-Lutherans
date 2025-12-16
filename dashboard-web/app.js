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
const verses = [
    {
        text: '"क्योंकि मैं तुम्हारे लिए जो योजनाएँ बनाता हूँ, उन्हें मैं जानता हूँ, तुम्हें आशा और भविष्य देने की योजनाएँ।"',
        reference: '— यिर्मयाह 29:11'
    },
    {
        text: '"प्रभु पर भरोसा रखो और भलाई करो, धरती पर बसो और विश्वासयोग्यता से जीवित रहो।"',
        reference: '— भजन संहिता 37:3'
    },
    {
        text: '"मैं तुम्हें ताकत देता हूँ जब तुम थक जाते हो, और जब तुम कमजोर होते हो तो शक्ति बढ़ाता हूँ।"',
        reference: '— यशायाह 40:29'
    },
    {
        text: '"परमेश्वर ही हमारा आश्रय और शक्ति है, संकट में अति सहायक।"',
        reference: '— भजन संहिता 46:1'
    }
];

// Load or generate daily verse
function loadDailyVerse() {
    const verseText = document.querySelector('.verse-text');
    const verseRef = document.querySelector('.verse-reference');

    if (!verseText || !verseRef) return;

    // Check if we have a verse for today
    const today = new Date().toDateString();
    const savedDate = localStorage.getItem('verseDate');
    let verseIndex = parseInt(localStorage.getItem('verseIndex') || '0');

    // If it's a new day, pick a new verse
    if (savedDate !== today) {
        verseIndex = Math.floor(Math.random() * verses.length);
        localStorage.setItem('verseDate', today);
        localStorage.setItem('verseIndex', verseIndex.toString());
    }

    const verse = verses[verseIndex];
    verseText.textContent = verse.text;
    verseRef.textContent = verse.reference;
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
