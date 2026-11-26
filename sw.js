// Matek-kaland service worker. Új kiadásnál a VERSION változik, így a régi gyorsítótár törlődik.
const VERSION = 'mk-v1.6';
const CORE = ['./', './index.html', './esemenyek.js', './konyvtar.js', './Képek/konyvtar.webp', './Karakterek/konyvtaros.webp', './manifest.webmanifest', './Ikonok/icon-192.png', './Ikonok/icon-512.png', './Ikonok/maskable-512.png', './Ikonok/apple-touch-icon.png', './Képek/img-6786e9fadd.webp', './Képek/img-17a5775f20.webp', './Képek/img-6a1d02971e.webp', './Képek/varazslotorony.webp', './Karakterek/img-b5819318d4.webp', './Karakterek/img-3aa1fe3696.webp', './Karakterek/img-762275f823.webp', './Karakterek/img-1894775d52.webp', './Karakterek/img-4e53a562e9.webp', './Karakterek/img-ee2a0647ed.webp', './Karakterek/img-7d75c75582.webp', './Karakterek/img-909e5ddc4e.webp', './Karakterek/img-86cbc207c2.webp', './Karakterek/img-9cc883cace.webp', './Karakterek/img-98ac8194bf.webp', './Karakterek/img-565c7460f5.webp', './Képek/falu2.webp', './Képek/img-e078c8c07b.webp', './Szornyek/gnoll.webp', './Szornyek/elemental.webp', './Szornyek/csontlovag.webp', './Szornyek/ork.webp', './Szornyek/sarkany.webp'];
self.addEventListener('install', e => { e.waitUntil(caches.open(VERSION).then(c => c.addAll(CORE)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== VERSION).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const req = e.request; if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (req.mode === 'navigate') {   // oldal: hálózat előbb (friss verzió), offline a mentett
    e.respondWith(fetch(req).then(r => { const c = r.clone(); caches.open(VERSION).then(x => x.put(req, c)); return r; })
      .catch(() => caches.match(req).then(hit => hit || caches.match('./index.html'))));
    return;
  }
  if (url.origin === location.origin || /fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {  // ikon, betűtípus: gyorsítótár előbb
    e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(r => { if (r.ok) { const c = r.clone(); caches.open(VERSION).then(x => x.put(req, c)); } return r; })));
  }
});
