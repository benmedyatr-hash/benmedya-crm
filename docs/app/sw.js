// Firma uygulamasını "uygulama olarak kur" için. Veri önbelleğe alınmaz; önce ağ, olmazsa önbellek.
// Ayrıca telefon bildirimlerini (Web Push) gösterir — uygulama kapalı / telefon kilitliyken de.
const SURUM = 'crm-app-v24';
const ISKELET = ['./', 'index.html', '../ayar.js', '../sektorler.js?v=2', 'manifest.webmanifest', 'ikon-192.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(SURUM).then(c => c.addAll(ISKELET)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k.startsWith('crm-app') && k !== SURUM).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin) return;
  e.respondWith(
    fetch(e.request).then(r => { const k = r.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); return r; })
      .catch(() => caches.match(e.request).then(r => r || caches.match('index.html')))
  );
});

self.addEventListener('push', e => {
  let v = {};
  try { v = e.data ? e.data.json() : {}; } catch (_) { v = { govde: e.data && e.data.text() }; }
  e.waitUntil(self.registration.showNotification(v.baslik || 'CRM', {
    body: v.govde || '',
    tag: v.etiket || undefined,
    icon: 'ikon-192.png',
    badge: 'ikon-192.png',
    data: { url: v.url || './' }
  }));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const hedef = new URL((e.notification.data && e.notification.data.url) || './', self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ws => {
    for (const w of ws) if (w.url.startsWith(self.registration.scope) && 'focus' in w) return w.focus();
    return self.clients.openWindow(hedef);
  }));
});
