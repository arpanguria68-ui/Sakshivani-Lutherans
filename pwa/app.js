document.addEventListener('DOMContentLoaded', () => {
    // Register Service Worker
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('./sw.js')
            .then(reg => console.log('Service Worker Registered'))
            .catch(err => console.log('Service Worker Error', err));
    }

    const songList = document.getElementById('song-list');
    const searchInput = document.getElementById('search-input');
    const songDetail = document.getElementById('song-detail');
    const backBtn = document.getElementById('back-btn');
    const detailTitle = document.getElementById('detail-title');
    const detailLyrics = document.getElementById('detail-lyrics');

    let allSongs = [];

    // Fetch Data
    fetch('./songs.json')
        .then(response => response.json())
        .then(data => {
            allSongs = data.sort((a, b) => a.id - b.id);
            renderSongs(allSongs);
        })
        .catch(err => console.error('Error loading songs:', err));

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
        detailLyrics.textContent = song.lyrics;

        songDetail.classList.add('active');

        // Push history state to allow back button
        history.pushState({ songId: song.id }, null, `#song${song.id}`);
    }

    // Hide Song Detail
    function hideSong() {
        songDetail.classList.remove('active');
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
