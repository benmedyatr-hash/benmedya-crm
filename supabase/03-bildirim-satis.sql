-- =====================================================================
--  BenMedya CRM — 03: tek seferlik işlem (satis) + telefon bildirimi (Web Push)
--  Supabase SQL Editor'de BİR KEZ çalıştır. Tekrar çalıştırmak zararsız.
-- =====================================================================

-- ---------- 1) Tek seferlik işlem: yeni kayıt türü 'satis' ----------
alter table public.kayitlar drop constraint if exists kayitlar_tur_check;
alter table public.kayitlar add constraint kayitlar_tur_check
  check (tur in ('musteri','hizmet','randevu','paket','gorev','satis'));

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
    when 'satis'   then coalesce((select m.veri->>'ad' from public.kayitlar m where m.firma_id = p_firma and m.tur = 'musteri' and m.id = v->>'mid'), '(müşteri)')
                        || ' · ' || coalesce(v->>'aciklama','') || ' · ' || coalesce(v->>'tutar','0') || ' ₺'
    else null end
$$;

-- ---------- 2) Bildirim tabloları ----------
-- Her telefon/tarayıcı bir abonelik. Kişi yalnız kendi aboneliğini görür.
create table if not exists public.bildirim_abonelik (
  endpoint   text primary key,
  firma_id   uuid not null references public.firmalar(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  p256dh     text not null,
  auth       text not null,
  cihaz      text,
  olusturma  timestamptz not null default now()
);
create index if not exists bildirim_abonelik_firma on public.bildirim_abonelik(firma_id);
alter table public.bildirim_abonelik enable row level security;
drop policy if exists abonelik_oku on public.bildirim_abonelik;
create policy abonelik_oku on public.bildirim_abonelik for select using (user_id = auth.uid());

-- Aynı bildirim iki kez gitmesin
create table if not exists public.bildirim_gonderilen (
  anahtar text primary key,
  zaman   timestamptz not null default now()
);
alter table public.bildirim_gonderilen enable row level security;  -- politika yok = dışarıdan erişilemez

-- "Deneme bildirimi gönder" istekleri
create table if not exists public.bildirim_deneme (
  id       bigserial primary key,
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  user_id  uuid not null references auth.users(id) on delete cascade,
  zaman    timestamptz not null default now()
);
alter table public.bildirim_deneme enable row level security;

-- Gönderici anahtarı (VAPID). Sunucu ilk çalışmada kendisi üretir; gizli yarısı dışarı ÇIKMAZ.
create table if not exists public.bildirim_anahtar (
  id    int primary key check (id = 1),
  acik  text not null,
  gizli text not null
);
alter table public.bildirim_anahtar enable row level security;
revoke all on public.bildirim_anahtar, public.bildirim_gonderilen, public.bildirim_deneme from anon, authenticated;

-- ---------- 3) Uygulamanın çağırdığı işlevler ----------
create or replace function public.bildirim_acik_anahtar() returns text
language sql stable security definer set search_path = public as $$
  select acik from public.bildirim_anahtar where id = 1
$$;

create or replace function public.bildirim_abone_ol(p_endpoint text, p_p256dh text, p_auth text, p_cihaz text)
returns void language plpgsql security definer set search_path = public as $$
declare f uuid := public.benim_firmam();
begin
  if f is null then raise exception 'Firma bulunamadı'; end if;
  insert into public.bildirim_abonelik (endpoint, firma_id, user_id, p256dh, auth, cihaz)
  values (p_endpoint, f, auth.uid(), p_p256dh, p_auth, left(p_cihaz, 120))
  on conflict (endpoint) do update set firma_id = excluded.firma_id, user_id = excluded.user_id,
    p256dh = excluded.p256dh, auth = excluded.auth, cihaz = excluded.cihaz;
end $$;

create or replace function public.bildirim_abonelik_sil(p_endpoint text)
returns void language sql security definer set search_path = public as $$
  delete from public.bildirim_abonelik where endpoint = p_endpoint and user_id = auth.uid()
$$;

create or replace function public.bildirim_deneme_iste()
returns void language plpgsql security definer set search_path = public as $$
declare f uuid := public.benim_firmam();
begin
  if f is null then raise exception 'Firma bulunamadı'; end if;
  insert into public.bildirim_deneme (firma_id, user_id) values (f, auth.uid());
end $$;

revoke execute on function public.bildirim_acik_anahtar()                      from anon, public;
revoke execute on function public.bildirim_abone_ol(text,text,text,text)       from anon, public;
revoke execute on function public.bildirim_abonelik_sil(text)                  from anon, public;
revoke execute on function public.bildirim_deneme_iste()                       from anon, public;
grant  execute on function public.bildirim_acik_anahtar()                      to authenticated;
grant  execute on function public.bildirim_abone_ol(text,text,text,text)       to authenticated;
grant  execute on function public.bildirim_abonelik_sil(text)                  to authenticated;
grant  execute on function public.bildirim_deneme_iste()                       to authenticated;

-- ---------- 4) Gönderilecekler kuyruğu (yalnız sunucu işlevi çağırır) ----------
-- Firma ayarı (firmalar.ayar): bildirimDk = 0 (kapalı) | 15 | 30 | 60 | 120 (varsayılan 30)
--                             sabahOzet = true/false (varsayılan true), sabahSaat = 'SS:DD' (varsayılan 09:00)
-- Türkiye saati sabit +03.
create or replace function public.bildirim_kuyrugu() returns setof jsonb
language plpgsql security definer set search_path = public as $$
declare simdi timestamp := (now() at time zone 'Europe/Istanbul');
        bugun text := to_char(simdi, 'YYYY-MM-DD');
