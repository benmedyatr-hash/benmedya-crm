-- BenMedya CRM — 04: yönetici firma açarken düzenlediği hizmet listesini firmaya yazar
-- (firma ilk açılışta sektörün hazır listesini EKLEMEZ; kuruldu=true yapılır)
create or replace function public.yonetici_hizmet_ekle(p_firma uuid, p_hizmetler jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare h jsonb; n int := 0; yid text;
begin
  if not public.yonetici_mi() then raise exception 'Yetki yok'; end if;
  for h in select * from jsonb_array_elements(coalesce(p_hizmetler, '[]'::jsonb)) loop
    if coalesce(trim(h->>'ad'), '') = '' then continue; end if;
    yid := substr(md5(random()::text || clock_timestamp()::text), 1, 12);
    insert into public.kayitlar (firma_id, tur, id, veri) values (p_firma, 'hizmet', yid,
      jsonb_build_object('id', yid, 'ad', left(trim(h->>'ad'), 80),
        'sure', greatest(5, coalesce(nullif(h->>'sure','')::numeric, 30))::int,
        'fiyat', greatest(0, coalesce(nullif(h->>'fiyat','')::numeric, 0))));
    n := n + 1;
  end loop;
  update public.firmalar set ayar = ayar || '{"kuruldu":true}'::jsonb where id = p_firma;
  return n;
end $$;
revoke execute on function public.yonetici_hizmet_ekle(uuid, jsonb) from anon, public;
grant  execute on function public.yonetici_hizmet_ekle(uuid, jsonb) to authenticated;
