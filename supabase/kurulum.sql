-- =====================================================================
--  BenMedya CRM — veritabanı kurulumu (Supabase SQL Editor'de BİR KEZ çalıştır)
--  Çok firmalı yapı: her kayıt bir firmaya bağlı, firmalar birbirini GÖREMEZ.
--  Kilit veritabanının kendisinde (RLS); uygulamada hata olsa bile veri sızmaz.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- tablolar ----------
create table if not exists public.firmalar (
  id          uuid primary key default gen_random_uuid(),
  ad          text not null,
  ayar        jsonb not null default '{}'::jsonb,
  durum       text not null default 'aktif' check (durum in ('aktif','durduruldu')),
  bitis       date,                      -- abonelik bitişi (boş = süresiz)
  notlar      text,                      -- yalnız yöneticinin gördüğü not
  olusturma   timestamptz not null default now()
);

create table if not exists public.uyeler (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  firma_id    uuid not null references public.firmalar(id) on delete cascade,
  olusturma   timestamptz not null default now()
);
create index if not exists uyeler_firma on public.uyeler(firma_id);

create table if not exists public.yoneticiler (
  user_id     uuid primary key references auth.users(id) on delete cascade
);

-- Müşteri, hizmet, randevu, paket, hatırlatıcı: hepsi tek tabloda, firmaya bağlı
create table if not exists public.kayitlar (
  firma_id    uuid not null references public.firmalar(id) on delete cascade,
  tur         text not null check (tur in ('musteri','hizmet','randevu','paket','gorev')),
  id          text not null,
  veri        jsonb not null,
  guncellendi timestamptz not null default now(),
  primary key (firma_id, tur, id)
);
create index if not exists kayitlar_firma_tur on public.kayitlar(firma_id, tur);

-- ---------- yardımcı işlevler ----------
-- Giriş yapan kişinin firması (firma durdurulmuş ya da süresi bitmişse BOŞ döner → hiçbir şey göremez)
create or replace function public.benim_firmam() returns uuid
language sql stable security definer set search_path = public as $$
  select u.firma_id
  from public.uyeler u
  join public.firmalar f on f.id = u.firma_id
  where u.user_id = auth.uid()
    and f.durum = 'aktif'
    and (f.bitis is null or f.bitis >= current_date)
$$;

create or replace function public.yonetici_mi() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.yoneticiler where user_id = auth.uid())
$$;

-- ---------- kilitler (RLS) ----------
alter table public.firmalar    enable row level security;
alter table public.uyeler      enable row level security;
alter table public.yoneticiler enable row level security;
alter table public.kayitlar    enable row level security;

drop policy if exists firma_oku on public.firmalar;
create policy firma_oku on public.firmalar for select
  using (id = public.benim_firmam() or public.yonetici_mi());

drop policy if exists firma_guncelle on public.firmalar;
create policy firma_guncelle on public.firmalar for update
  using (id = public.benim_firmam()) with check (id = public.benim_firmam());

-- Firma kendi adını ve ayarını değiştirebilir; durum/bitiş/not'a DOKUNAMAZ
revoke update on public.firmalar from authenticated, anon;
grant  update (ad, ayar) on public.firmalar to authenticated;

drop policy if exists uye_oku on public.uyeler;
create policy uye_oku on public.uyeler for select
  using (user_id = auth.uid() or public.yonetici_mi());

drop policy if exists yonetici_oku on public.yoneticiler;
create policy yonetici_oku on public.yoneticiler for select
  using (user_id = auth.uid());

drop policy if exists kayit_oku on public.kayitlar;
create policy kayit_oku on public.kayitlar for select
  using (firma_id = public.benim_firmam());
drop policy if exists kayit_ekle on public.kayitlar;
create policy kayit_ekle on public.kayitlar for insert
  with check (firma_id = public.benim_firmam());
drop policy if exists kayit_guncelle on public.kayitlar;
create policy kayit_guncelle on public.kayitlar for update
  using (firma_id = public.benim_firmam()) with check (firma_id = public.benim_firmam());
