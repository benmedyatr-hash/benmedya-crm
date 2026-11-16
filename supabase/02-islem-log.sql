-- =====================================================================
--  02 — İşlem kaydı (log). Veritabanı tetikleyicisiyle tutulur:
--  uygulama atlayamaz, firma kaydı değiştiremez / silemez (yalnız okur).
-- =====================================================================

create table if not exists public.islem_log (
  id        bigint generated always as identity primary key,
  firma_id  uuid not null references public.firmalar(id) on delete cascade,
  zaman     timestamptz not null default now(),
  user_id   uuid,
  eposta    text,
  islem     text not null,          -- ekledi | guncelledi | sildi | giris | ayar | yonetim
  tur       text,                   -- musteri | hizmet | randevu | paket | gorev | firma
  kayit_id  text,
  ozet      text,                   -- insan okunur kısa özet (firma görür, yönetici GÖRMEZ)
  degisen   text,                   -- güncellemede değişen alanlar
  onceki    jsonb,
  sonraki   jsonb
);
create index if not exists islem_log_firma_zaman on public.islem_log(firma_id, zaman desc);
create index if not exists islem_log_kayit on public.islem_log(firma_id, tur, kayit_id);

alter table public.islem_log enable row level security;
drop policy if exists log_oku on public.islem_log;
create policy log_oku on public.islem_log for select using (firma_id = public.benim_firmam());
revoke insert, update, delete on public.islem_log from anon, authenticated;

-- Kısa özet: "Ayşe Yılmaz · 2026-11-17 14:00 · Cilt Bakımı" gibi
create or replace function public.kayit_ozet(p_firma uuid, p_tur text, v jsonb) returns text
language sql stable security definer set search_path = public as $$
  select case p_tur
    when 'musteri' then v->>'ad'
    when 'hizmet'  then v->>'ad'
    when 'gorev'   then v->>'baslik'
    when 'randevu' then coalesce((select m.veri->>'ad' from public.kayitlar m where m.firma_id = p_firma and m.tur = 'musteri' and m.id = v->>'mid'), '(müşteri)')
                        || ' · ' || coalesce(v->>'tarih','') || ' ' || coalesce(v->>'saat','')
                        || coalesce(' · ' || (select h.veri->>'ad' from public.kayitlar h where h.firma_id = p_firma and h.tur = 'hizmet' and h.id = v->>'hid'), '')
    when 'paket'   then coalesce((select m.veri->>'ad' from public.kayitlar m where m.firma_id = p_firma and m.tur = 'musteri' and m.id = v->>'mid'), '(müşteri)')
                        || ' · ' || coalesce(v->>'kullanilan','0') || '/' || coalesce(v->>'toplam','0') || ' seans'
    else null end
$$;

create or replace function public.kayit_log_tetik() returns trigger
language plpgsql security definer set search_path = public, auth as $$
declare e text; deg text;
begin
  select email into e from auth.users where id = auth.uid();
  if tg_op = 'INSERT' then
    insert into public.islem_log (firma_id, user_id, eposta, islem, tur, kayit_id, ozet, sonraki)
    values (new.firma_id, auth.uid(), e, 'ekledi', new.tur, new.id, public.kayit_ozet(new.firma_id, new.tur, new.veri), new.veri);
    return new;
  elsif tg_op = 'UPDATE' then
    if new.veri = old.veri then return new; end if;
    select string_agg(k, ',' order by k) into deg from (
      select n.key k from jsonb_each(new.veri) n where n.value is distinct from (old.veri -> n.key)
      union select o.key from jsonb_each(old.veri) o where not (new.veri ? o.key)
    ) x;
    insert into public.islem_log (firma_id, user_id, eposta, islem, tur, kayit_id, ozet, degisen, onceki, sonraki)
    values (new.firma_id, auth.uid(), e, 'guncelledi', new.tur, new.id, public.kayit_ozet(new.firma_id, new.tur, new.veri), deg, old.veri, new.veri);
    return new;
  else
    -- firma tamamen silinirken (cascade) kayıt tutma
    if not exists (select 1 from public.firmalar where id = old.firma_id) then return old; end if;
    insert into public.islem_log (firma_id, user_id, eposta, islem, tur, kayit_id, ozet, onceki)
    values (old.firma_id, auth.uid(), e, 'sildi', old.tur, old.id, public.kayit_ozet(old.firma_id, old.tur, old.veri), old.veri);
    return old;
  end if;
end $$;

drop trigger if exists kayit_log on public.kayitlar;
create trigger kayit_log after insert or update or delete on public.kayitlar
  for each row execute function public.kayit_log_tetik();

