// Sektör şablonları — firma uygulaması ve yönetim paneli BU dosyayı ortak kullanır.
// ek: müşteri kartındaki sektöre özel alanın adı · uyari: kartta kırmızı görünen alanın adı
// hizmetler: [ad, süre (dk), örnek fiyat ₺] — firma ilk girişte bunlarla başlar, sonra kendisi düzenler.
// ANAHTARLARI DEĞİŞTİRME (genel, guzellik, saglik, oto, teknik, egitim, danismanlik firmalarda kayıtlı).
window.SEKTOR_GRUPLARI = ['Genel', 'Güzellik & Bakım', 'Sağlık', 'Spor & Eğitim', 'Otomotiv', 'Ev & Teknik Hizmetler', 'Profesyonel Hizmetler', 'Etkinlik, Moda & Yaşam'];
window.SEKTORLER = {
  genel:        { grup: 'Genel', ad: 'Genel / Diğer', ek: 'Ek bilgi', uyari: 'Önemli not', hizmetler: [['Hizmet', 60, 1000], ['Görüşme', 30, 500], ['Kontrol', 30, 400]] },

  guzellik:     { grup: 'Güzellik & Bakım', ad: 'Güzellik Merkezi', ek: 'Cilt / saç tipi', uyari: 'Alerji / dikkat', hizmetler: [['Lazer Epilasyon', 60, 2500], ['Cilt Bakımı', 75, 1500], ['Kaş Laminasyon', 45, 900], ['İpek Kirpik', 90, 1800], ['Manikür', 45, 500], ['Bölgesel İncelme', 60, 1200]] },
  kuafor:       { grup: 'Güzellik & Bakım', ad: 'Kuaför (Kadın)', ek: 'Saç tipi / renk no', uyari: 'Alerji / dikkat', hizmetler: [['Saç Kesimi', 45, 600], ['Fön', 30, 300], ['Boya', 120, 1500], ['Röfle / Balyaj', 180, 3000], ['Keratin Bakım', 150, 2500], ['Gelin Saçı', 120, 4000]] },
  berber:       { grup: 'Güzellik & Bakım', ad: 'Berber / Erkek Kuaförü', ek: 'Tercih (kesim modeli)', uyari: 'Önemli not', hizmetler: [['Saç Kesimi', 30, 400], ['Sakal Tıraşı', 20, 200], ['Saç + Sakal', 45, 550], ['Cilt Bakımı', 30, 400], ['Damat Tıraşı', 90, 2500]] },
  tirnak:       { grup: 'Güzellik & Bakım', ad: 'Tırnak & Kirpik Stüdyosu', ek: 'Tercih / model', uyari: 'Alerji / dikkat', hizmetler: [['Kalıcı Oje', 60, 600], ['Protez Tırnak', 120, 1200], ['Manikür', 45, 400], ['Pedikür', 60, 500], ['İpek Kirpik', 90, 1500], ['Kirpik Lifting', 60, 900]] },
  spa:          { grup: 'Güzellik & Bakım', ad: 'Masaj & Spa', ek: 'Tercih (baskı / yağ)', uyari: 'Sağlık durumu / dikkat', hizmetler: [['Klasik Masaj', 60, 1500], ['Aromaterapi Masajı', 60, 1700], ['Sıcak Taş Masajı', 75, 2000], ['Hamam + Kese', 45, 1000], ['Çift Masajı', 60, 3000]] },
  dovme:        { grup: 'Güzellik & Bakım', ad: 'Dövme & Piercing', ek: 'Bölge / desen', uyari: 'Alerji / sağlık durumu', hizmetler: [['Ön Görüşme', 30, 0], ['Küçük Dövme', 60, 1500], ['Orta Dövme', 120, 3500], ['Büyük Dövme (seans)', 180, 6000], ['Piercing', 20, 600]] },

  saglik:       { grup: 'Sağlık', ad: 'Klinik / Muayenehane', ek: 'Şikâyet', uyari: 'Alerji / kronik hastalık', hizmetler: [['Muayene', 20, 1500], ['Kontrol', 15, 750], ['Fizik tedavi seansı', 45, 1200], ['Diyet görüşmesi', 40, 1000], ['Online görüşme', 30, 900]] },
  dis:          { grup: 'Sağlık', ad: 'Diş Kliniği', ek: 'Şikâyet / diş no', uyari: 'Alerji / kronik hastalık', hizmetler: [['Muayene', 20, 1000], ['Diş Taşı Temizliği', 30, 1500], ['Dolgu', 45, 2500], ['Kanal Tedavisi', 60, 6000], ['Diş Çekimi', 30, 2000], ['Beyazlatma', 60, 5000]] },
  fizyoterapi:  { grup: 'Sağlık', ad: 'Fizyoterapi', ek: 'Şikâyet / bölge', uyari: 'Kronik hastalık / ameliyat', hizmetler: [['Değerlendirme', 45, 1500], ['Fizik Tedavi Seansı', 45, 1200], ['Manuel Terapi', 45, 1500], ['Kinesyo Bant', 20, 500]] },
  psikolog:     { grup: 'Sağlık', ad: 'Psikolog & Terapist', ek: 'Görüşme konusu', uyari: 'Önemli not', hizmetler: [['Bireysel Seans', 50, 2000], ['Çift Terapisi', 60, 2500], ['Çocuk / Ergen Seansı', 50, 2000], ['Online Seans', 50, 1800]] },
  diyetisyen:   { grup: 'Sağlık', ad: 'Diyetisyen', ek: 'Hedef / kilo', uyari: 'Alerji / kronik hastalık', hizmetler: [['İlk Görüşme', 60, 1500], ['Kontrol', 30, 750], ['Online Görüşme', 30, 700], ['Vücut Analizi', 15, 300]] },
  veteriner:    { grup: 'Sağlık', ad: 'Veteriner & Pet Kuaför', ek: 'Hayvan adı / türü', uyari: 'Alerji / hastalık', hizmetler: [['Muayene', 20, 800], ['Aşı', 15, 600], ['Pet Tıraş', 60, 800], ['Banyo + Bakım', 45, 600], ['Kısırlaştırma (ön görüşme)', 20, 0]] },
  optik:        { grup: 'Sağlık', ad: 'Optik & Gözlük', ek: 'Göz numarası', uyari: 'Önemli not', hizmetler: [['Göz Ölçümü', 20, 0], ['Gözlük Teslim', 10, 0], ['Lens Deneme', 30, 0], ['Tamir / Ayar', 15, 0]] },

  spor:         { grup: 'Spor & Eğitim', ad: 'Spor Salonu & Personal Trainer', ek: 'Hedef', uyari: 'Sağlık durumu / sakatlık', hizmetler: [['PT Dersi', 60, 1000], ['Ölçüm & Analiz', 30, 0], ['Deneme Dersi', 60, 0], ['Grup Dersi', 50, 400]] },
  pilates:      { grup: 'Spor & Eğitim', ad: 'Pilates & Yoga Stüdyosu', ek: 'Seviye', uyari: 'Sağlık durumu / sakatlık', hizmetler: [['Reformer Pilates', 50, 900], ['Mat Pilates', 50, 500], ['Yoga', 60, 500], ['Özel Ders', 50, 1500]] },
  egitim:       { grup: 'Spor & Eğitim', ad: 'Eğitim & Kurs / Özel Ders', ek: 'Seviye / sınıf', uyari: 'Önemli not', hizmetler: [['Özel ders', 60, 800], ['Grup dersi', 90, 500], ['Deneme sınavı', 120, 300], ['Etüt', 60, 400]] },
  muzik:        { grup: 'Spor & Eğitim', ad: 'Müzik & Dans Kursu', ek: 'Enstrüman / seviye', uyari: 'Önemli not', hizmetler: [['Bireysel Ders', 45, 700], ['Grup Dersi', 60, 400], ['Deneme Dersi', 30, 0]] },
  surucu:       { grup: 'Spor & Eğitim', ad: 'Sürücü Kursu', ek: 'Ehliyet sınıfı', uyari: 'Önemli not', hizmetler: [['Direksiyon Dersi', 50, 1000], ['Teorik Ders', 50, 0], ['Sınav Günü', 60, 0]] },

  oto:          { grup: 'Otomotiv', ad: 'Oto Servis & Bakım', ek: 'Plaka / araç', uyari: 'Önemli not', hizmetler: [['Periyodik bakım', 120, 4500], ['Yağ değişimi', 45, 2200], ['Lastik değişimi', 30, 600], ['Arıza tespiti', 60, 1000], ['Detaylı yıkama', 90, 1500]] },
  lastik:       { grup: 'Otomotiv', ad: 'Lastikçi & Rot Balans', ek: 'Plaka / lastik ölçüsü', uyari: 'Önemli not', hizmetler: [['Lastik Değişimi', 30, 600], ['Rot Balans', 45, 800], ['Lastik Oteli', 15, 1000], ['Yol Yardım', 60, 1500]] },
  yikama:       { grup: 'Otomotiv', ad: 'Oto Yıkama & Detaylı Temizlik', ek: 'Plaka / araç', uyari: 'Önemli not', hizmetler: [['İç Dış Yıkama', 45, 500], ['Detaylı Temizlik', 180, 2500], ['Pasta Cila', 240, 4000], ['Seramik Kaplama', 480, 12000]] },
  kaporta:      { grup: 'Otomotiv', ad: 'Kaporta & Boya', ek: 'Plaka / araç', uyari: 'Sigorta / dosya no', hizmetler: [['Ekspertiz / Keşif', 30, 0], ['Boyasız Göçük', 60, 1500], ['Parça Boya', 480, 4000]] },

  teknik:       { grup: 'Ev & Teknik Hizmetler', ad: 'Teknik Servis & Usta', ek: 'Cihaz / marka', uyari: 'Önemli not', hizmetler: [['Periyodik bakım', 60, 1200], ['Arıza onarımı', 60, 1500], ['Keşif', 30, 0], ['Montaj', 120, 2500]] },
  tesisat:      { grup: 'Ev & Teknik Hizmetler', ad: 'Tesisat, Vidanjör & Tıkanıklık', ek: 'Adres tarifi', uyari: 'Önemli not', hizmetler: [['Tıkanıklık Açma', 60, 1500], ['Vidanjör Çekimi', 90, 3000], ['Kamera ile Görüntüleme', 45, 1500], ['Su Kaçağı Tespiti', 60, 2000], ['Keşif', 30, 0]] },
  elektrik:     { grup: 'Ev & Teknik Hizmetler', ad: 'Elektrikçi', ek: 'Adres tarifi', uyari: 'Önemli not', hizmetler: [['Arıza Tespiti', 60, 1000], ['Tesisat / Montaj', 120, 2000], ['Keşif', 30, 0]] },
  klima:        { grup: 'Ev & Teknik Hizmetler', ad: 'Klima & Kombi Servisi', ek: 'Cihaz / marka', uyari: 'Önemli not', hizmetler: [['Klima Bakımı', 60, 1200], ['Kombi Bakımı', 60, 1200], ['Montaj', 180, 3000], ['Arıza', 60, 1500]] },
  telefon:      { grup: 'Ev & Teknik Hizmetler', ad: 'Telefon & Bilgisayar Tamiri', ek: 'Cihaz / model', uyari: 'Şifre / yedek notu', hizmetler: [['Arıza Tespiti', 30, 0], ['Ekran Değişimi', 60, 2500], ['Batarya Değişimi', 45, 1500], ['Yazılım / Format', 60, 800]] },
  temizlik:     { grup: 'Ev & Teknik Hizmetler', ad: 'Temizlik Hizmetleri', ek: 'Ev / ofis büyüklüğü', uyari: 'Önemli not', hizmetler: [['Ev Temizliği', 240, 2500], ['Ofis Temizliği', 240, 3000], ['İnşaat Sonrası', 480, 6000], ['Koltuk Yıkama', 120, 1500], ['Halı Yıkama (teslim)', 30, 0]] },
  ilaclama:     { grup: 'Ev & Teknik Hizmetler', ad: 'İlaçlama & Haşere Kontrolü', ek: 'Alan (m²)', uyari: 'Evcil hayvan / çocuk', hizmetler: [['Ev İlaçlama', 60, 1500], ['İşyeri İlaçlama', 90, 2500], ['Kontrol Ziyareti', 30, 500]] },
  nakliyat:     { grup: 'Ev & Teknik Hizmetler', ad: 'Nakliyat', ek: 'Nereden → nereye', uyari: 'Önemli not', hizmetler: [['Ekspertiz / Keşif', 30, 0], ['Evden Eve Taşıma', 480, 15000], ['Parça Eşya', 120, 2500]] },
  tadilat:      { grup: 'Ev & Teknik Hizmetler', ad: 'Tadilat, Dekorasyon & İç Mimar', ek: 'Proje / adres', uyari: 'Önemli not', hizmetler: [['Keşif / Ölçü', 60, 0], ['Proje Görüşmesi', 60, 0], ['Uygulama Günü', 480, 0]] },
  peyzaj:       { grup: 'Ev & Teknik Hizmetler', ad: 'Bahçe & Peyzaj', ek: 'Alan (m²)', uyari: 'Önemli not', hizmetler: [['Keşif', 30, 0], ['Bahçe Bakımı', 180, 2000], ['Çim / Ağaç Budama', 120, 1500]] },

  danismanlik:  { grup: 'Profesyonel Hizmetler', ad: 'Danışmanlık & Ofis', ek: 'Firma / unvan', uyari: 'Önemli not', hizmetler: [['Danışmanlık', 60, 2000], ['Ön görüşme', 30, 0], ['Evrak teslimi', 15, 0], ['Aylık takip', 45, 1500]] },
  hukuk:        { grup: 'Profesyonel Hizmetler', ad: 'Avukat & Hukuk Bürosu', ek: 'Dosya no / konu', uyari: 'Önemli not', hizmetler: [['Ön Görüşme', 30, 0], ['Hukuki Danışmanlık', 60, 3000], ['Dosya İnceleme', 60, 0], ['Duruşma', 120, 0]] },
  muhasebe:     { grup: 'Profesyonel Hizmetler', ad: 'Mali Müşavir & Muhasebe', ek: 'Firma / vergi no', uyari: 'Önemli not', hizmetler: [['Beyanname', 30, 0], ['Danışmanlık', 60, 1500], ['Evrak Teslim', 15, 0], ['Şirket Kuruluşu Görüşmesi', 60, 0]] },
  emlak:        { grup: 'Profesyonel Hizmetler', ad: 'Emlak Ofisi', ek: 'Aradığı / bütçe', uyari: 'Önemli not', hizmetler: [['Ev Gösterimi', 45, 0], ['Değerleme', 60, 0], ['Tapu Randevusu', 60, 0], ['Sözleşme', 60, 0]] },
  sigorta:      { grup: 'Profesyonel Hizmetler', ad: 'Sigorta Acentesi', ek: 'Poliçe türü / plaka', uyari: 'Poliçe bitiş', hizmetler: [['Teklif Görüşmesi', 30, 0], ['Poliçe Yenileme', 20, 0], ['Hasar Dosyası', 45, 0]] },
  fotograf:     { grup: 'Profesyonel Hizmetler', ad: 'Fotoğrafçı & Stüdyo', ek: 'Çekim türü', uyari: 'Önemli not', hizmetler: [['Vesikalık', 15, 300], ['Stüdyo Çekimi', 60, 2500], ['Dış Çekim', 120, 5000], ['Ürün Çekimi', 120, 3000]] },
  ajans:        { grup: 'Profesyonel Hizmetler', ad: 'Reklam & Dijital Ajans', ek: 'Firma / sektör', uyari: 'Önemli not', hizmetler: [['Tanışma Toplantısı', 45, 0], ['Rapor Toplantısı', 30, 0], ['Çekim Günü', 240, 0]] },

  organizasyon: { grup: 'Etkinlik, Moda & Yaşam', ad: 'Düğün & Organizasyon', ek: 'Etkinlik tarihi / kişi sayısı', uyari: 'Önemli not', hizmetler: [['Ön Görüşme / Mekân Gezisi', 60, 0], ['Nişan', 240, 0], ['Kına', 300, 0], ['Düğün', 360, 0], ['Doğum Günü', 180, 0]] },
  gelinlik:     { grup: 'Etkinlik, Moda & Yaşam', ad: 'Gelinlik & Moda Evi', ek: 'Beden / etkinlik tarihi', uyari: 'Önemli not', hizmetler: [['Prova', 60, 0], ['Ölçü Alma', 30, 0], ['Teslim', 30, 0]] },
  terzi:        { grup: 'Etkinlik, Moda & Yaşam', ad: 'Terzi & Kuru Temizleme', ek: 'Ölçüler', uyari: 'Önemli not', hizmetler: [['Prova', 20, 0], ['Tadilat Teslim', 10, 0], ['Özel Dikim Görüşmesi', 30, 0]] },
  kuyumcu:      { grup: 'Etkinlik, Moda & Yaşam', ad: 'Kuyumcu', ek: 'Yüzük ölçüsü / ayar', uyari: 'Önemli not', hizmetler: [['Özel Sipariş Görüşmesi', 30, 0], ['Tamir Teslim', 15, 0], ['Ölçü Alma', 15, 0]] },
  restoran:     { grup: 'Etkinlik, Moda & Yaşam', ad: 'Restoran & Kafe (rezervasyon)', ek: 'Kişi sayısı / masa', uyari: 'Alerji / özel istek', hizmetler: [['Masa Rezervasyonu', 120, 0], ['Özel Gün / Doğum Günü', 180, 0], ['Grup Yemeği', 180, 0]] },
  otel:         { grup: 'Etkinlik, Moda & Yaşam', ad: 'Otel & Pansiyon (giriş takibi)', ek: 'Oda / kişi sayısı', uyari: 'Özel istek', hizmetler: [['Giriş (Check-in)', 30, 0], ['Çıkış (Check-out)', 15, 0], ['Transfer', 60, 0]] }
};
// Sektör seçim kutusu: gruplu, her grupta alfabetik (Genel en üstte)
window.sektorSecenekleri = function (secili) {
  const e = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  return window.SEKTOR_GRUPLARI.map(g => {
    const l = Object.entries(window.SEKTORLER).filter(([, s]) => s.grup === g).sort((a, b) => a[1].ad.localeCompare(b[1].ad, 'tr'));
    return `<optgroup label="${e(g)}">` + l.map(([k, s]) => `<option value="${k}" ${k === secili ? 'selected' : ''}>${e(s.ad)}</option>`).join('') + '</optgroup>';
  }).join('');
};