drop policy if exists kayit_sil on public.kayitlar;
create policy kayit_sil on public.kayitlar for delete
  using (firma_id = public.benim_firmam());

-- ---------- yönetici işlemleri (yalnız yönetici çağırabilir) ----------
create or replace function public.yonetici_firma_ac(p_ad text, p_sektor text, p_renk int, p_bitis date, p_notlar text)
returns uuid language plpgsql security definer set search_path = public as $$
declare yeni uuid;
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  insert into public.firmalar (ad, ayar, bitis, notlar)
  values (trim(p_ad), jsonb_build_object('sektor', coalesce(p_sektor,'genel'), 'renk', coalesce(p_renk,0)), p_bitis, p_notlar)
  returning id into yeni;
  return yeni;
end $$;

create or replace function public.yonetici_firma_guncelle(p_id uuid, p_ad text, p_durum text, p_bitis date, p_notlar text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  update public.firmalar set ad = trim(p_ad), durum = p_durum, bitis = p_bitis, notlar = p_notlar where id = p_id;
end $$;

create or replace function public.yonetici_uye_bagla(p_eposta text, p_firma uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
declare kid uuid;
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  select id into kid from auth.users where lower(email) = lower(trim(p_eposta));
  if kid is null then raise exception 'Bu e-postayla kullanıcı bulunamadı'; end if;
  insert into public.uyeler (user_id, firma_id) values (kid, p_firma)
  on conflict (user_id) do update set firma_id = excluded.firma_id;
end $$;

create or replace function public.yonetici_uye_cikar(p_eposta text)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  delete from public.uyeler where user_id = (select id from auth.users where lower(email) = lower(trim(p_eposta)));
end $$;

create or replace function public.yonetici_liste()
returns table (id uuid, ad text, durum text, bitis date, notlar text, olusturma timestamptz, sektor text,
               kullanicilar text, son_giris timestamptz, musteri bigint, randevu bigint, son_islem timestamptz)
language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  return query
  select f.id, f.ad, f.durum, f.bitis, f.notlar, f.olusturma, f.ayar->>'sektor',
         (select string_agg(au.email, ', ' order by au.email) from public.uyeler u join auth.users au on au.id = u.user_id where u.firma_id = f.id)::text,
         (select max(au.last_sign_in_at) from public.uyeler u join auth.users au on au.id = u.user_id where u.firma_id = f.id),
         (select count(*) from public.kayitlar k where k.firma_id = f.id and k.tur = 'musteri'),
         (select count(*) from public.kayitlar k where k.firma_id = f.id and k.tur = 'randevu'),
         (select max(k.guncellendi) from public.kayitlar k where k.firma_id = f.id)
  from public.firmalar f
  order by f.olusturma desc;
end $$;

-- Dışarıdan (giriş yapmamış) kimse bu işlevleri çağıramasın
revoke execute on function public.yonetici_firma_ac(text,text,int,date,text)        from anon, public;
revoke execute on function public.yonetici_firma_guncelle(uuid,text,text,date,text) from anon, public;
revoke execute on function public.yonetici_uye_bagla(text,uuid)                     from anon, public;
revoke execute on function public.yonetici_uye_cikar(text)                          from anon, public;
revoke execute on function public.yonetici_liste()                                  from anon, public;
grant  execute on function public.yonetici_firma_ac(text,text,int,date,text)        to authenticated;
grant  execute on function public.yonetici_firma_guncelle(uuid,text,text,date,text) to authenticated;
grant  execute on function public.yonetici_uye_bagla(text,uuid)                     to authenticated;
grant  execute on function public.yonetici_uye_cikar(text)                          to authenticated;
grant  execute on function public.yonetici_liste()                                  to authenticated;

-- ---------- canlı güncelleme (aynı firmada iki cihaz açıksa anında yansır) ----------
do $$ begin
  alter publication supabase_realtime add table public.kayitlar;
exception when duplicate_object then null; end $$;