begin
  delete from public.bildirim_gonderilen where zaman < now() - interval '3 days';

  return query
  with firma as (
    select f.id, f.ad,
           case when coalesce(f.ayar->>'bildirimDk','') ~ '^\d{1,4}$' then (f.ayar->>'bildirimDk')::int else 30 end as dk,
           coalesce((f.ayar->>'sabahOzet')::boolean, true) as ozet,
           case when coalesce(f.ayar->>'sabahSaat','') ~ '^\d\d:\d\d$' then (f.ayar->>'sabahSaat')::time else time '09:00' end as ozet_saat
    from public.firmalar f
    where f.durum = 'aktif' and (f.bitis is null or f.bitis >= current_date)
      and exists (select 1 from public.bildirim_abonelik a where a.firma_id = f.id)
  ),
  rnd as (
    select fi.id as firma_id, fi.dk, k.id, k.veri,
           ((k.veri->>'tarih') || ' ' || (k.veri->>'saat'))::timestamp as bas
    from firma fi
    join public.kayitlar k on k.firma_id = fi.id and k.tur = 'randevu'
    where k.veri->>'durum' = 'bekliyor'
      and k.veri->>'tarih' in (bugun, to_char(simdi + interval '1 day', 'YYYY-MM-DD'))
      and coalesce(k.veri->>'saat','') ~ '^\d\d:\d\d$'
  ),
  aday as (
    -- randevudan önce
    select r.firma_id, null::uuid as user_id,
           'r:' || r.firma_id || ':' || r.id || ':' || to_char(r.bas, 'YYYY-MM-DD HH24:MI') as anahtar,
           'Randevu ' || ceil(extract(epoch from r.bas - simdi) / 60)::int || ' dk sonra' as baslik,
           (r.veri->>'saat') || ' · ' || coalesce(nullif(m.veri->>'ad',''), 'Müşteri')
             || coalesce(' · ' || coalesce(h.veri->>'ad', r.veri->>'hizmetAdi'), '') as govde,
           'r-' || r.id as etiket
    from rnd r
    left join public.kayitlar m on m.firma_id = r.firma_id and m.tur = 'musteri' and m.id = r.veri->>'mid'
    left join public.kayitlar h on h.firma_id = r.firma_id and h.tur = 'hizmet'  and h.id = r.veri->>'hid'
    where r.dk > 0 and r.bas > simdi and r.bas <= simdi + make_interval(mins => r.dk)
    union all
    -- sabah özeti (yalnız o gün randevu varsa, öğlene kadar)
    select fi.id, null::uuid,
           'o:' || fi.id || ':' || bugun,
           'Bugün ' || count(*) || ' randevunuz var',
           string_agg((r.veri->>'saat') || ' ' || split_part(coalesce(nullif(m.veri->>'ad',''), 'Müşteri'), ' ', 1), ', ' order by r.bas),
           'ozet-' || bugun
    from firma fi
    join rnd r on r.firma_id = fi.id and r.veri->>'tarih' = bugun
    left join public.kayitlar m on m.firma_id = fi.id and m.tur = 'musteri' and m.id = r.veri->>'mid'
    where fi.ozet and simdi::time >= fi.ozet_saat and simdi::time < time '12:00'
    group by fi.id
    union all
    -- saatli hatırlatıcılar (saati gelince)
    select fi.id, null::uuid,
           'g:' || fi.id || ':' || k.id || ':' || (k.veri->>'tarih') || (k.veri->>'saat'),
           'Hatırlatıcı',
           k.veri->>'baslik',
           'g-' || k.id
    from firma fi
    join public.kayitlar k on k.firma_id = fi.id and k.tur = 'gorev'
    where coalesce((k.veri->>'bitti')::boolean, false) = false
      and k.veri->>'tarih' = bugun
      and coalesce(k.veri->>'saat','') ~ '^\d\d:\d\d$'
      and (k.veri->>'saat')::time <= simdi::time
      and (k.veri->>'saat')::time > (simdi - interval '10 minutes')::time
    union all
    -- deneme bildirimi
    select d.firma_id, d.user_id, 'd:' || d.id, 'Bildirimler açık ✓',
           'Randevularınızdan önce bu telefona bildirim gelecek.', 'deneme'
    from public.bildirim_deneme d
  ),
  yeni as (
    insert into public.bildirim_gonderilen (anahtar)
    select anahtar from aday
    on conflict do nothing
    returning anahtar
  )
  select jsonb_build_object('endpoint', a.endpoint, 'p256dh', a.p256dh, 'auth', a.auth,
                            'baslik', ad.baslik, 'govde', ad.govde, 'etiket', ad.etiket)
  from yeni y
  join aday ad on ad.anahtar = y.anahtar
  join public.bildirim_abonelik a on a.firma_id = ad.firma_id and (ad.user_id is null or a.user_id = ad.user_id);

  delete from public.bildirim_deneme where zaman < now() + interval '1 second';
end $$;
revoke execute on function public.bildirim_kuyrugu() from anon, authenticated, public;

-- ---------- 5) Her dakika sunucu işlevini tetikle ----------
create extension if not exists pg_cron;
create extension if not exists pg_net;
do $$ begin perform cron.unschedule('crm-bildirim'); exception when others then null; end $$;
select cron.schedule('crm-bildirim', '* * * * *', $c$
  select net.http_post(
    url := 'https://qxdbjqclutntmypqnusu.supabase.co/functions/v1/bildirim-gonder',
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := '{}'::jsonb,
    timeout_milliseconds := 20000)
$c$);