-- Firma ayarları (firma kendisi) ve yönetim değişiklikleri (durum / bitiş / ad)
create or replace function public.firma_log_tetik() returns trigger
language plpgsql security definer set search_path = public, auth as $$
declare e text; deg text;
begin
  select email into e from auth.users where id = auth.uid();
  if new.durum is distinct from old.durum or new.bitis is distinct from old.bitis then
    insert into public.islem_log (firma_id, user_id, eposta, islem, tur, ozet, onceki, sonraki)
    values (new.id, auth.uid(), e, 'yonetim', 'firma',
            'durum: ' || old.durum || ' → ' || new.durum || ' · bitiş: ' || coalesce(old.bitis::text,'süresiz') || ' → ' || coalesce(new.bitis::text,'süresiz'),
            jsonb_build_object('durum', old.durum, 'bitis', old.bitis), jsonb_build_object('durum', new.durum, 'bitis', new.bitis));
  end if;
  if new.ad is distinct from old.ad or new.ayar is distinct from old.ayar then
    select string_agg(k, ',' order by k) into deg from (
      select n.key k from jsonb_each(new.ayar) n where n.value is distinct from (old.ayar -> n.key)
    ) x;
    if new.ad is distinct from old.ad then deg := concat_ws(',', 'firma', deg); end if;
    insert into public.islem_log (firma_id, user_id, eposta, islem, tur, ozet, degisen, onceki, sonraki)
    values (new.id, auth.uid(), e, 'ayar', 'firma', new.ad, deg,
            jsonb_build_object('firma', old.ad) || old.ayar, jsonb_build_object('firma', new.ad) || new.ayar);
  end if;
  return new;
end $$;

drop trigger if exists firma_log on public.firmalar;
create trigger firma_log after update on public.firmalar
  for each row execute function public.firma_log_tetik();

-- Uygulama her açıldığında / girişte çağrılır
create or replace function public.giris_kaydet() returns void
language plpgsql security definer set search_path = public, auth as $$
declare f uuid := public.benim_firmam();
begin
  if f is null then return; end if;
  insert into public.islem_log (firma_id, user_id, eposta, islem)
  values (f, auth.uid(), (select email from auth.users where id = auth.uid()), 'giris');
end $$;
revoke execute on function public.giris_kaydet() from anon, public;
grant  execute on function public.giris_kaydet() to authenticated;

-- Yönetici: firmanın işlem özetini görür (müşteri adı / veri içeriği YOK)
create or replace function public.yonetici_log(p_firma uuid, p_adet int default 50)
returns table (zaman timestamptz, eposta text, islem text, tur text, degisen text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  return query
  select l.zaman, l.eposta, l.islem, l.tur, l.degisen
  from public.islem_log l where l.firma_id = p_firma
  order by l.zaman desc limit least(coalesce(p_adet, 50), 500);
end $$;
revoke execute on function public.yonetici_log(uuid,int) from anon, public;
grant  execute on function public.yonetici_log(uuid,int) to authenticated;

-- Yönetici firma açtığında da kayıt düşsün
create or replace function public.yonetici_firma_ac(p_ad text, p_sektor text, p_renk int, p_bitis date, p_notlar text)
returns uuid language plpgsql security definer set search_path = public, auth as $$
declare yeni uuid;
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  insert into public.firmalar (ad, ayar, bitis, notlar)
  values (trim(p_ad), jsonb_build_object('sektor', coalesce(p_sektor,'genel'), 'renk', coalesce(p_renk,0)), p_bitis, p_notlar)
  returning id into yeni;
  insert into public.islem_log (firma_id, user_id, eposta, islem, tur, ozet)
  values (yeni, auth.uid(), (select email from auth.users where id = auth.uid()), 'yonetim', 'firma', 'Firma açıldı · bitiş: ' || coalesce(p_bitis::text, 'süresiz'));
  return yeni;
end $$;

-- ---------- KAYITLAR SİLİNEMEZ / DEĞİŞTİRİLEMEZ ----------
-- Firma, yönetim paneli ya da uygulama hatası: hiçbiri işlem kaydını silemez veya değiştiremez.
-- Firma silinse bile (cascade) kayıtlar korunur → firma silme de reddedilir.
-- Tek istisna: Supabase SQL Editor'de, aynı işlemde bilinçli olarak
--   begin; set local crm.log_sil = 'evet'; delete from public.islem_log where ...; commit;
create or replace function public.log_koru() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' then raise exception 'İşlem kayıtları değiştirilemez'; end if;
  if coalesce(current_setting('crm.log_sil', true), '') <> 'evet' then
    raise exception 'İşlem kayıtları silinemez';
  end if;
  if tg_op = 'TRUNCATE' then return null; end if;
  return old;
end $$;

drop trigger if exists log_koru on public.islem_log;
create trigger log_koru before update or delete on public.islem_log
  for each row execute function public.log_koru();
drop trigger if exists log_koru_toplu on public.islem_log;
create trigger log_koru_toplu before truncate on public.islem_log
  for each statement execute function public.log_koru();

revoke truncate on public.islem_log, public.kayitlar, public.firmalar, public.uyeler, public.yoneticiler from anon, authenticated;
