-- BenMedya CRM — 05: sayfa / müşteri kartı açılışlarını işlem geçmişine yazar (değişiklik yapılmasa bile)
-- islem = 'goruntuledi', tur = 'sayfa' (ozet = sayfa adı) ya da 'musteri' (kayit_id = müşteri, ozet = ad)
-- Aynı kişi aynı sayfayı 1 dakika içinde tekrar açarsa ikinci kez yazılmaz.
create or replace function public.sayfa_kaydet(p_tur text, p_ozet text, p_kayit text default null)
returns void language plpgsql security definer set search_path = public, auth as $$
declare f uuid := public.benim_firmam(); t text := case when p_tur = 'musteri' then 'musteri' else 'sayfa' end;
begin
  if f is null then return; end if;
  if exists (select 1 from public.islem_log l
             where l.firma_id = f and l.user_id = auth.uid() and l.islem = 'goruntuledi'
               and l.tur = t and coalesce(l.kayit_id,'') = coalesce(p_kayit,'') and l.ozet = left(p_ozet, 80)
               and l.zaman > now() - interval '1 minute') then return; end if;
  insert into public.islem_log (firma_id, user_id, eposta, islem, tur, kayit_id, ozet)
  values (f, auth.uid(), (select email from auth.users where id = auth.uid()), 'goruntuledi', t, p_kayit, left(p_ozet, 80));
end $$;
revoke execute on function public.sayfa_kaydet(text, text, text) from anon, public;
grant  execute on function public.sayfa_kaydet(text, text, text) to authenticated;
