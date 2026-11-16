// Telefona "uygulama olarak kur" için gereken küçük çalışan.
// Veri ÖNBELLEĞE ALINMAZ (her zaman canlı veritabanından gelir); yalnız sayfa iskeleti.
const SURUM = 'crm-v2';
const ISKELET = ['./', 'index.html', 'ayar.js', 'manifest.webmanifest', 'ikon-192.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(SURUM).then(c => c.addAll(ISKELET)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== SURUM).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
// Önce ağ, olmazsa önbellek (güncelleme her zaman hemen gelir)
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin) return;
  e.respondWith(
    fetch(e.request).then(r => { const k = r.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); return r; })
      .catch(() => caches.match(e.request).then(r => r || caches.match('index.html')))
  );
});
