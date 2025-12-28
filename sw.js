const CACHE_NAME = 'sakshivani-root-v1';

// Critical assets to cache immediately
const ASSETS = [
    '/',
    '/index.html',
    '/shared/theme.css',
    '/shared/reader.css',
    '/shared/theme.js',
    '/shared/reader.js',
    '/manifest.json', // Assuming a root manifest or we might need to cache specific module manifests

    // Dashboard Module
    '/dashboard-web/dashboard.html',
    '/dashboard-web/read_bible.html',
    '/dashboard-web/style.css',
    '/dashboard-web/app.js',
    '/dashboard-web/bible-reader.js',

    // PWA Module
    '/pwa/index.html',
    '/pwa/style.css',
    '/pwa/app.js',
    '/pwa/songs.js',
    '/pwa/songs.json',
    '/pwa/catechism.html',

    // Data (Heavy - Cache Carefully)
    '/dashboard-web/data/bible/books.js',
    '/dashboard-web/data/bible/en_data.js',
    '/dashboard-web/data/bible/hi_data.js'
];

self.addEventListener('install', (event) => {
    console.log('[Service Worker] Installing...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[Service Worker] Caching all assets');
                return cache.addAll(ASSETS);
            })
            .then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', (event) => {
    console.log('[Service Worker] Activating...');
    event.waitUntil(
        caches.keys().then((keyList) => {
            return Promise.all(keyList.map((key) => {
                if (key !== CACHE_NAME) {
                    console.log('[Service Worker] Removing old cache', key);
                    return caches.delete(key);
                }
            }));
        })
            .then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', (event) => {
    // Strategy: Cache First, fallback to Network
    // This provides the "Offline" experience.

    // Skip non-GET requests
    if (event.request.method !== 'GET') return;

    // Skip chrome-extension or other non-http schemes
    if (!event.request.url.startsWith('http')) return;

    event.respondWith(
        caches.match(event.request)
            .then((response) => {
                if (response) {
                    // console.log('[Service Worker] Serving from cache:', event.request.url);
                    return response;
                }

                // Fetch from network
                // console.log('[Service Worker] Fetching from network:', event.request.url);
                return fetch(event.request).then((networkResponse) => {
                    // Check if we received a valid response
                    if (!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
                        return networkResponse;
                    }

                    // Clone the response
                    const responseToCache = networkResponse.clone();

                    caches.open(CACHE_NAME)
                        .then((cache) => {
                            cache.put(event.request, responseToCache);
                        });

                    return networkResponse;
                });
            })
    );
});
