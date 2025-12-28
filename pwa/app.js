document.addEventListener('DOMContentLoaded', () => {
    // Service Worker is now registered globally in shared/theme.js

    // Focus search if navigated with #search hash
    if (window.location.hash === '#search') {
        const searchInput = document.getElementById('search-input');
        if (searchInput) {
            setTimeout(() => {
                searchInput.focus();
                searchInput.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }, 300);
        }
    }

    const songList = document.getElementById('song-list');
    const searchInput = document.getElementById('search-input');
    const songDetail = document.getElementById('song-detail');
    const backBtn = document.getElementById('back-btn');
    const detailTitle = document.getElementById('detail-title');
    const detailLyrics = document.getElementById('detail-lyrics');

    let allSongs = [];

    // Fetch Data (Modified to use global variable for file:// support)
    if (typeof SONGS_DATA !== 'undefined') {
        allSongs = SONGS_DATA.sort((a, b) => a.id - b.id);
        renderSongs(allSongs);
    } else {
        // Fallback for server environment or if script missing
        fetch('/pwa/songs.json')
            .then(response => response.json())
            .then(data => {
                allSongs = data.sort((a, b) => a.id - b.id);
                renderSongs(allSongs);
            })
            .catch(err => {
                console.error('Error loading songs:', err);
                songList.innerHTML = '<li style="padding:1rem; text-align:center; color:red">Error loading songs. Please check console.</li>';
            });
    }

    // Render List
    function renderSongs(songs) {
        songList.innerHTML = '';
        songs.forEach(song => {
            const li = document.createElement('li');
            li.className = 'song-item';
            li.onclick = () => showSong(song);

            const title = document.createElement('div');
            title.className = 'song-title';
            title.textContent = `${song.id}. ${song.title}`;

            const meta = document.createElement('div');
            meta.className = 'song-meta';
            const categorySpan = document.createElement('span');
            categorySpan.textContent = song.category || '';
            const refSpan = document.createElement('span');
            refSpan.textContent = song.reference || '';

            meta.appendChild(categorySpan);
            meta.appendChild(refSpan);

            li.appendChild(title);
            li.appendChild(meta);
            songList.appendChild(li);
        });

        if (songs.length === 0) {
            songList.innerHTML = '<li style="padding:1rem; text-align:center; color:var(--text-secondary)">No songs found</li>';
        }
    }

    // Search functionality
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase().trim();
        if (!query) {
            renderSongs(allSongs);
            return;
        }

        const filtered = allSongs.filter(song =>
            song.title.toLowerCase().includes(query) ||
            song.lyrics.toLowerCase().includes(query) ||
            song.id.toString().includes(query)
        );
        renderSongs(filtered);
    });

    // Show Song Detail
    function showSong(song) {
        detailTitle.textContent = `${song.id}. ${song.title}`;

        // Format Lyrics: Ensure formatting is clean
        // 1. Remove initial numbers if they are redundant with verse numbers? 
        // The lyrics in JSON have "1- ...", "2- ..." which is good.
        // We will just display it as is, relying on pre-wrap

        // BETTER: Split by newline to create chunks for Reader
        const lines = song.lyrics.split('\n');
        detailLyrics.innerHTML = ''; // Clear text

        lines.forEach((line, i) => {
            const trimmed = line.trim();
            if (trimmed) {
                const div = document.createElement('div');
                div.className = 'song-line';
                div.textContent = trimmed;
                detailLyrics.appendChild(div);
            } else {
                // Keep spacing
                const br = document.createElement('br');
                detailLyrics.appendChild(br);
            }
        });

        songDetail.classList.add('active');

        // Push history state to allow back button
        history.pushState({ songId: song.id }, null, `#song${song.id}`);

        // Initialize Reader
        if (window.AccessibleReader) {
            setTimeout(() => {
                // We use a property on the function to store instance if needed, or just let garbage collection handle old one
                // Since we only have one detail view open at a time:
                window.currentReader = new window.AccessibleReader('#detail-content');
            }, 300); // Wait for transition
        }
    }

    // Hide Song Detail
    function hideSong() {
        songDetail.classList.remove('active');

        // Stop Reader if playing
        if (window.currentReader && window.currentReader.destroy) {
            window.currentReader.destroy();
            window.currentReader = null;
        } else if (window.currentReader && window.currentReader.pause) {
            window.currentReader.pause(); // Fallback
        }
        // Hide toolbar
        const toolbar = document.querySelector('.reader-toolbar');
        if (toolbar) toolbar.classList.remove('visible');

        // Clear history hash if needed, or just let it depend on back button logic
        if (window.location.hash) {
            history.back();
        }
    }

    backBtn.addEventListener('click', () => {
        songDetail.classList.remove('active');
        history.back();
    });

    // Handle Hardware Back Button
    window.addEventListener('popstate', (e) => {
        if (!e.state) {
            songDetail.classList.remove('active');
        } else {
            // If we deeply link, we might handle it here, but for now just close
            // Actually if we popstate TO a state, we might want to open, but simpler logic is:
            // If hash is empty, close modal.
        }
    });
});
