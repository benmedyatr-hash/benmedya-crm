// ESKİ kök çalışan (uygulama /app/'e taşındı). Telefonlarda kalan eski kaydı temizleyip kendini kaldırır.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    const ks = await caches.keys();
    await Promise.all(ks.filter(k => /^crm-v\d/.test(k)).map(k => caches.delete(k)));
    await self.registration.unregister();
  })());
});
