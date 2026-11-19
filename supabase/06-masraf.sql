-- =====================================================================
--  BenMedya CRM — 06: ön muhasebe — masraf kaydı (Yemek / Fatura / Diğer)
--  Supabase SQL Editor'de BİR KEZ çalıştır. Tekrar çalıştırmak zararsız.
--  Uygulama yayına alınmadan ÖNCE çalışmalı (yoksa masraf kaydı reddedilir).
-- =====================================================================

alter table public.kayitlar drop constraint if exists kayitlar_tur_check;
alter table public.kayitlar add constraint kayitlar_tur_check
  check (tur in ('musteri','hizmet','randevu','paket','gorev','satis','masraf'));

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
    when 'satis'   then coalesce((select m.veri->>'ad' from public.kayitlar m where m.firma_id = p_firma and m.tur = 'musteri' and m.id = v->>'mid'), 'Kayıtsız müşteri')
                        || ' · ' || coalesce(v->>'aciklama','') || ' · ' || coalesce(v->>'tutar','0') || ' ₺'
                        || case when coalesce(v->>'alinan','') ~ '^[0-9.]*[1-9][0-9.]*$' then ' (alınan ' || (v->>'alinan') || ' ₺)' else '' end
    when 'masraf'  then coalesce(v->>'kategori','Masraf') || ' masrafı · ' || coalesce(v->>'tutar','0') || ' ₺'
                        || coalesce(' · ' || nullif(v->>'aciklama',''), '')
    else null end
$$;
