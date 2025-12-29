const CACHE_NAME = 'sakshivani-v24';
const ASSETS = [
    '/',
    'index.html',
    'style.css',
    'app.js',
    'manifest.json',
    'songs.json',
    'catechism.html',
    'catechism/1-commandments.html',
    'catechism/2-creed.html',
    'catechism/3-prayer.html',
    'catechism/4-baptism.html',
    'catechism/5-communion.html',
    'catechism/6-confession.html',
    'catechism/7-app1.html',
    'catechism/8-app2.html',
    'catechism/9-app3.html',
    'catechism/10-app4.html',
    'icons/icon-192x192.png',
    'icons/icon-512x512.png'
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(ASSETS))
    );
});

self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request)
            .then((response) => response || fetch(event.request))
    );
});
