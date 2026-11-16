# BenMedya CRM

Çok firmalı CRM: tek sistem, her firma yalnız kendi verisini görür (Supabase RLS).

- `docs/app/` — firmaların kullandığı uygulama (crm.benmedya.com → /app/ yönlendirir; kendi kapsamı, yönetimle çakışmaz)
- `docs/yonetim/` — yönetim paneli (ayrı kurulabilir uygulama; eski yonetim.html buraya yönlendirir) (firma açma / durdurma / bitiş tarihi / kullanıcı ekleme)
- `docs/ayar.js` — Supabase adresi + anon anahtar (herkese açık olabilir; service_role ASLA)
- `supabase/kurulum.sql` — veritabanı kurulumu (SQL Editor'de bir kez)

Yayın: GitHub Pages, `docs/` klasörü. Güncelleme = commit + push.

## Supabase ayarları (bir kez)
1. Authentication > Sign In / Providers > Email: **Confirm email KAPALI** (yönetim paneli kullanıcıyı onaysız açar).
2. Authentication > URL Configuration: Site URL `https://crm.benmedya.com`, Redirect URLs'e `https://crm.benmedya.com/**`.
3. SQL Editor'de `supabase/kurulum.sql`.
4. Yönetici hesabı: Authentication > Users > Add user (Auto confirm), sonra SQL:
   `insert into public.yoneticiler select id from auth.users where email = '<yönetici e-postası>';`
